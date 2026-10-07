; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $009", ROMX[$4000], BANK[$9]

    db $09 ;ROM Bank

    dw label9_4005
    dw label9_6120

label9_4005:                        ; bank $09 entry 0: screen effects
    ld a, [$c8ef]                   ; the effect type (script opcode $04)
    rst $00
; ScreenEffectTable09 ($09:$4009) — S109: 16 handlers indexed by $C8EF, the
; SCREEN-EFFECT type written by script opcode $04 (TriggerScreenEffect
; type, text). Was mgbdis fake code. Type 4 = the arena class menu.
ScreenEffectTable09:
    dw $45F3               ; type  0
    dw $4033               ; type  1 — close (no menu)
    dw VaultScreen         ; type  2 — the Vault menu (S118f: the Vault keeper's $04 2)
    dw $402E               ; type  3 — bank $12 entry 0: Pulio's farm menu (pick up / leave monsters; $12:$4EBC sets flag $0007, S118f)
    dw ArenaClassMenu      ; type  4 — ARENA CLASS-REGISTRATION MENU
    dw $4029               ; type  5 — bank $0A entry 0
    dw $4029               ; type  6 — bank $0A entry 0
    dw $4029               ; type  7 — bank $0A entry 0
    dw $402E               ; type  8 — bank $12 entry 0: the Library (look up a family)
    dw $402E               ; type  9 — bank $12 entry 0: the Monster Namer (rename)
    dw $402E               ; type 10 — bank $12 entry 0: MedalMan's medal exchange
    dw $4029               ; type 11 — bank $0A entry 0
    dw $45F3               ; type 12
    dw GateListScreen      ; type 13 — the list of Travelers' Gates (Gate Hub guide, S118f)
    dw $4033               ; type 14 — close (no menu)
    dw label9_6120         ; type 15
    ld hl, $0a00
    rst $10
    ret


    ld hl, $1200
    rst $10
    ret


    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


ReadFld9_403d:
    ld a, [hl]
    add $04
    ld [hl+], a
    ld a, [hl]
    adc $00
    ld [hl-], a
    ld a, [hl]
    and $f8
    ld [hl], a
    ret


SaveFld9_404a:
    push af
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
    pop af
    ret


LoadFld9_4059:
    ld a, [$c909]
    add l
    ld l, a
    ld a, [$c90a]
    adc h
    and $03
    ld h, a
    ld a, [$c90a]
    and $fc
    or h
    ld h, a
    ret


LoadFld9_406d:
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ret


SaveFld9_4076:
    push bc
    ld b, l
    ld a, l
    and $e0
    ld l, a
    call LoadFld9_4059
    ld a, b
    and $1f
    jr z, jr_009_408b

    ld b, a

jr_009_4085:
    call SaveFld9_404a
    dec b
    jr nz, jr_009_4085

jr_009_408b:
    pop bc
    ret


    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call SaveFld9_4076
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a

jr_009_409c:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_009_40c1

    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
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
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    jr jr_009_409c

jr_009_40c1:
    call Write_gfx_tile
    call SaveFld9_404a
    jr jr_009_409c

LoadFld9_40c9:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    call LoadFld9_406d
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a

jr_009_40d8:
    ld a, [de]
    inc de
    cp $d9
    ret z

    cp $d8
    jr nz, jr_009_40f7

    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    jr jr_009_40d8

jr_009_40f7:
    ld [hl+], a
    jr jr_009_40d8

LoadFld9_40fa:
    ; THE BANK $09 SCREEN PUSH (S117b): every bank $09 screen (shops, the arena
    ; class menu, the other screen effects) is composed in WRAM at $C500
    ; (18 rows x 32: SetFld9_4204 copies the room's tiles $C300 + the HUD
    ; $C1C0, then the windows are drawn into it — font / frame tiles >= $80)
    ; and pushed here to the BG map at [$C909] (the scroll-aligned origin,
    ; map rows wrap). Tile ids only: the cells keep the room's GBC attributes.
    ; Patched builds: a same-size far call to bank $77 ScreenPush (palette
    ; attributes in free-colour custom rooms; DATA_STRUCTURES "Shops (S117)").
    ld a, [$c909]
    ld l, a
    ld a, [$c90a]
    ld h, a
    ld de, $c500
    ld c, $12

jr_009_4107:
    ld b, $20
    push hl

jr_009_410a:
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
    jr nz, jr_009_410a

    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, jr_009_4107

    ret


LoadFld9_412f:
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


SaveFld9_4168:
    push hl
    ld hl, $c180
    call Copy4Bytes
    pop hl
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0401
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


FuncFld9_41b6:
    ld [$c180], a
    ld a, $f0
    ld [$c181], a
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0101
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ret


SetFld9_4204:
    ld hl, $c500
    ld de, $c300
    ld bc, $0200

jr_009_420d:
    ld a, [de]
    inc de
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_009_420d

    ld de, $c1c0
    ld c, $02

jr_009_421a:
    ld b, $14

jr_009_421c:
    ld a, [de]
    inc de
    ld [hl+], a
    dec b
    jr nz, jr_009_421c

    ld a, e
    add $0c
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ld a, l
    add $0c
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec c
    jr nz, jr_009_421a

    ret


SetFld9_4236:
    ld hl, $c500
    ld bc, $0240

jr_009_423c:
    ld a, $e0
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, jr_009_423c

    ret


    ld hl, $9800
    ld bc, $0400

jr_009_424b:
    ld a, $e0
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, jr_009_424b

    ret


LoadFld9_4256:
    ld a, c
    ld [$c8e1], a
    inc de
    inc de
    ld a, [$c825]
    or a
    jp nz, Jump_009_42cf

    ld a, [wJoypad_current_frame]
    bit 5, a
    jr z, jr_009_428c

    ld a, [$df0d]
    inc a
    and $01
    ld [$df0d], a
    inc hl
    ld a, [hl]
    dec a
    push af
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_009_42b3

    ld a, c
    dec a
    jr jr_009_42b3

jr_009_428c:
    ld a, [wJoypad_current_frame]
    bit 4, a		  ; checking if your pressing right
    jr z, jr_009_42cf

    ld a, [$df0d]	;df0d = the current page in the shop, but changing it does not update the page number on screen.
    inc a		;inc a to open the message window
    and $01		;and a with 01 to make sure it's the only bit set
    ld [$df0d], a   ; load the contents of a (mesage window status) into df0d
    inc hl  ; add 1 to hl (unknown pointer)
    ld a, [hl]  ; load the contents of hl (unknown pointer +1) into a
    inc a   ; add 1 to a
    push af
    push de
    push bc
    ld a, b     ; load the contents of b
    ld b, c
    dec b
    call Div8x8
    ld a, b
    inc a
    pop bc
    pop de
    ld c, a
    pop af
    cp c
    jr c, jr_009_42b3

    ld a, $00

jr_009_42b3:
    ld [hl-], a     ; load the contents of a (unknown pointer) into hl then -1
    dec c   ; subtract 1 from c
    cp c    ; compare a and c
    jr nz, jr_009_4312  ; if the last resault was not 0 jump to 4312

    ld a, [$c8e1]   ; load the contents of c8e1 () into a
    ld c, a     ; load the contents of a (c8el)into c
    push de
    push bc
    ld a, b     ; load the contents of b (unknown variable) into a
    ld b, c     ; load the contents of c (c8el) into b
    call Div8x8
    pop bc
    pop de
    or a
    jr z, jr_009_4312

    dec a   ; subtract 1 from a
    cp [hl]     ; compare hl (unknown pointer -1) to a
    jr nc, jr_009_4312

    ld [hl], a  ; load the contents of a ( which must be smaller than hl) into hl
    jr jr_009_4312

Jump_009_42cf:
jr_009_42cf:
    push bc
    push de
    push hl
    call LoadFld9_448e
    pop hl
    pop de
    pop bc
    push de
    push bc
    ld a, b
    ld b, c
    dec b
    call Div8x8
    ld [$c8e1], a
    ld a, b
    pop bc
    pop de
    ld c, a
    inc hl
    ld a, [hl-]
    cp c
    jr nz, jr_009_42f1

    ld a, [$c8e1]
    inc a
    ld b, a

FuncFld9_42f1:
jr_009_42f1:
    res 7, [hl]		; set contents of bit 7 of hl ($c8da) to 0
    ld a, [wJoypad_Current]	; load the contents of wJoypad_Current (current button) into register a
    bit 6, a		; check to see if bit 6 (up) is pressed
    jr z, jr_009_4303	; if the last math op resulted in 0 jump to 4303

    ld a, [hl]		; load the contents of hl ($c8da) into a
    dec a		; subtract 1 from the contents of a
    cp b		; Compare the contents of b ($03) to a
    jr c, jr_009_4311	; if cary flag is set jump to 4311

    dec b		; subtract 1 from the contents of b
    ld a, b		; load the contents of b ($02) into a
    jr jr_009_4311	; jump to 4311

jr_009_4303:
    ld a, [wJoypad_Current]	; load currently pressed button into a
    bit 7, a		; checking to see if bit 7 (down) is pressed
    jr z, jr_009_431a	; if the last math op resulted in 0 jump to 431a

    ld a, [hl]  ; load the contents of hl ($c8da current menue option) into a
    inc a   ; add 1 to the contents of a ($c8da current menue option)
    cp b    ; compare a and b
    jr c, jr_009_4311   ; if cary flag is set jump to 4311

    ld a, $00   ; load $00 into a

jr_009_4311:
    ld [hl], a  ; load next menue option (a) into curent menue option (hl)

jr_009_4312:
    xor a   ; set the contents of a to 0
    ld [$c90c], a   ; load the contents of a (0) into $c90c (reset cursor blink timer)
    push hl     ; incomplete function
    push de
    pop de
    pop hl  ; end of incomplete function

jr_009_431a:
    ld a, [wJoypad_current_frame]   ; load the contents of wJoypad_current_frame (currently pressed button) into a
    bit 0, a    ; checking to see if bit 0 (a button) is pressed
    jr z, jr_009_4323   ; if the last math op resulted in 0 jump to 4323

    set 7, [hl]     ; sets bit 7 of hl (current menue option) to 1

jr_009_4323:
    ld a, [hl]  ; load the contents of hl (c8da current menue option) to a
    call FuncFld9_442f
    ret

;FUNCTION UNCALLED (checks for pushing left and right)
    res 7, [hl]
    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_009_433a

    ld a, [hl]
    dec a
    cp b
    jr c, jr_009_4311

    dec b
    ld a, b
    jr jr_009_4311

jr_009_433a:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_431a

    ld a, [hl]
    inc a
    cp b
    jr c, jr_009_4311

    ld a, $00
    jr jr_009_4311

FuncFld9_434a:
    res 7, [hl]     ; set contents of bit 7 of hl ($c8da) to 0
    ld a, c     ; load the contents of c (unknown pointer) into a
    ldh [$d7], a
    ld a, [wJoypad_Current]
    bit 7, a
    jr z, jr_009_4360

    ld a, $10
    ld [wCursorBlinkTimer], a
    call SaveFld9_43b7
    jr jr_009_4394

jr_009_4360:
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_009_4371

    ld a, $10
    ld [wCursorBlinkTimer], a
    call SaveFld9_43fe
    jr jr_009_4394

jr_009_4371:
    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_009_4381

    ld a, [hl]
    dec a
    cp b
    jr c, jr_009_438f

    dec b
    ld a, b
    jr jr_009_438f

jr_009_4381:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_4398

    ld a, [hl]
    inc a
    cp b
    jr c, jr_009_438f

    ld a, $00

jr_009_438f:
    ld [hl], a
    xor a
    ld [wCursorBlinkTimer], a

jr_009_4394:
    push hl
    push de
    pop de
    pop hl

jr_009_4398:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_009_43a1

    set 7, [hl]

jr_009_43a1:
    ldh a, [$d7]
    inc hl
    cp [hl]
    dec hl
    jr nc, jr_009_43aa

    inc hl
    ld [hl-], a

jr_009_43aa:
    inc hl
    ld a, [hl]
    or a
    jr nz, jr_009_43b1

    ld [hl], $01

jr_009_43b1:
    dec hl
    ld a, [hl]
    call FuncFld9_456d
    ret


SaveFld9_43b7:
    push de
    ld a, [hl]
    push hl
    inc hl
    ld c, [hl]
    ld b, $00
    ld hl, wDebug_main_menu_option
    call PrintNumber
    pop hl
    ld a, [hl]
    ld de, wDebug_main_menu_option
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    and $0f
    dec a
    ld [de], a
    cp $ff
    jr nz, jr_009_43db

    ld a, $09
    ld [de], a

jr_009_43db:
    call SaveFld9_43e9
    pop de
    or a
    ret nz

    ld a, [hl]
    or a
    ret z

    ld a, $09
    inc hl
    ld [hl-], a
    ret


SaveFld9_43e9:
    push hl
    ld a, [wDebug_main_menu_option]
    and $0f
    ld c, $0a
    call Mul8x8To16
    ld a, [$c0a1]
    and $0f
    add l
    pop hl
    inc hl
    ld [hl-], a
    ret


SaveFld9_43fe:
    push de
    ld a, [hl]
    push hl
    inc hl
    ld c, [hl]
    ld b, $00
    ld hl, wDebug_main_menu_option
    call PrintNumber
    pop hl
    ld de, $c0a1
    ld a, [hl]
    ld de, wDebug_main_menu_option
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    and $0f
    inc a
    ld [de], a
    cp $0a
    jr nz, jr_009_4425

    ld a, $00
    ld [de], a

jr_009_4425:
    call SaveFld9_43e9
    pop de
    ret

ClrFld9_442a:
    xor a
    ld [$c90c], a
    ret


FuncFld9_442f:
    ld c, a     ; load the contents of a (current menue option) into c
    bit 7, a    ; check to see if bit 7 (down is pressed)
    jr nz, jr_009_4444  ; if the last math op resaulted in 0 jump to 4444

    ld a, [$c90c]   ; load c90c (blinker timer) into a
    and $0f     ; put lower nybble of timer into a
    push af     ; coppy contents of af onto stack
    ld a, [$c90c]   ; load c90c (blinker timer) into a
    inc a   ; add 1 to the contents of a (blinker timer)
    ld [$c90c], a   ; load a into c90c (blinker timer)
    pop af  ; remove contents of af from stack and put them into af
    ld a, c     ; load the contents of c (c8da current menue option) into a
    ret nz  ; return if last resault was not 0

jr_009_4444:
    ld c, a     ; load the contents of a (current menue option) into c
    ld b, $00   ; load $00 into b

jr_009_4447:
    ld a, [de]  ; load the contents of de (unknown pointer) to a
    ld l, a     ; load the contents of a (unknown pointer) into l
    inc de  ; add 1 to de (unknown pointer)
    ld a, [de]  ; load the contents of de (unknown pointer +1) into a
    ld h, a     ; load the contents of a (unknown pointer +1) into h
    inc de  ; add 1 to de
    and l   ; compares h and l (to set flags)
    cp $ff  ; compares h to ff
    ret z   ; returns to the function that called this one if last resault was 0

    ld a, l     ; load the contents of l (unknown pointer) into a
    ldh [$d5], a    ;
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_009_4477

    ld a, $e9
    bit 7, c
    jr nz, jr_009_4477

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_009_4477

    ld a, $e8

jr_009_4477:
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_009_4447

LoadFld9_448e:
    ld a, b
    cp c
    ret nc

    inc hl
    ld c, [hl]
    dec de
    dec de
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    dec hl
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, c
    and $7f
    cp $09
    jr z, jr_009_44b6

    add $f1
    call SaveFld9_44db
    ld a, $ee
    jr jr_009_44bd

jr_009_44b6:
    ld a, $f0
    call SaveFld9_44db
    ld a, $f1

jr_009_44bd:
    push af
    ldh a, [$d5]
    sub $01
    ldh [$d5], a
    ldh a, [$d6]
    sbc $00
    ldh [$d6], a
    pop af
    call SaveFld9_44db
    ldh a, [$d5]
    add $01
    ldh [$d5], a
    ldh a, [$d6]
    adc $00
    ldh [$d6], a
    ret


SaveFld9_44db:
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    pop af
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


ReadFld9_44ff:
    ld a, [hl+]
    push af
    push hl
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    inc de
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    ld a, b
    cp c
    ld a, $ee
    jr nc, jr_009_4518

    ld a, $e7

jr_009_4518:
    ld [hl-], a
    pop bc
    jr nc, jr_009_452f

    ld a, [bc]
    cp $09
    jr z, jr_009_4529

    add $f1
    ld [hl-], a
    ld a, $ee
    ld [hl+], a
    jr jr_009_452f

jr_009_4529:
    ld a, $f0
    ld [hl-], a
    ld a, $f1
    ld [hl+], a

jr_009_452f:
    pop af

FuncFld9_4530:
    ld c, a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, $e9
    bit 7, c
    jr nz, jr_009_455b

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_009_455b

    ld a, $e8

jr_009_455b:
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


FuncFld9_456d:
    ld c, a
    inc hl
    push de
    push bc
    ld c, [hl]
    ld b, $00
    ld hl, wDebug_main_menu_option
    call PrintNumber
    pop bc
    pop de
    bit 7, c
    jr nz, jr_009_4590

    ld a, [wCursorBlinkTimer]
    and $0f
    push af
    ld a, [wCursorBlinkTimer]
    inc a
    ld [wCursorBlinkTimer], a
    pop af
    ld a, c
    ret nz

jr_009_4590:
    ld c, a
    ld b, $00

jr_009_4593:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_009_45bd

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_009_45bd

    ld a, $e6

jr_009_45bd:
    cp $e0
    jr nz, jr_009_45ce

    push hl
    ld a, b
    ld hl, wDebug_main_menu_option
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl

jr_009_45ce:
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_009_4593

; ScreenEffectSay (S117): HL = a text OFFSET; adds the screen effect's text
; base [$C8F0/$C8F1] (script opcode $04's second word — $0680 for the shops:
; $0681 Anything else? $0683 What would you like? $0685 How many? ...) and
; queues it (ROM0 TextBankDispatch).
ScreenEffectSay:
    ld a, [$c8f0]
    add l
    ld l, a
    ld a, [$c8f1]
    adc h
    ld h, a
    call TextBankDispatch
    ret


ShopOuterMachine:
    ; SHOP (screen effect type 0 = script opcode $04 $0000 <text base>; S117).
    ; Outer machine on $C905: 0 window, 1 one frame, 2 gold box, 3 menu
    ; cursor, 4 = the BUY / SELL / QUIT choice (ShopMenuTable).
    ld a, [$c905]
    rst $00
ShopOuterStateTable:
    dw $4601   ; [ 0]
    dw $464c   ; [ 1]
    dw $4691   ; [ 2]
    dw $46e7   ; [ 3]
    dw $46f1   ; [ 4] -> state 4 = the menu choice (the wMenu_selection dispatch)
    ld hl, $ffb7
    call ReadFld9_403d
    ld hl, $ffbb
    call ReadFld9_403d
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
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
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetFld9_4204
    ld de, $2e0e
    ld hl, $8800
    call WaitDMATransfer
    call ClrFld9_442a
    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    call SetFld9_4204
    call SetFld9_465a
    call LoadFld9_40fa
    ret


SetFld9_465a:
    ld de, $6f3c
    call LoadFld9_40c9
    ld de, $6f1f
    call LoadFld9_40c9
    ld de, $2e07
    call LoadFld9_40c9
    ld a, [wCurrGoldLo]
    ldh [$d5], a
    ld a, [wCurrGoldMid]
    ldh [$d6], a
    ld a, [wCurrGoldHi]
    ldh [$d7], a
    ld hl, $002e
    call LoadFld9_406d
    call ConvertNumberToText
    call ClrFld9_442a
    ld de, ShopMenuCursorTable
    ld a, [wMenu_selection]
    call FuncFld9_4530
    ret


    ld de, ShopMenuCursorTable
    ld hl, wMenu_selection
    ld b, $03
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    and $0a
    jr z, jr_009_46ad

    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    jr jr_009_46de

jr_009_46ad:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_009_46de

    ld a, $59
    call PlaySoundEffect
    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    set 7, [hl]
    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    jr jr_009_46de

jr_009_46de:
    ret


ShopMenuCursorTable:
    ; the BUY / SELL / QUIT cursor table (column word, rows, $FFFF; S117)
    db $21, $00, $61, $00, $a1, $00, $ff, $ff
    ld a, [wMenu_selection]
    rst $00
ShopMenuTable:
    dw $4707   ; [ 0] BUY  (ShopBuyStateTable)
    dw $4aeb   ; [ 1] SELL (ShopSellStateTable)
    dw $46f1   ; [ 2] QUIT (close: wGameState bit 4 off, $C905 := 0)
    call SetFld9_4204
    ld de, $2e07
    call LoadFld9_40c9
    call LoadFld9_40fa
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
ShopBuyStateTable:
    ; BUY inner machine on $C906 (S117). State 0 = the STOCK FILL below.
    dw $4721   ; [ 0] ShopBuyStockFill
    dw $4795   ; [ 1]
    dw $4890   ; [ 2]
    dw $48f8   ; [ 3]
    dw $4908   ; [ 4]
    dw $494c   ; [ 5]
    dw $4993   ; [ 6]
    dw $49fa   ; [ 7]
    dw $4a1e   ; [ 8]
    dw $4a6a   ; [ 9]
    dw $4aca   ; [10]
ShopBuyStockFill:
    ; buy state 0: 'What would you like?' (text base + 3), then the shop's
    ; list -> $C0D8 (20 B, $FF-terminated): map $50 (the gate-floor shop) ->
    ; GateworldShopInventory, else by wScreenIndex 0 Bazaar / 2 StarryNight /
    ; 4 Bookstore / 5 (and any other screen) RareItemShopInventory — so a
    ; vanilla shop is chosen by the SCREEN it stands on. Patched builds
    ; replace the choice + copy with a same-size far call to bank $77
    ; ShopFill (the project's shops, gamedata.shops; S117).
    ld hl, $0003
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ld a, [wMapID]
    ld hl, GateworldShopInventory
    cp $50  ;ID for gateworld shop map
    jr z, .clear_shop_inventory

    ld a, [wScreenIndex]
    ld hl, BazaarInventory
    cp $00
    jr z, .clear_shop_inventory

    ld hl, StarryNightShopInventory
    cp $02
    jr z, .clear_shop_inventory

    ld hl, BookstoreInventory
    cp $04
    jr z, .clear_shop_inventory

    ld hl, RareItemShopInventory
    cp $05
    jr z, .clear_shop_inventory

.clear_shop_inventory:
    push hl
    ld hl, $c0d8 ;shop inventory
    ld bc, $0014
    xor a
    call FillNBytesWithRegA
    pop hl
    ld de, $c0d8

.fill_inventory_loop:
    ld a, [hl+]
    ld [de], a
    inc de
    cp $ff
    ret z

    jr .fill_inventory_loop


BazaarInventory:
    db ITEM_HERB
    db ITEM_LOVEWATER
    db ITEM_ANTIDOTE
    db ITEM_REPELLANT
    db ITEM_BEEF_JERKY
    db ITEM_PORK_CHOP
    db ITEM_WARP_WING
    db ITEM_BEAST_TAIL
    db $ff


StarryNightShopInventory:
    db ITEM_POTION
    db ITEM_WORLD_DEW
    db ITEM_SAGE_STONE
    db ITEM_WORLD_LEAF
    db ITEM_MAP_HERB
    db ITEM_BOOK_MARK
    db ITEM_RIB
    db ITEM_MIST_STAFF
    db $ff

BookstoreInventory:
    db ITEM_QUEST_BK
    db ITEM_HORROR_BK
    db ITEM_BENICE_BK
    db ITEM_CHEATER_BK
    db ITEM_SMART_BK
    db ITEM_COMEDY_BK
    db $ff

RareItemShopInventory:
    db ITEM_SIRLOIN
    db ITEM_SHINY_HARP
    db ITEM_WIND_STAFF
    db ITEM_LAVA_STAFF
    db ITEM_BOLT_STAFF
    db ITEM_SNOW_STAFF
    db ITEM_FIRE_STAFF
    db $ff


GateworldShopInventory:
    db ITEM_HERB
    db ITEM_LOVEWATER
    db ITEM_ANTIDOTE
    db ITEM_MOON_HERB
    db ITEM_AWAKE_SAND
    db ITEM_SKY_BELL
    db ITEM_LAUREL
    db ITEM_WORLD_LEAF
    db $ff


    ld a, [$c825]
    or a
    ret nz

    call ShopCountItems
    call ShopDrawNames
    call CallFld9_47a8
    ld hl, $c906

jr_009_47a6:
    inc [hl]
    ret


CallFld9_47a8:
    call SetFld9_4204
    call SetFld9_465a
    ld de, $6f7d
    call LoadFld9_40c9
    call ShopDrawPrices
    call ClrFld9_442a
    ld de, $48ec
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    call LoadFld9_40fa
    ret


; ShopDrawNames (S117): the names of the 3 visible list rows from [$C8E3]
; (the first row shown) to VRAM $8800.
ShopDrawNames:
    ld de, $c0d8
    ld a, [$c8e3]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8800
    call SaveFld9_47e7
    call SaveFld9_47e7
    call SaveFld9_47e7

SaveFld9_47e7:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr nz, jr_009_47f0

    ld a, $00

jr_009_47f0:
    ld [$c823], a
    ld a, $08
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    call LoadFld9_412f
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


; ShopDrawPrices (S117): the BUY price of the 3 visible rows (ItemInfoTable
; +1/+2 via bank $03 entry 2 -> $DA63/$DA64) as numbers + 'G'.
ShopDrawPrices:
    ld de, $c0d8
    ld a, [$c8e3]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $00ad
    call SaveFld9_4824
    call SaveFld9_4824
    call SaveFld9_4824

SaveFld9_4824:
    push de
    push hl
    ld a, [de]
    cp $00
    jr z, jr_009_482f

    cp $ff
    jr nz, jr_009_483c

jr_009_482f:
    call LoadFld9_406d
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    jr jr_009_4869

jr_009_483c:
    push hl
    ld a, [de]
    ld [$da5e], a
    ld hl, $0302
    rst $10
    pop hl
    push hl
    call LoadFld9_406d
    ld a, [$da63]
    ldh [$d5], a
    ld a, [$da64]
    ldh [$d6], a
    ld a, $00
    ldh [$d7], a
    call ConvertNumberToText
    pop hl
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    call LoadFld9_406d
    ld [hl], $dd

jr_009_4869:
    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


; ShopCountItems (S117): [$C8E9] := the number of items in the shop list at
; $C0D8 (stops at 0 / $FF, at most 20).
ShopCountItems:
    ld hl, $c0d8
    call FuncFld9_4880
    ld a, c
    ld [$c8e9], a
    ret


FuncFld9_4880:
    ld b, $14
    ld c, $00

jr_009_4884:
    ld a, [hl+]
    cp $00
    ret z

    cp $ff
    ret z

    inc c
    dec b
    jr nz, jr_009_4884

    ret


    ld de, $48ec
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadFld9_4256
    pop af
    ld hl, $c8e2
    and $7f
    ld b, a
    ld a, [hl]
    and $7f
    cp b
    jr z, jr_009_48b1

jr_009_48b1:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_009_48c1

    call ShopDrawNames
    call ShopDrawPrices
    call LoadFld9_40fa

jr_009_48c1:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_48d5

    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    jr jr_009_48eb

jr_009_48d5:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_48eb

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    ld a, $01
    ld [$c8dd], a

Jump_009_48eb:
jr_009_48eb:
    ret


    sub d
    ld bc, $00a2
    ld [c], a
    nop
    ld [hl+], a
    ld bc, $0162
    rst $38
    rst $38
    ld hl, $0005
    call ScreenEffectSay
    ld a, $01
    ld [wPLAN_selection], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_4915
    ld hl, $c906
    inc [hl]
    ret


CallFld9_4915:
    call SetFld9_4204
    call SetFld9_465a
    ld de, $6f7d
    call LoadFld9_40c9
    call ShopDrawPrices
    ld de, $48ec
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    ld de, $7033
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $498d
    ld hl, wPLAN_selection
    ld b, $02
    ld a, [hl]
    call FuncFld9_456d
    call LoadFld9_40fa
    ret


    ld de, $498d
    ld hl, wPLAN_selection
    ld b, $02
    ld c, $14
    call FuncFld9_434a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_497b

    call CallFld9_47a8
    ld hl, $0004
    call ScreenEffectSay
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_498c

jr_009_497b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_498c

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_498c:
jr_009_498c:
    ret


    ld h, c
    ld bc, $0162
    rst $38
    rst $38
    ld hl, $c0d8
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$da5e], a
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld a, [$c8dd]
    ld hl, $c190
    call ExtractDigits
    ld hl, $0302
    rst $10
    ld a, [$da63]
    ld c, a
    ld a, [$da64]
    ld b, a
    ld a, [$c8dd]
    call Mul16x8To24
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, e
    ldh [$d7], a
    ld a, l
    ld [$c8e4], a
    ld a, h
    ld [$c8e5], a
    ld a, e
    ld [$c8e6], a
    ld hl, $c1a0
    call FormatLargeNumber
    ld hl, $0006
    call ScreenEffectSay
    xor a
    ld [$c8de], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld de, $6efa
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $4a64
    ld a, [$c8de]
    call FuncFld9_4530
    call LoadFld9_40fa
    ld hl, $c906
    inc [hl]
    ret


    ld de, $4a64
    ld hl, $c8de
    ld b, $02
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_4a4b

jr_009_4a30:
    call CallFld9_4915
    ld hl, $0005
    call ScreenEffectSay
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_4a63

jr_009_4a4b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_4a63

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_009_4a30

    ld hl, $c906
    inc [hl]

Jump_009_4a63:
jr_009_4a63:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld hl, $0305
    rst $10
    ld hl, $c8e4
    ld a, [wCurrGoldLo]
    sub [hl]
    inc hl
    ld a, [wCurrGoldMid]
    sbc [hl]
    inc hl
    ld a, [wCurrGoldHi]
    sbc [hl]
    ld hl, $0007
    jr c, jr_009_4ac2

    ld hl, wInventory
    call FuncFld9_4880
    ld a, [$c8dd]
    add c
    cp $15
    ld hl, $0008
    jr nc, jr_009_4ac2

    ld a, [$c8e4]
    ld l, a
    ld a, [$c8e5]
    ld h, a
    ld a, [$c8e6]
    ld e, a
    call AddGold
    ld hl, wInventory
    call FuncFld9_4880
    ld a, c
    ld hl, wInventory
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$c8dd]
    ld b, a
    ld a, [$da5e]

jr_009_4abb:
    ld [hl+], a
    dec b
    jr nz, jr_009_4abb

    ld hl, $0009

jr_009_4ac2:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld a, $00
    ld [$c906], a
    ret


    ld a, [$c906]
    rst $00
ShopSellStateTable:
    ; SELL inner machine on $C906 (S117); state 0 builds the sellable list.
    dw $4b09   ; [ 0]
    dw $4b27   ; [ 1]
    dw $4c81   ; [ 2]
    dw $4ce9   ; [ 3]
    dw $4cf9   ; [ 4]
    dw $4d6b   ; [ 5]
    dw $4dbb   ; [ 6]
    dw $4e05   ; [ 7]
    dw $4e29   ; [ 8]
    dw $4e73   ; [ 9]
    dw $4ebc   ; [10]
    dw $4edd   ; [11]
    dw $4ee8   ; [12]
    call SetFld9_4c24
    ld hl, $c0d8
    call FuncFld9_4880
    ld a, c
    or a
    jr nz, jr_009_4b1c

    ld a, $0b
    ld [$c906], a
    ret


jr_009_4b1c:
    ld hl, $000a
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetFld9_4c24
    call ShopCountItems
    call ShopDrawNames
    call CallFld9_4b3d
    ld hl, $c906
    inc [hl]
    ret


CallFld9_4b3d:
    call SetFld9_4204
    call SetFld9_465a
    ld de, $6f7d
    call LoadFld9_40c9
    call SetFld9_4b62
    call ClrFld9_442a
    ld de, $4cdd
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    call LoadFld9_40fa
    ret


SetFld9_4b62:
    ld de, $c0d8
    ld a, [$c8e3]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $00ad
    call SaveFld9_4b7c
    call SaveFld9_4b7c
    call SaveFld9_4b7c

SaveFld9_4b7c:
    push de
    push hl
    ld a, [de]
    cp $00
    jr z, jr_009_4b87

    cp $ff
    jr nz, jr_009_4b94

jr_009_4b87:
    call LoadFld9_406d
    ld a, $e0
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    jr jr_009_4bbc

jr_009_4b94:
    push hl
    push hl
    ld a, [de]
    ld [$da5e], a
    call ShopSellPrice
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, $00
    ldh [$d7], a
    pop hl
    call LoadFld9_406d
    call ConvertNumberToText
    pop hl
    ld a, l
    add $05
    ld l, a
    ld a, h
    adc $00
    ld h, a
    call LoadFld9_406d
    ld [hl], $dd

jr_009_4bbc:
    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


; ShopSellPrice (S117): HL = what the shop PAYS for item [$DA5E]: the full
; price in the gate-floor shop (map $50); a staff ($18-$1C, $25 FireStaff,
; $27 WarpStaff) price / 10; anything else price - price / 4 (3/4).
ShopSellPrice:
    ld hl, $0302
    rst $10
    ld a, [$da63]
    ld l, a
    ld a, [$da64]
    ld h, a
    ld a, [wMapID]
    cp $50
    ret z

    ld a, [$da5e]
    cp $18
    jr z, jr_009_4bfb

    cp $19
    jr z, jr_009_4bfb

    cp $1a
    jr z, jr_009_4bfb

    cp $1b
    jr z, jr_009_4bfb

    cp $1c
    jr z, jr_009_4bfb

    cp $25
    jr z, jr_009_4bfb

    cp $27
    jr z, jr_009_4bfb

    jr jr_009_4c09

jr_009_4bfb:
    ld a, [$da63]
    ld l, a
    ld a, [$da64]
    ld h, a
    ld a, $0a
    call Div16x8To16
    ret


jr_009_4c09:
    ld a, [$da63]
    ld l, a
    ld a, [$da64]
    ld h, a
    srl h
    rr l
    srl h
    rr l
    ld a, [$da63]
    sub l
    ld l, a
    ld a, [$da64]
    sbc h
    ld h, a
    ret


SetFld9_4c24:
    ld hl, $0305
    rst $10
    ld hl, $d665
    ld bc, $0030
    xor a
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld bc, $0014
    xor a
    call FillNBytesWithRegA
    ld de, wInventory
    ld b, $14

jr_009_4c41:
    ld a, [de]
    or a
    jr z, jr_009_4c6b

    cp $ff
    jr z, jr_009_4c6b

    ld [$da5e], a
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    push de
    push bc
    ld hl, $0302
    rst $10
    pop bc
    pop de
    pop hl
    inc de
    ld a, [$da6d]
    bit 0, a
    jr nz, jr_009_4c68

    inc [hl]

jr_009_4c68:
    dec b
    jr nz, jr_009_4c41

jr_009_4c6b:
    ld hl, $d666
    ld de, $c0d8
    ld b, $2f
    ld c, $01

jr_009_4c75:
    ld a, [hl+]
    or a
    jr z, jr_009_4c7c

    ld a, c
    ld [de], a
    inc de

jr_009_4c7c:
    inc c
    dec b
    jr nz, jr_009_4c75

    ret


    ld de, $4cdd
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadFld9_4256
    pop af
    ld hl, $c8e2
    and $7f
    ld b, a
    ld a, [hl]
    and $7f
    cp b
    jr z, jr_009_4ca2

jr_009_4ca2:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_009_4cb2

    call ShopDrawNames
    call SetFld9_4b62
    call LoadFld9_40fa

jr_009_4cb2:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_4cc6

    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    jr jr_009_4cdc

jr_009_4cc6:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_4cdc

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    ld a, $01
    ld [$c8dd], a

Jump_009_4cdc:
jr_009_4cdc:
    ret


    sub d
    ld bc, $00a2
    ld [c], a
    nop
    ld [hl+], a
    ld bc, $0162
    rst $38
    rst $38
    ld hl, $000c
    call ScreenEffectSay
    ld a, $01
    ld [wPLAN_selection], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_4d06
    ld hl, $c906
    inc [hl]
    ret


CallFld9_4d06:
    call SetFld9_4204
    call SetFld9_465a
    ld de, $6f7d
    call LoadFld9_40c9
    call SetFld9_4b62
    ld de, $4cdd
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    ld de, $7044
    call LoadFld9_40c9
    ld hl, $c0d8
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$da5e], a
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $00
    ld hl, $0164
    call LoadFld9_406d
    call CopyHLtoDE
    call ClrFld9_442a
    ld de, $4db5
    ld hl, wPLAN_selection
    ld b, $02
    ld a, [hl]
    call FuncFld9_456d
    call LoadFld9_40fa
    ret


    ld de, $4db5
    ld hl, $d665
    ld a, [$da5e]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $02
    ld hl, wPLAN_selection
    call FuncFld9_434a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_4da3

    call CallFld9_4b3d
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_4db4

jr_009_4da3:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_4db4

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_4db4:
jr_009_4db4:
    ret


    ld h, c
    ld bc, $0162
    rst $38
    rst $38
    ld a, [$da5e]
    ld l, a
    ld h, $08
    ld de, $c180
    call SetupVRAMParams
    ld a, [$c8dd]
    ld hl, $c190
    call ExtractDigits
    call ShopSellPrice
    ld c, l
    ld b, h
    ld a, [$c8dd]
    call Mul16x8To24
    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    ld a, e
    ldh [$d7], a
    ld a, l
    ld [$c8e4], a
    ld a, h
    ld [$c8e5], a
    ld a, e
    ld [$c8e6], a
    ld hl, $c1a0
    call FormatLargeNumber
    ld hl, $000d
    call ScreenEffectSay
    xor a
    ld [$c8de], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld de, $6efa
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $4e6d
    ld a, [$c8de]
    call FuncFld9_4530
    call LoadFld9_40fa
    ld hl, $c906
    inc [hl]
    ret


    ld de, $4e6d
    ld hl, $c8de
    ld b, $02
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_4e54

jr_009_4e3b:
    call CallFld9_4d06
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_4e6c

jr_009_4e54:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_4e6c

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_009_4e3b

    ld hl, $c906
    inc [hl]

Jump_009_4e6c:
jr_009_4e6c:
    ret


    cpl
    ld bc, $016f
    rst $38
    rst $38
    ld hl, $c8e4
    ld a, [wCurrGoldLo]
    add [hl]
    ld e, a
    inc hl
    ld a, [wCurrGoldMid]
    adc [hl]
    ld d, a
    inc hl
    ld a, [wCurrGoldHi]
    adc [hl]
    ld c, a
    ld a, e
    sub $a0
    ld a, d
    sbc $86
    ld a, c
    sbc $01
    ld hl, $000e
    jr nc, jr_009_4eb4

    ld a, [$c8e4]
    ld l, a
    ld a, [$c8e5]
    ld h, a
    ld a, [$c8e6]
    ld e, a
    call CompareGold
    ld a, [$c8dd]
    ld b, a

jr_009_4ea8:
    push bc
    ld hl, $0307
    rst $10
    pop bc
    dec b
    jr nz, jr_009_4ea8

    ld hl, $000f

jr_009_4eb4:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld a, $00
    ld [$c906], a
    ret


    ld hl, $000b
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    ret


; VaultScreen: screen effect type 2 — the Vault menu (PUT / TAKE / EXIT; text base $06A0, op $04 2 $06A0); S126 annotation
VaultScreen:
    ld a, [$c905]
    rst $00


    dec bc
    ld c, a
    ld d, [hl]
    ld c, a
    or e
    ld c, a
    inc hl
    ld d, b
    add b
    ld d, b
    add sp, $50
    inc b
    ld d, c
    ld hl, $ffb7
    call ReadFld9_403d
    ld hl, $ffbb
    call ReadFld9_403d
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
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
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetFld9_4204
    ld de, $2e0f
    ld hl, $8800
    call WaitDMATransfer
    call ClrFld9_442a
    ld hl, $c905
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $c905
    inc [hl]
    call SetFld9_4204
    call LoadFld9_4f69
    call LoadFld9_40fa
    ret


LoadFld9_4f69:
    ld a, $02
    ld [$c822], a
    ld a, $0b
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    ld de, $7838
    call LoadFld9_40c9
    ld de, $6f1f
    call LoadFld9_40c9
    ld de, $2e07
    call LoadFld9_40c9
    ld a, [wCurrGoldLo]
    ldh [$d5], a
    ld a, [wCurrGoldMid]
    ldh [$d6], a
    ld a, [wCurrGoldHi]
    ldh [$d7], a
    ld hl, $002e
    call LoadFld9_406d
    call ConvertNumberToText
    call ClrFld9_442a
    ld de, $501b
    ld a, [wMenu_selection]
    call FuncFld9_4530
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $501b
    ld hl, wMenu_selection
    ld b, $03
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    and $0a
    jr z, jr_009_4fdc

    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    jr jr_009_501a

jr_009_4fdc:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_009_501a

    ld a, $59
    call PlaySoundEffect
    ld a, [wMenu_selection]
    cp $82
    jp z, Jump_009_5104

    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    set 7, [hl]
    ld hl, wOPTN_and_Item_selection
    ld bc, $0007
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $0003
    ld a, [wMenu_selection]
    and $7f
    jr z, jr_009_5015

    ld hl, $000e

jr_009_5015:
    call ScreenEffectSay
    jr jr_009_501a

jr_009_501a:
    ret


    ld hl, $6100
    nop
    and c
    nop
    rst $38
    rst $38
    ld a, [$c825]
    or a
    ret nz

    ld hl, $c905
    inc [hl]
    call SetFld9_4204
    call SetFld9_5049
    call LoadFld9_40fa
    ld a, $02
    ld [$c822], a
    ld a, $0c
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    ret


SetFld9_5049:
    ld de, $7838
    call LoadFld9_40c9
    ld de, $6f1f
    call LoadFld9_40c9
    ld de, $2e07
    call LoadFld9_40c9
    ld a, [wCurrGoldLo]
    ldh [$d5], a
    ld a, [wCurrGoldMid]
    ldh [$d6], a
    ld a, [wCurrGoldHi]
    ldh [$d7], a
    ld hl, $002e
    call LoadFld9_406d
    call ConvertNumberToText
    call ClrFld9_442a
    ld de, $50b0
    ld a, [wOPTN_and_Item_selection]
    call FuncFld9_4530
    ret


    ld a, [$c825]
    or a
    ret nz

    ld de, $50b0
    ld hl, wOPTN_and_Item_selection
    ld b, $03
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    and $0a
    jr z, jr_009_50b8

    call SetFld9_4204
    call LoadFld9_4f69
    call LoadFld9_40fa
    ld hl, $0001
    call ScreenEffectSay
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    jr jr_009_50e7

    ld hl, $6100
    nop
    and c
    nop
    rst $38
    rst $38

jr_009_50b8:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_009_50e7

    ld a, $59
    call PlaySoundEffect
    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wOPTN_and_Item_selection
    set 7, [hl]
    ld hl, wPLAN_selection
    ld bc, $0006
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA

jr_009_50e7:
    ret


    ld a, [wMenu_selection]
    rst $00
    ldh a, [$50]
    ld a, [$fa50]
    db $db
    ret z

    rst $00
    ld a, [de]
    ld d, c
    xor a
    ld d, e
    inc b
    ld d, c
    ld a, [wOPTN_and_Item_selection]
    rst $00
    add hl, de
    ld d, l
    adc l
    ld d, a
    inc b
    ld d, c

Jump_009_5104:
    call SetFld9_4204
    ld de, $2e07
    call LoadFld9_40c9
    call LoadFld9_40fa
; S126: the Vault's close — the lower text box is left on screen (the room's
; tiles under it are not redrawn); patches/ replaces the 10 bytes below with a
; call of bank $77 ServiceCloseBox (re-seats the box like the shop's close).
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
    jr nc, @+$53

    ld h, c
    ld d, c
    nop
    ld d, d
    ld a, [hl]
    ld d, d
    adc [hl]
    ld d, d
    db $fd
    ld d, d
    ld c, a
    ld d, e
    ld a, l
    ld d, e
    sbc [hl]
    ld d, e
    ld hl, wInventory
    call CountFullInvSlots
    ld a, c
    or a
    ld hl, $0005
    jr z, jr_009_5158

    ld hl, wBankSlots
    ld b, $28
    call FuncFld9_51f2
    ld a, c
    cp $28
    ld hl, $0006
    jr nc, jr_009_5158

    ld hl, $c906
    inc [hl]
    ld hl, $0004
    call ScreenEffectSay
    ret


jr_009_5158:
    call ScreenEffectSay
    ld a, $08
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetFld9_5199
    call SetFld9_51e5
    call ShopDrawNames
    call CallFld9_5177
    ld hl, $c906
    inc [hl]
    ret


CallFld9_5177:
    call SetFld9_4204
    call SetFld9_5049
    ld de, $7153
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $5272
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    call LoadFld9_40fa
    ret


SetFld9_5199:
    ld hl, $0305
    rst $10
    ld hl, $d665
    ld bc, $0030
    xor a
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld bc, $0028
    xor a
    call FillNBytesWithRegA
    ld de, wInventory
    ld b, $14

jr_009_51b6:
    ld a, [de]
    or a
    jr z, jr_009_51cf

    cp $ff
    jr z, jr_009_51cf

    ld [$da5e], a
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc de
    inc [hl]
    dec b
    jr nz, jr_009_51b6

jr_009_51cf:
    ld hl, $d666
    ld de, $c0d8
    ld b, $2f
    ld c, $01

jr_009_51d9:
    ld a, [hl+]
    or a
    jr z, jr_009_51e0

    ld a, c
    ld [de], a
    inc de

jr_009_51e0:
    inc c
    dec b
    jr nz, jr_009_51d9

    ret


SetFld9_51e5:
    ld hl, $c0d8	;pointer to temp inventory storage loaded into hl
    call CountFullInvSlots
    ld a, c
    ld [$c8e9], a	;number of individual item ids the bank should display
    ret


CountFullInvSlots:		;find how many inv slots are full
    ld b, $28		;load number of inv slots into counter at reg b

FuncFld9_51f2:
    ld c, $00

jr_009_51f4:
    ld a, [hl+]		;loads contents of current inventory slot into reg a and increments to next one
    cp $00		;compares ID to 0
    ret z		;returns if a zero is found (currently unknown what writes 00 to inventory slots.)

    cp $ff		;compares item id to FF (empty slot)
    ret z		;return once an empty slot is reached.

    inc c		;if neither happens, increment c
    dec b
    jr nz, jr_009_51f4

    ret


    ld de, $5272
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadFld9_4256
    pop af
    ld hl, $c8e2
    and $7f
    ld b, a
    ld a, [hl]
    and $7f
    cp b
    jr z, jr_009_5221

jr_009_5221:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_009_522b

    call ShopDrawNames

jr_009_522b:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_525b

    ld a, $02
    ld [$c822], a
    ld a, $0c
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    call SetFld9_4204
    call SetFld9_5049
    call LoadFld9_40fa
    ld hl, $0003
    call ScreenEffectSay
    ld a, $04
    ld [$c905], a
    jr jr_009_5271

jr_009_525b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5271

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    ld a, $01
    ld [$c8de], a

Jump_009_5271:
jr_009_5271:
    ret


    ld [hl], d
    ld bc, $0089
    ret


    nop
    add hl, bc
    ld bc, HeaderRAMSize
    rst $38
    rst $38
    ld hl, $0007
    call ScreenEffectSay
    ld a, $01
    ld [$c8dd], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_529b
    ld hl, $c906
    inc [hl]
    ret


CallFld9_529b:
    call SetFld9_4204
    call SetFld9_5049
    ld de, $7153
    call LoadFld9_40c9
    ld de, $5272
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    ld de, $7044
    call LoadFld9_40c9
    ld hl, $c0d8
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$da5e], a
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $00
    ld hl, $0164
    call LoadFld9_406d
    call CopyHLtoDE
    call ClrFld9_442a
    ld de, $5349
    ld hl, $c8dd
    ld b, $02
    ld a, [hl]
    call FuncFld9_456d
    call LoadFld9_40fa
    ret


    ld de, $5349
    ld hl, $d665
    ld a, [$da5e]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $02
    ld hl, $c8dd
    call FuncFld9_434a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_5337

    call CallFld9_5177
    ld hl, $0004
    call ScreenEffectSay
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_5348

jr_009_5337:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5348

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_5348:
jr_009_5348:
    ret


    ld h, c
    ld bc, $0162
    rst $38
    rst $38
    ld hl, wBankSlots
    ld b, $28
    call FuncFld9_51f2
    ld a, [$c8de]
    add c
    cp $29
    ld hl, $0008
    jr nc, jr_009_5375

    ld a, [$c8de]
    ld b, a

jr_009_5366:
    push bc
    ld hl, $0307
    rst $10
    call LoadFld9_5b1a
    pop bc
    dec b
    jr nz, jr_009_5366

    ld hl, $0009

jr_009_5375:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wPLAN_selection
    ld bc, $0006
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld a, $00
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
    cp l
    ld d, e
    call c, $3953
    ld d, h
    sbc e
    ld d, h
    rst $38
    ld d, h
    ld hl, $000a
    call ScreenEffectSay
    ld a, $02
    ld [wPLAN_selection], a
    ld a, $00
    ld [$c8df], a
    ld a, $00
    ld [$c8e0], a
    ld a, $00
    ld [$c8e1], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_53e9
    ld hl, $c906
    inc [hl]
    ret


CallFld9_53e9:
    call SetFld9_4204
    call SetFld9_5049
    ld a, $02
    ld [$c822], a
    ld a, $55
    ld [$c823], a
    ld hl, $8a00
    ld de, $0401
    call LoadFld9_412f
    ld de, $71ca
    call LoadFld9_40c9
    ld de, $71e7
    call LoadFld9_40c9
    ld a, [$ca4e]
    ldh [$d5], a
    ld a, [$ca4f]
    ldh [$d6], a
    ld a, [$ca50]
    ldh [$d7], a
    ld hl, $016d
    call LoadFld9_406d
    call CoordClampHigh
    call ClrFld9_442a
    ld de, $548f
    ld hl, wPLAN_selection
    ld b, $02
    ld a, [hl]
    call FuncFld9_5a67
    call LoadFld9_40fa
    ret


    ld de, $548f
    ld hl, wPLAN_selection
    ld b, $03
    call FuncFld9_590c
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_5474

    ld a, $02
    ld [$c822], a
    ld a, $0c
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    call SetFld9_4204
    call SetFld9_5049
    call LoadFld9_40fa
    ld hl, $0003
    call ScreenEffectSay
    ld a, $04
    ld [$c905], a
    jr jr_009_548e

jr_009_5474:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_548e

    ld hl, $c8df
    ld a, [hl+]
    or [hl]
    inc hl
    or [hl]
    jr z, jr_009_548e

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_548e:
jr_009_548e:
    ret


    adc [hl]
    nop
    adc a
    nop
    sub b
    nop
    sub c
    nop
    sub d
    nop
    rst $38
    rst $38
    ld hl, $c8df
    ld a, [wCurrGoldLo]
    sub [hl]
    inc hl
    ld a, [wCurrGoldMid]
    sbc [hl]
    inc hl
    ld a, [wCurrGoldHi]
    sbc [hl]
    ld hl, $000b
    jr c, jr_009_54f7

    ld hl, $c8df
    ld a, [$ca4e]
    add [hl]
    ld e, a
    inc hl
    ld a, [$ca4f]
    adc [hl]
    ld d, a
    inc hl
    ld a, [$ca50]
    adc [hl]
    ld c, a
    ld a, e
    sub $40
    ld a, d
    sbc $42
    ld a, c
    sbc $0f
    ld hl, $000c
    jr nc, jr_009_54f7

    ld a, [$c8df]
    ld l, a
    ld a, [$c8e0]
    ld h, a
    ld a, [$c8e1]
    ld e, a
    call AddGold
    ld a, [$c8df]
    ld l, a
    ld a, [$c8e0]
    ld h, a
    ld a, [$c8e1]
    ld e, a
    call CompareGoldAndSub
    call CallFld9_53e9
    ld hl, $000d

jr_009_54f7:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetFld9_4204
    call LoadFld9_4f69
    call LoadFld9_40fa
    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
    cpl
    ld d, l
    ld h, b
    ld d, l
    ldh [rHDMA5], a
    ld e, [hl]
    ld d, [hl]
    ld l, [hl]
    ld d, [hl]
    db $dd
    ld d, [hl]
    cpl
    ld d, a
    ld e, e
    ld d, a
    ld a, h
    ld d, a
    ld hl, wBankSlots
    ld b, $28
    call FuncFld9_51f2
    ld a, c
    or a
    ld hl, $0011
    jr z, jr_009_5557

    ld hl, wInventory
    call CountFullInvSlots
    ld a, c
    cp $14
    ld hl, $0012
    jr nc, jr_009_5557

    ld hl, $c906
    inc [hl]
    ld hl, $0010
    call ScreenEffectSay
    ret


jr_009_5557:
    call ScreenEffectSay
    ld a, $08
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_5598
    call SetFld9_51e5
    call ShopDrawNames
    call CallFld9_5576
    ld hl, $c906
    inc [hl]
    ret


CallFld9_5576:
    call SetFld9_4204
    call SetFld9_5049
    ld de, $7153
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $5652
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    call LoadFld9_40fa
    ret


CallFld9_5598:
    call SetFld9_5aea
    ld hl, $d665
    ld bc, $0030
    xor a
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld bc, $0028
    xor a
    call FillNBytesWithRegA
    ld de, wBankSlots
    ld b, $28

jr_009_55b4:
    ld a, [de]
    or a
    jr z, jr_009_55ca

    cp $ff
    jr z, jr_009_55ca

    inc de
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc [hl]
    dec b
    jr nz, jr_009_55b4

jr_009_55ca:
    ld hl, $d666
    ld de, $c0d8
    ld b, $2f
    ld c, $01

jr_009_55d4:
    ld a, [hl+]
    or a
    jr z, jr_009_55db

    ld a, c
    ld [de], a
    inc de

jr_009_55db:
    inc c
    dec b
    jr nz, jr_009_55d4

    ret


    ld de, $5652
    ld hl, $c8e2
    ld a, [$c8e9]
    ld c, a
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    ld a, [hl]
    push af
    call LoadFld9_4256
    pop af
    ld hl, $c8e2
    and $7f
    ld b, a
    ld a, [hl]
    and $7f
    cp b
    jr z, jr_009_5601

jr_009_5601:
    pop af
    ld hl, $c8e3
    cp [hl]
    jr z, jr_009_560b

    call ShopDrawNames

jr_009_560b:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_563b

    ld a, $02
    ld [$c822], a
    ld a, $0c
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    call SetFld9_4204
    call SetFld9_5049
    call LoadFld9_40fa
    ld hl, $000e
    call ScreenEffectSay
    ld a, $04
    ld [$c905], a
    jr jr_009_5651

jr_009_563b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5651

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    ld a, $01
    ld [$c8de], a

Jump_009_5651:
jr_009_5651:
    ret


    ld [hl], d
    ld bc, $0089
    ret


    nop
    add hl, bc
    ld bc, HeaderRAMSize
    rst $38
    rst $38
    ld hl, $0013
    call ScreenEffectSay
    ld a, $01
    ld [$c8dd], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_567b
    ld hl, $c906
    inc [hl]
    ret


CallFld9_567b:
    call SetFld9_4204
    call SetFld9_5049
    ld de, $7153
    call LoadFld9_40c9
    ld de, $5652
    ld b, $04
    ld a, [$c8e9]
    ld c, a
    ld hl, $c8e2
    call ReadFld9_44ff
    ld de, $7044
    call LoadFld9_40c9
    ld hl, $c0d8
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$da5e], a
    ld hl, $d665
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $00
    ld hl, $0164
    call LoadFld9_406d
    call CopyHLtoDE
    call ClrFld9_442a
    ld de, $5729
    ld hl, $c8dd
    ld b, $02
    ld a, [hl]
    call FuncFld9_456d
    call LoadFld9_40fa
    ret


    ld de, $5729
    ld hl, $d665
    ld a, [$da5e]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld c, [hl]
    ld b, $02
    ld hl, $c8dd
    call FuncFld9_434a
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_5717

    call CallFld9_5576
    ld hl, $0010
    call ScreenEffectSay
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_5728

jr_009_5717:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5728

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_5728:
jr_009_5728:
    ret


    ld h, c
    ld bc, $0162
    rst $38
    rst $38
    ld hl, wInventory
    call CountFullInvSlots
    ld a, [$c8de]
    add c
    cp $15
    ld hl, $0014
    jr nc, jr_009_5753

    ld a, [$c8de]
    ld b, a

jr_009_5744:
    push bc
    call LoadFld9_5b40
    ld hl, $0306
    rst $10
    pop bc
    dec b
    jr nz, jr_009_5744

    ld hl, $0015

jr_009_5753:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, wPLAN_selection
    ld bc, $0006
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld a, $00
    ld [$c906], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    ret


    ld a, [$c906]
    rst $00
    sbc e
    ld d, a
    rst $08
    ld d, a
    inc l
    ld e, b
    adc [hl]
    ld e, b
    ld a, [c]
    ld e, b
    ld hl, $ca4e
    ld a, [hl+]
    or [hl]
    inc hl
    or [hl]
    jr nz, jr_009_57b0

    ld hl, $000f
    call ScreenEffectSay
    ld a, $04
    ld [$c906], a
    ret


jr_009_57b0:
    ld hl, $0016
    call ScreenEffectSay
    ld a, $02
    ld [wPLAN_selection], a
    ld a, $00
    ld [$c8df], a
    ld a, $00
    ld [$c8e0], a
    ld a, $00
    ld [$c8e1], a
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call CallFld9_57dc
    ld hl, $c906
    inc [hl]
    ret


CallFld9_57dc:
    call SetFld9_4204
    call SetFld9_5049
    ld a, $02
    ld [$c822], a
    ld a, $55
    ld [$c823], a
    ld hl, $8a00
    ld de, $0401
    call LoadFld9_412f
    ld de, $71ca
    call LoadFld9_40c9
    ld de, $71e7
    call LoadFld9_40c9
    ld a, [$ca4e]
    ldh [$d5], a
    ld a, [$ca4f]
    ldh [$d6], a
    ld a, [$ca50]
    ldh [$d7], a
    ld hl, $016d
    call LoadFld9_406d
    call CoordClampHigh
    call ClrFld9_442a
    ld de, $5882
    ld hl, wPLAN_selection
    ld b, $02
    ld a, [hl]
    call FuncFld9_5a67
    call LoadFld9_40fa
    ret


    ld de, $5882
    ld hl, wPLAN_selection
    ld b, $03
    call FuncFld9_590c
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_5867

    ld a, $02
    ld [$c822], a
    ld a, $0c
    ld [$c823], a
    ld hl, $8a40
    ld de, $0c01
    call LoadFld9_412f
    call SetFld9_4204
    call SetFld9_5049
    call LoadFld9_40fa
    ld hl, $000e
    call ScreenEffectSay
    ld a, $04
    ld [$c905], a
    jr jr_009_5881

jr_009_5867:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5881

    ld hl, $c8df
    ld a, [hl+]
    or [hl]
    inc hl
    or [hl]
    jr z, jr_009_5881

    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]

Jump_009_5881:
jr_009_5881:
    ret


    adc [hl]
    nop
    adc a
    nop
    sub b
    nop
    sub c
    nop
    sub d
    nop
    rst $38
    rst $38
    ld hl, $c8df
    ld a, [$ca4e]
    sub [hl]
    inc hl
    ld a, [$ca4f]
    sbc [hl]
    inc hl
    ld a, [$ca50]
    sbc [hl]
    ld hl, $0017
    jr c, jr_009_58ea

    ld hl, $c8df
    ld a, [wCurrGoldLo]
    add [hl]
    ld e, a
    inc hl
    ld a, [wCurrGoldMid]
    adc [hl]
    ld d, a
    inc hl
    ld a, [wCurrGoldHi]
    adc [hl]
    ld c, a
    ld a, e
    sub $a0
    ld a, d
    sbc $86
    ld a, c
    sbc $01
    ld hl, $0018
    jr nc, jr_009_58ea

    ld a, [$c8df]
    ld l, a
    ld a, [$c8e0]
    ld h, a
    ld a, [$c8e1]
    ld e, a
    call SubtractGold
    ld a, [$c8df]
    ld l, a
    ld a, [$c8e0]
    ld h, a
    ld a, [$c8e1]
    ld e, a
    call CompareGold
    call CallFld9_57dc
    ld hl, $0019

jr_009_58ea:
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetFld9_4204
    call LoadFld9_4f69
    call LoadFld9_40fa
    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c905], a
    ret


FuncFld9_590c:
    res 7, [hl]
    push de
    ld a, [wJoypad_Current]
    bit 7, a
    jr z, jr_009_5920

    ld a, $10
    ld [wCursorBlinkTimer], a
    call SaveFld9_5965
    jr jr_009_5954

jr_009_5920:
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_009_5931

    ld a, $10
    ld [wCursorBlinkTimer], a
    call SaveFld9_5a30
    jr jr_009_5954

jr_009_5931:
    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_009_5941

    ld a, [hl]
    dec a
    cp b
    jr c, jr_009_594f

    dec b
    ld a, b
    jr jr_009_594f

jr_009_5941:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_5956

    ld a, [hl]
    inc a
    cp b
    jr c, jr_009_594f

    ld a, $00

jr_009_594f:
    ld [hl], a
    xor a
    ld [wCursorBlinkTimer], a

jr_009_5954:
    push hl
    pop hl

jr_009_5956:
    ld a, [wJoypad_Current]
    bit 0, a
    jr z, jr_009_595f

    set 7, [hl]

jr_009_595f:
    pop de
    ld a, [hl]
    call FuncFld9_5a67
    ret


SaveFld9_5965:
    push de
    ld a, [hl]
    push hl
    ld a, [$c8df]
    ldh [$d5], a
    ld a, [$c8e0]
    ldh [$d6], a
    ld a, [$c8e1]
    ldh [$d7], a
    ld hl, wDebug_main_menu_option
    call InitNumberFormat
    pop hl
    ld a, [hl]
    ld de, wDebug_main_menu_option
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    and $0f
    dec a
    ld [de], a
    cp $ff
    jr nz, jr_009_5994

    ld a, $09
    ld [de], a

jr_009_5994:
    call SaveFld9_5999
    pop de
    ret


SaveFld9_5999:
    push hl
    ld bc, $2710
    ld a, [wDebug_main_menu_option]
    and $0f
    call Mul16x8To24
    ld a, l
    ld [$c8df], a
    ld a, h
    ld [$c8e0], a
    ld a, e
    ld [$c8e1], a
    ld bc, $03e8
    ld a, [$c0a1]
    and $0f
    call Mul16x8To24
    ld a, [$c8df]
    add l
    ld [$c8df], a
    ld a, [$c8e0]
    adc h
    ld [$c8e0], a
    ld a, [$c8e1]
    adc e
    ld [$c8e1], a
    ld bc, $0064
    ld a, [$c0a2]
    and $0f
    call Mul16x8To24
    ld a, [$c8df]
    add l
    ld [$c8df], a
    ld a, [$c8e0]
    adc h
    ld [$c8e0], a
    ld a, [$c8e1]
    adc e
    ld [$c8e1], a
    ld bc, $000a
    ld a, [$c0a3]
    and $0f
    call Mul16x8To24
    ld a, [$c8df]
    add l
    ld [$c8df], a
    ld a, [$c8e0]
    adc h
    ld [$c8e0], a
    ld a, [$c8e1]
    adc e
    ld [$c8e1], a
    ld a, [$c0a4]
    and $0f
    ld l, a
    ld a, [$c8df]
    add l
    ld [$c8df], a
    ld a, [$c8e0]
    adc $00
    ld [$c8e0], a
    ld a, [$c8e1]
    adc $00
    ld [$c8e1], a
    pop hl
    ret


SaveFld9_5a30:
    push de
    ld a, [hl]
    push hl
    ld a, [$c8df]
    ldh [$d5], a
    ld a, [$c8e0]
    ldh [$d6], a
    ld a, [$c8e1]
    ldh [$d7], a
    ld hl, wDebug_main_menu_option
    call InitNumberFormat
    pop hl
    ld de, $c0a1
    ld a, [hl]
    ld de, wDebug_main_menu_option
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    and $0f
    inc a
    ld [de], a
    cp $0a
    jr nz, jr_009_5a62

    ld a, $00
    ld [de], a

jr_009_5a62:
    call SaveFld9_5999
    pop de
    ret


FuncFld9_5a67:
    ld c, a
    push de
    push bc
    ld a, [$c8df]
    ldh [$d5], a
    ld a, [$c8e0]
    ldh [$d6], a
    ld a, [$c8e1]
    ldh [$d7], a
    ld hl, wDebug_main_menu_option
    call InitNumberFormat
    pop bc
    pop de
    bit 7, c
    jr nz, jr_009_5a95

    ld a, [wCursorBlinkTimer]
    and $0f
    push af
    ld a, [wCursorBlinkTimer]
    inc a
    ld [wCursorBlinkTimer], a
    pop af
    ld a, c
    ret nz

jr_009_5a95:
    ld c, a
    ld b, $00

jr_009_5a98:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_009_5ac2

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_009_5ac2

    ld a, $e6

jr_009_5ac2:
    cp $e0
    jr nz, jr_009_5ad3

    push hl
    ld a, b
    ld hl, wDebug_main_menu_option
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl

jr_009_5ad3:
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_009_5a98

SetFld9_5aea:
    ld hl, $d665
    ld de, wBankSlots
    ld b, $28

jr_009_5af2:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_009_5af2

    ld hl, wBankSlots
    ld bc, $0028
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $d665
    ld de, wBankSlots
    ld b, $28

jr_009_5b0b:
    ld a, [hl+]
    cp $ff
    jr z, jr_009_5b16

    cp $00
    jr z, jr_009_5b16

    ld [de], a
    inc de

jr_009_5b16:
    dec b
    jr nz, jr_009_5b0b

    ret


LoadFld9_5b1a:
    ld a, [$da5e]
    cp $00
    ret z

    cp $ff
    ret z

    ld hl, wBankSlots
    ld b, $28

jr_009_5b28:
    ld a, [hl]
    cp $00
    jr z, jr_009_5b3b

    cp $ff
    jr z, jr_009_5b3b

    inc hl
    dec b
    jr nz, jr_009_5b28

    ld a, $ff
    ld [$da5e], a
    ret


jr_009_5b3b:
    ld a, [$da5e]
    ld [hl], a
    ret


LoadFld9_5b40:
    ld a, [$da5e]
    cp $00
    ret z

    cp $ff
    ret z

    ld hl, wBankSlots
    ld b, $28

jr_009_5b4e:
    ld a, [$da5e]
    cp [hl]
    jr z, jr_009_5b5e

    inc hl
    dec b
    jr nz, jr_009_5b4e

    ld a, $ff
    ld [$da5e], a
    ret


jr_009_5b5e:
    ld [hl], $ff
    call SetFld9_5aea
    ret


; ---------------------------------------------------------------------------
; ArenaClassMenu ($09:$5B64, screen effect 4) — S109 annotation. The Arena
; Lobby class REGISTRATION menu: Arena Lobby script 6 `$04 $0004 $0710`
; ('Which class are you registering for?'). Two columns of four classes,
; each with its entry FEE (ArenaClassFeeTable) and a star when already won
; ($CAB4 = classes won). Choosing a class that is not won and paying its fee
; sets wArenaGroup = the class (0-7 = G..S); script 6 then runs opcode $1F
; ArenaBattleSetup (bank $04) and warps to the Arena Battle room ($5D).
; Editor: gamedata.arena.<class>.fee -> region gd_arena_fees (S109).
; ---------------------------------------------------------------------------
ArenaClassMenu:
    ld a, [$c905]
    rst $00
ArenaClassMenuOuterTable:
    dw ArenaClassMenu_S0Window
    dw ArenaClassMenu_S1
    dw ArenaClassMenu_S2Cursor
    dw ArenaClassMenu_S3Run
    dw ArenaClassMenu_S4Close
; outer state 0: menu window position from HRAM $B7/$BB -> $C909/$C90A,
; border tiles to VRAM $8800
ArenaClassMenu_S0Window:
    ld hl, $ffb7
    call ReadFld9_403d
    ld hl, $ffbb
    call ReadFld9_403d
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
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
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetFld9_4204
    ld de, MenuBorderFill
    ld hl, $8800
    call WaitDMATransfer
    ld hl, $c905
    inc [hl]
    ret


; outer state 1: one frame
ArenaClassMenu_S1:
    ld hl, $c905
    inc [hl]
    ret


; outer state 2: inner state := 0, cursor := the next class to win:
; $C8E2 (row) = [$CAB4] & 3, $C8E3 (column) = 1 when [$CAB4] >= 4
; ($CAB4 = arena progress tier = classes won, Arena Lobby scr0)
ArenaClassMenu_S2Cursor:
    ld hl, $c905
    inc [hl]
    xor a
    ld [$c906], a
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c8e2
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
    ld a, [$cab4]
    and $03
    ld [$c8e2], a
    ld a, [$cab4]
    cp $04
    ret c

    ld a, $01
    ld [$c8e3], a
    ret


; outer state 3: the inner machine runs until it advances $C905
ArenaClassMenu_S3Run:
    jp ArenaClassMenuRun


; outer state 4: restore the screen, clear wGameState bit 4 (screen effect
; done) and $C905 -> the script resumes
ArenaClassMenu_S4Close:
    call SetFld9_4204
    ld de, $2e07
    call LoadFld9_40c9
    call LoadFld9_40fa
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret


; ArenaClassMenuRun: the inner 9-state machine (state $C906), S109
ArenaClassMenuRun:
    ld a, [$c906]
    rst $00
ArenaClassMenuStateTable:          ; inner machine, state = $C906
    dw ArenaClassMenu_State0
    dw ArenaClassMenu_State1
    dw ArenaClassMenu_State2
    dw ArenaClassMenu_State3
    dw ArenaClassMenu_State4
    dw ArenaClassMenu_State5
    dw ArenaClassMenu_State6
    dw ArenaClassMenu_State7
    dw ArenaClassMenu_State8
; inner state 0: ArenaMenuMarkWon, next
ArenaClassMenu_State0:
    call ArenaMenuMarkWon
    ld hl, $c906
    inc [hl]
    ret


; ArenaMenuMarkWon: $C0D8[0..7] := $90 (selectable), then the first [$CAB4]
; classes := $AC (the star glyph = already won). $CAB4 = classes won.
; S128 (ROADMAP P3.14e3, your arena): ArenaMenuMarkWon fills the class menu marks $C0D8[0..7]
; ($90 open, $AC star = the first [$CAB4] won). patches/ moves the body to bank
; $6E ArenaMarkClasses (same bytes, + per-class locks in the project's lobby:
; $9C "-") and adds ArenaRefuse09 for the refusal below.
ArenaMenuMarkWon:
    ld hl, $c0d8
    ld bc, $0008
    ld a, $90
    call FillNBytesWithRegA
    ld a, [$cab4]
    or a
    ret z

    ld b, a
    ld hl, $c0d8

jr_009_5c3c:
    ld [hl], $ac
    inc hl
    dec b
    jr nz, jr_009_5c3c

    ret


; inner state 1 (after text): draw letters, fees, gold, cursor; next
ArenaClassMenu_State1:
    ld a, [$c825]
    or a
    ret nz

    call ArenaMenuDrawLetters
    call ArenaMenuDraw
    ld hl, $c906
    inc [hl]
    ret


; ArenaMenuDraw: the menu window, the fee column (ArenaMenuDrawFees), the
; player's gold, the cursor (ArenaMenuCursorTable).
ArenaMenuDraw:
    call SetFld9_4204
    ld de, $2e07
    call LoadFld9_40c9
    ld de, $74a0
    call LoadFld9_40c9
    ld de, $6f1f
    call LoadFld9_40c9
    call ArenaMenuDrawFees
    ld a, [wCurrGoldLo]
    ldh [$d5], a
    ld a, [wCurrGoldMid]
    ldh [$d6], a
    ld a, [wCurrGoldHi]
    ldh [$d7], a
    ld hl, $002e
    call LoadFld9_406d
    call ConvertNumberToText
    call ClrFld9_442a
    ld de, ArenaMenuCursorTable
    ld b, $04
    ld c, $04
    ld hl, $c8e2
    call ReadFld9_44ff
    call LoadFld9_40fa
    ret


; ArenaMenuDrawLetters: the four class letters of column [$C8E3]
; (ArenaClassLetterTable) to VRAM $8800 and their four won/selectable
; marks ($C0D8) to $8840.
ArenaMenuDrawLetters:
    ld de, ArenaClassLetterTable
    ld a, [$c8e3]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8800
    call ArenaMenuPutLetter
    call ArenaMenuPutLetter
    call ArenaMenuPutLetter
    call ArenaMenuPutLetter
    ld de, $c0d8
    ld a, [$c8e3]
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8840
    call ArenaMenuPutLetter
    call ArenaMenuPutLetter
    call ArenaMenuPutLetter

; ArenaMenuPutLetter: one glyph [DE] -> tile at HL; DE+1, HL+$10
ArenaMenuPutLetter:
    push de
    push hl
    ld a, [de]
    call FuncFld9_41b6
    pop hl
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


; ArenaMenuDrawFees: the four fees of column [$C8E3] (ArenaClassFeeTable,
; 4 words per column) as numbers, one text row ($40) apart from $00AB.
ArenaMenuDrawFees:
    ld de, ArenaClassFeeTable
    ld a, [$c8e3]
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $00ab
    call ArenaMenuPutFee
    call ArenaMenuPutFee
    call ArenaMenuPutFee

; ArenaMenuPutFee: the 16-bit fee [DE] -> number text at HL; DE+2, HL+$40
ArenaMenuPutFee:
    push de
    push hl
    ld a, [de]
    ldh [$d5], a
    inc de
    ld a, [de]
    ldh [$d6], a
    ld a, $00
    ldh [$d7], a
    call LoadFld9_406d
    call ConvertNumberToText
    pop hl
    ld a, l
    add $40
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    inc de
    ret


; ArenaClassLetterTable ($09:$5D1B) — the class letter glyphs G F E D C B A S
; (font: $24 = A); index 4*column + row. Read by ArenaMenuDrawLetters and
; state 3 (the '<class> class?' prompt).
ArenaClassLetterTable:
    db $2a, $29, $28, $27, $26, $25, $24, $36   ; G F E D C B A S
; ArenaClassFeeTable ($09:$5D23) — the ENTRY FEE of each class in gold, one
; word per class G..S (index 4*column + row). Read by ArenaMenuDrawFees
; (display), state 3 (gold >= fee?) and state 5 (AddGold). 16-bit: a fee
; is 0-65535. Editor: gamedata.arena.<class>.fee (region gd_arena_fees, S109).
ArenaClassFeeTable:
    dw     0   ; G class
    dw    10   ; F class
    dw    50   ; E class
    dw   100   ; D class
    dw   500   ; C class
    dw  1000   ; B class
    dw  5000   ; A class
    dw 10000   ; S class
; inner state 2 = the class SELECTION: cursor over 2 columns x 4 rows
; (column $C8E3: G F E D | C B A S; row $C8E2). A on a class whose
; ArenaMenuMarkWon byte is $90 (not won yet) -> state 3; on a won class
; ($AC, the star) -> menu message 6 and state 8. B -> wColiseumBattle := $FF
; (the lobby script's 'Better luck next time' path) and leave.
ArenaClassMenu_State2:
    ld de, ArenaMenuCursorTable + 2
    ld hl, $c8e2
    ld b, $04
    inc hl
    ld a, [hl-]
    push af
    call FuncFld9_42f1
    pop af
    ld hl, $c8e3
    cp [hl]

jr_009_5d46:
    jr z, jr_009_5d51

    call ArenaMenuDrawLetters
    call ArenaMenuDrawFees
    call LoadFld9_40fa

jr_009_5d51:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5d90

    ld hl, $c0d8
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $90
    jp z, Jump_009_5d81

    ld hl, $0006
    ; S128 (ROADMAP P3.14e3, your arena): State2 accepts only $90; any other mark says line +6
    ; ($0716). patches/ -> call ArenaRefuse09 (a locked class: the project's
    ; words, ARENA_LOCKED_OFS).
    call ScreenEffectSay
    ld a, $08
    ld [$c906], a
    jr jr_009_5da1

Jump_009_5d81:
    ld a, $59
    call PlaySoundEffect
    ld hl, $c906
    inc [hl]
    xor a
    ld [$c8de], a
    jr jr_009_5da1

Jump_009_5d90:
    ld a, [wJoypad_current_frame]
    bit 1, a
    jp z, Jump_009_5da1

    ld a, $ff
    ld [wColiseumBattle], a
    ld hl, $c905
    inc [hl]

Jump_009_5da1:
jr_009_5da1:
    ret


; ArenaMenuCursorTable ($09:$5DA2) — the class cursor: ArenaMenuDraw passes
; $5DA2 to ReadFld9_44ff (B = C = 4), state 2 passes $5DA4 (the four row
; words, $FFFF-ended) to FuncFld9_42f1 (B = 4).
ArenaMenuCursorTable:
    dw $018C, $00A2, $00E2, $0122, $0162, $FFFF
; inner state 3 = the GOLD CHECK: gold (24-bit $CA4B-$CA4D) minus
; ArenaClassFeeTable[4*col + row] (16-bit). Short -> menu message 5 and
; state 8; else $C180 = the class letter (+$F0 end) for message 4
; ('<class> class?') and state 4.
ArenaClassMenu_State3:
    ld hl, ArenaClassFeeTable
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wCurrGoldLo]
    sub [hl]
    inc hl
    ld a, [wCurrGoldMid]
    sbc [hl]
    inc hl
    ld a, [wCurrGoldHi]
    sbc $00
    jr nc, jr_009_5de1

    ld hl, $0005
    call ScreenEffectSay
    ld a, $08
    ld [$c906], a
    ret


jr_009_5de1:
    ld de, ArenaClassLetterTable
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [$c180], a
    ld a, $f0
    ld [$c181], a
    ld hl, $0004
    call ScreenEffectSay
    ld hl, $c906
    inc [hl]
    ret


; inner state 4: draw the YES/NO box (cursor $C8DE = YES)
ArenaClassMenu_State4:
    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld de, $6ed5
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, ArenaYesNoCursorTable
    ld a, [$c8de]
    call FuncFld9_4530
    call LoadFld9_40fa
    ld hl, $c906
    inc [hl]
    ret


; inner state 5 = YES/NO. B or NO ($C8DE = $81) -> redraw, message 1, back
; to state 2. YES -> `call AddGold` with HL = the fee, E = 0: despite its
; name the ROM0 routine SUBTRACTS (CompareGoldHL: gold - C:D:E, floor 0;
; PyBoy S109: 3800 -> 3750 for E class), then wArenaGroup := 4*col + row
; (the class 0-7 = G..S), next.
ArenaClassMenu_State5:
    ld de, ArenaYesNoCursorTable
    ld hl, $c8de
    ld b, $02
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_5e5b

jr_009_5e40:
    call ArenaMenuDraw
    ld hl, $0001
    call ScreenEffectSay
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    ld hl, $c906
    dec [hl]
    jr jr_009_5ea0

jr_009_5e5b:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_5ea0

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_009_5e40

    ld hl, ArenaClassFeeTable
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld e, $00
    call AddGold
    ld a, [$c8e3]
    add a
    add a
    ld b, a
    ld a, [$c8e2]
    and $7f
    add b
    ld [wArenaGroup], a
    ld hl, $c906
    inc [hl]

Jump_009_5ea0:
jr_009_5ea0:
    ret


; ArenaYesNoCursorTable ($09:$5EA1) — the YES/NO cursor (state 4 FuncFld9_4530,
; state 5 FuncFld9_42f1 with B = 2).
ArenaYesNoCursorTable:
    dw $012F, $016F, $FFFF
; inner state 6: next
ArenaClassMenu_State6:
    ld hl, $c906
    inc [hl]
    ret


; inner state 7 (after text): outer state 4 = close
ArenaClassMenu_State7:
    ld a, [$c825]
    or a
    ret nz

    ld hl, $c905
    inc [hl]
    ret


; inner state 8 (after the message of a refused choice): redraw,
; message 1, back to state 1
ArenaClassMenu_State8:
    ld a, [$c825]
    or a
    ret nz

    call ArenaMenuDraw
    ld hl, $0001
    call ScreenEffectSay
    ld a, $01
    ld [$c906], a
    ret


; GateListScreen: screen effect type 13 — the list of Travelers' Gates (a full screen: the gate names are a bitmap in the room's tile slots $38-$7F); S126 annotation
GateListScreen:
    ld a, [$c905]
    rst $00
    sub $5e
    inc h
    ld e, a
    xor [hl]
    ld h, b
    ld a, [$2160]
    or a
    rst $38
    call ReadFld9_403d
    ld hl, $ffbb
    call ReadFld9_403d
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
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
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    call SetFld9_4236
    call LoadFld9_40fa
    call ClrFld9_442a
    ld a, $01
    ld [$c8ec], a
    xor a
    ld [$df0d], a
    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    call SetFld9_4236
    call SetFld9_604d
    call SetFld9_5f4d
    call SetFld9_5f38
    call LoadFld9_40fa
    ret


SetFld9_5f38:
    ld de, $6cde
    call LoadFld9_40c9
    ld a, [$c8e9]
    cp $09
    ret c

    ld hl, $0212
    call LoadFld9_406d
    ld [hl], $e7
    ret


SetFld9_5f4d:
    ld de, $c0d8
    ld a, [wOPTN_and_Item_selection]
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $9380
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    call SaveFld9_5fa2
    ld de, $c0d8
    ld a, [wOPTN_and_Item_selection]
    add a
    add a
    add a
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld hl, $8880
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    call SaveFld9_6004
    ret


SaveFld9_5fa2:
    push de
    push hl
    ld a, [de]
    cp $ff
    jr nz, jr_009_5fc5

    ld a, $6f
    ld [$c823], a
    ld a, $02
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    call LoadFld9_412f
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


jr_009_5fc5:
    push hl
    ld hl, $5fe4
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld e, a
    ld a, [hl]
    ld d, a
    pop hl
    call WaitDMATransfer
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


    rrca
    ld d, [hl]
    db $10
    ld d, [hl]
    ld de, $1256
    ld d, [hl]
    inc de
    ld d, [hl]
    inc d
    ld d, [hl]
    dec d
    ld d, [hl]
    ld d, $56
    rla
    ld d, [hl]
    jr @+$58

    add hl, de
    ld d, [hl]
    ld a, [de]
    ld d, [hl]
    dec de
    ld d, [hl]
    inc e
    ld d, [hl]
    dec e
    ld d, [hl]
    ld e, $56

SaveFld9_6004:
    push de
    push hl
    ld a, [de]
    cp $ff
    ld a, $e0
    jr z, jr_009_6033

    ld a, [de]
    push de
    ld de, GateListClearedFlags         ; S124: [gate] -> its cleared flag
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    push bc
    ld a, [de]
    ld c, a
    ld b, $00
    push hl
    call TestEventFlag
    pop hl
    pop bc
    pop de
    ld a, $e0
    jr z, jr_009_6033

    ld a, [de]
    ld de, GateListClearedByte          ; S124: [gate] -> drawn for a cleared gate
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]

jr_009_6033:
    ld [$c823], a
    ld a, $05
    ld [$c822], a
    ld de, WaitSTATForOverlayB
    call LoadFld9_412f
    pop hl
    ld a, l
    add $90
    ld l, a
    ld a, h
    adc $00
    ld h, a
    pop de
    inc de
    ret


SetFld9_604d:
    ; S124: the gate list = every gate 0-15 whose GateListUnlockFlags flag is SET
    ; ([$C0D8..] = gate numbers, [$C8E9] = how many)
    ld hl, $c0d8
    ld bc, $0010
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $c0d8
    ld de, GateListUnlockFlags          ; S124: [gate] -> the flag that lists it
    ld b, $00

jr_009_6060:
    push bc
    push de
    push hl
    ld a, [de]
    ld c, a
    ld b, $00
    call TestEventFlag
    pop hl
    pop de
    pop bc
    jr z, jr_009_6072

    ld [hl], b
    inc hl
    inc c

jr_009_6072:
    inc de
    inc b
    ld a, b
    cp $10
    jr nz, jr_009_6060

    ld a, c
    ld [$c8e9], a
    ret


; =============================================================================
; S124 (ROADMAP P3.14a): the gate keeper's gate list (screen 13, open_screen 13 —
; the Gate Hub guide). Three 16-byte tables, one byte per gate 0-15 (the 16 main
; gates in list order). Re-sectioned from mgbdis fake code (byte-perfect; ROM bytes
; $09:$607E-$60AD); EVENT_FLAGS "Engine-side flag setters and readers".
; =============================================================================
GateListClearedFlags:   ; $607E — the gate's CLEARED flag (low byte, flags $00xx):
                        ; SaveFld9_6004 tests it (TestEventFlag) for each listed gate
    db $10, $11, $12, $13, $14, $16, $17, $19, $1D, $1C, $1A, $1F, $20, $22, $23, $25
GateListClearedByte:    ; $608E — the byte SaveFld9_6004 draws ([$C823], $C822 = 5) for
                        ; a CLEARED gate ($E0 otherwise); its meaning is not traced (S124)
    db $09, $1C, $C4, $44, $66, $0A, $45, $C5, $2A, $58, $2B, $99, $AD, $43, $94, $9A
GateListUnlockFlags:    ; $609E — the flag that puts gate n on the list (SetFld9_604d:
                        ; TestEventFlag, set -> listed; $0000 = set by the bedroom intro):
                        ; Beginning; then 2 gates per arena class won G..A ($0030-$0036),
                        ; Reflection on class S ($0037) — the arena ranks open the gates
    db $00, $30, $30, $31, $31, $32, $32, $33, $33, $34, $34, $35, $35, $36, $36, $37

jr_009_60ae:
    ld de, $60f2
    ld hl, wMenu_selection
    ld c, $01
    ld a, [$c8e9]
    cp $09
    jr c, jr_009_60bf

    ld c, $02

jr_009_60bf:
    ld b, $01
    ld a, [wOPTN_and_Item_selection]
    push af
    call LoadFld9_4256
    pop af
    ld hl, wOPTN_and_Item_selection
    cp [hl]
    jr z, jr_009_60d2

    call SetFld9_5f4d

jr_009_60d2:
    ld a, [wJoypad_current_frame]
    and $0a
    jr z, jr_009_60df

    ld hl, $c905
    inc [hl]
    jr jr_009_60f1

jr_009_60df:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jr z, jr_009_60f1

    ld a, $59
    call PlaySoundEffect
    ld hl, $c905
    inc [hl]
    jr jr_009_60f1

jr_009_60f1:
    ret


    ld [de], a
    ld [bc], a
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    call SetFld9_4236
    call LoadFld9_40fa
    ld hl, $0b01
    rst $10
    ld hl, $0b02
    rst $10
    call UpdateOAMSprites
    call GetBGMapAddress
    ld hl, $0604
    rst $10
    xor a
    ld [$c8ec], a
    ld hl, wGameState
    res 4, [hl]
    xor a
    ld [$c905], a
    ret

label9_6120:
    ld a, [$c905]
    cp $09
    jr nc, jr_009_6155

    cp $02
    jr c, jr_009_6155

    ld hl, $ffc3
    ld a, $19
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, $21
    ld [hl+], a
    ld a, $00
    ld [hl+], a
    ld a, [$c8f4]
    ld [hl+], a
    ld b, $00
    ld a, [$c8a4]
    bit 4, a
    jr z, jr_009_6149

    ld b, $01

jr_009_6149:
    ld a, b
    ld [hl+], a
    ld a, $50
    ld [hl+], a
    ld a, $00
    ld [hl], a
    ld hl, $0403
    rst $10

jr_009_6155:
    ld a, [$c905]
    rst $00

    db $74, $61, $7d, $61, $6a, $62, $fc, $62, $b3, $66

    db $ed
    ld h, [hl]

    db $02, $67, $6b, $67, $8f, $67, $6f, $61, $dd, $67

    ld hl, $c905
    inc [hl]
    ret


    ld hl, $c905
    inc [hl]
    ld a, [$c850]
    or a
    ret z

    ld hl, $ffb7
    call ReadFld9_403d
    ld hl, $ffbb
    call ReadFld9_403d
    ld hl, $c0c8
    ld bc, $0010
    ld a, $9f
    call FillNBytesWithRegA
    call FuncFld9_621f
    ld hl, wMenu_selection
    ld bc, $0008
    ld a, $00
    call FillNBytesWithRegA
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
    ld [$c909], a
    ld a, h
    ld [$c90a], a
    ld hl, $01c0
    call LoadFld9_4059
    call SaveFld9_404a
    ld a, l
    ld [$c83e], a
    ld a, h
    ld [$c83f], a
    call SetFld9_4236
    call LoadFld9_40fa
    ld de, $2e1e
    ld hl, $9000
    call WaitDMATransfer
    ld de, $2e1f
    ld hl, $8800
    call WaitDMATransfer
    ld de, $2e20
    ld hl, $8a00
    call WaitDMATransfer
    ld a, [$c8f4]        ; index = species+$10
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add LOW(FieldPtrLookupTable)   ; [4/8] follower gfx-ID copy ($6b10; label is mgbdis-
    ld l, a                        ;   misleading). Repoint all 8 on a swap; new species
    ld a, h                        ;   id>=224 overshoots it.
    adc HIGH(FieldPtrLookupTable)
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld hl, $8500
    call WaitDMATransfer
    call ClrFld9_442a
    call SetFld9_625d
    ld hl, $1702
    rst $10
    ld hl, $1708
    rst $10
    ld hl, $c905
    inc [hl]
    ret


; Naming screen setup (S108; measured on a JOIN in PyBoy: the field shows "SL" + two
; blank slots for a Slime): copy the 8-byte current name ($C8F2/$C8F3 -> $C0C8);
; if $C8F4 != 0 (a monster is being named) and that name is blank ($9F), PRE-FILL
; it with the species' default nickname = text mode 7 (bank $41 MonsterNickPtrTable
; $4739, id [$C8F5]) via $C180. The editor writes those strings:
; gamedata.monster_text.<id>.nickname (S108, PROJECT_COMPILER §2.24).
FuncFld9_621f:
    ld b, $08
    ld a, [$c8f2]
    ld l, a
    ld a, [$c8f3]
    ld h, a
    ld de, $c0c8
    call ReadFld9_624d
    ld a, [$c8f4]
    cp $00
    ret z

    ld a, [$c0c8]
    cp $9f
    ret nz

    ld a, [$c8f5]
    ld l, a
    ld h, $07
    ld de, $c180
    call SetupVRAMParams
    ld hl, $c180
    ld de, $c0c8

ReadFld9_624d:
jr_009_624d:
    ld a, [hl+]
    cp $00
    ret z

    cp $f0
    ret z

    cp $9f
    ret z

    ld [de], a
    inc de
    dec b
    jr nz, jr_009_624d

    ret


SetFld9_625d:
    ld de, $c0c8
    ld hl, $9000
    call SaveFld9_4168
    call CallFld9_6ac8
    ret


    ld hl, $c905
    inc [hl]
    call SetFld9_4236
    call LoadFld9_627b
    call CallFld9_6ac8
    call LoadFld9_40fa
    ret


LoadFld9_627b:
    ld a, [$c8f4]
    or a
    jr z, jr_009_62e0

    ld a, [$c8f6]
    and $01
    add $a7
    ld [$c180], a
    ld a, $f0
    ld [$c181], a
    ld a, [$c827]
    ld c, a
    ld a, [$c828]
    ld b, a
    push bc
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    push bc
    ld hl, $8af0
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld de, $0101
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld a, $02
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4102
    rst $10
    pop de
    pop hl
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $0064
    call LoadFld9_406d
    ld [hl], $af

jr_009_62e0:
    ld de, $7ca5
    call LoadFld9_40c9
    ld de, $7ccb
    ld a, [wPLAN_selection]
    or a
    jr nz, jr_009_62f2

    ld de, $7dc9

jr_009_62f2:
    call LoadFld9_40c9
    call ClrFld9_442a
    call LoadFld9_69f6
    ret


    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_009_6332

    ld a, [wOPTN_and_Item_selection]
    cp $03
    jr c, jr_009_631e

    ld a, [wMenu_selection]
    dec a
    ld [wMenu_selection], a
    cp $11
    jp c, Jump_009_63f5

    ld a, $0d
    ld [wMenu_selection], a
    jp Jump_009_63f5


jr_009_631e:
    ld a, [wMenu_selection]
    dec a
    ld [wMenu_selection], a
    cp $11
    jp c, Jump_009_63f5

    ld a, $10
    ld [wMenu_selection], a
    jp Jump_009_63f5


jr_009_6332:
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_634d

    ld a, [wMenu_selection]
    inc a
    ld [wMenu_selection], a
    cp $11
    jp c, Jump_009_63f5

    ld a, $00
    ld [wMenu_selection], a
    jp Jump_009_63f5


jr_009_634d:
    ld a, [wJoypad_Current]
    bit 6, a
    jr z, jr_009_639d

    ld a, [wMenu_selection]
    cp $06
    jr c, jr_009_638b

    cp $0d
    jp nc, Jump_009_6374

    ld a, [wOPTN_and_Item_selection]
    dec a
    ld [wOPTN_and_Item_selection], a
    cp $05
    jp c, Jump_009_63f5

    ld a, $03
    ld [wOPTN_and_Item_selection], a
    jp Jump_009_63f5


Jump_009_6374:
    ld a, [wOPTN_and_Item_selection]
    dec a
    ld [wOPTN_and_Item_selection], a
    cp $05
    jr c, jr_009_63f5

    ld a, $04
    ld [wOPTN_and_Item_selection], a
    ld a, $0d
    ld [wMenu_selection], a
    jr jr_009_63f5

jr_009_638b:
    ld a, [wOPTN_and_Item_selection]
    dec a
    ld [wOPTN_and_Item_selection], a
    cp $05
    jr c, jr_009_63f5

    ld a, $04
    ld [wOPTN_and_Item_selection], a
    jr jr_009_63f5

jr_009_639d:
    ld a, [wJoypad_Current]
    bit 7, a
    jp z, Jump_009_6460

    ld a, [wMenu_selection]
    cp $06
    jr c, jr_009_63e3

    cp $0d
    jr nc, jr_009_63c2

    ld a, [wOPTN_and_Item_selection]
    inc a
    ld [wOPTN_and_Item_selection], a
    cp $04
    jr c, jr_009_63f5

    ld a, $00
    ld [wOPTN_and_Item_selection], a
    jr jr_009_63f5

jr_009_63c2:
    ld a, [wOPTN_and_Item_selection]
    cp $02
    jr c, jr_009_63e3

    ld a, [wMenu_selection]
    ld a, $0d
    ld [wMenu_selection], a
    ld a, [wOPTN_and_Item_selection]
    inc a
    ld [wOPTN_and_Item_selection], a
    cp $05
    jr c, jr_009_63f5

    ld a, $00
    ld [wOPTN_and_Item_selection], a
    jr jr_009_63f5

jr_009_63e3:
    ld a, [wOPTN_and_Item_selection]
    inc a
    ld [wOPTN_and_Item_selection], a
    cp $05
    jr c, jr_009_63f5

    ld a, $00
    ld [wOPTN_and_Item_selection], a
    jr jr_009_63f5

Jump_009_63f5:
jr_009_63f5:
    xor a
    ld [wCursorBlinkTimer], a
    ld a, [wOPTN_and_Item_selection]
    ld c, $11
    call Mul8x8To16
    ld a, [wMenu_selection]
    add l
    cp $4a
    jr nz, jr_009_641c

    ld a, $06
    ld [wMenu_selection], a
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_6460

    ld a, $0d
    ld [wMenu_selection], a
    jr jr_009_6460

jr_009_641c:
    cp $50
    jr nz, jr_009_6433

    ld a, $0d
    ld [wMenu_selection], a
    ld a, [wJoypad_Current]
    bit 5, a
    jr z, jr_009_6460

    ld a, $05
    ld [wMenu_selection], a
    jr jr_009_6460

jr_009_6433:
    cp $41
    jr z, jr_009_644d

    cp $42
    jr z, jr_009_644d

    cp $43
    jr z, jr_009_644d

    cp $52
    jr z, jr_009_644d

    cp $53
    jr z, jr_009_644d

    cp $54
    jr z, jr_009_644d

    jr jr_009_6460

jr_009_644d:
    ld a, $0a
    ld [wMenu_selection], a
    ld a, [wJoypad_Current]
    bit 4, a
    jr z, jr_009_6460

    ld a, $00
    ld [wMenu_selection], a
    jr jr_009_6460

Jump_009_6460:
jr_009_6460:
    call LoadFld9_69f6
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_64a9

Jump_009_646a:
    ld de, $c0c8
    ld a, [de]
    cp $9f
    jp z, Jump_009_6606

jr_009_6473:
    inc de
    ld a, [de]
    cp $9f
    jr nz, jr_009_6473

    dec de
    ld a, [$df0e]
    cp $00
    jp nz, Jump_009_64a0

    ld a, [$c8f4]
    cp $00
    jp nz, Jump_009_64a0

    ld a, $01
    ld [$df0e], a
    ld a, $9f
    ld [$c0c8], a
    ld [$c0c9], a
    ld [$c0ca], a
    ld [$c0cb], a
    jp Jump_009_64a3


Jump_009_64a0:
    ld a, $9f
    ld [de], a

Jump_009_64a3:
    call SetFld9_625d
    jp Jump_009_6606


jr_009_64a9:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_65f3

    ld a, [wOPTN_and_Item_selection]
    ld c, $11
    call Mul8x8To16
    ld a, [wMenu_selection]
    add l
    cp $51
    jr nz, jr_009_64c8

    ld hl, $c905
    inc [hl]
    jp Jump_009_6606


jr_009_64c8:
    cp $40
    jp z, Jump_009_646a

    cp $1e
    jr nz, jr_009_64d6

    ld a, $0d
    ld [hl], a
    jr jr_009_6525

jr_009_64d6:
    cp $1f
    jr nz, jr_009_64df

    ld a, $0e
    ld [hl], a
    jr jr_009_6525

jr_009_64df:
    cp $20
    jr nz, jr_009_64e8

    ld a, $0f
    ld [hl], a
    jr jr_009_6525

jr_009_64e8:
    cp $21
    jr nz, jr_009_64f1

    ld a, $10
    ld [hl], a
    jr jr_009_6525

jr_009_64f1:
    cp $2f
    jr nz, jr_009_64fa

    ld a, $1e
    ld [hl], a
    jr jr_009_6525

jr_009_64fa:
    cp $30
    jr nz, jr_009_6503

    ld a, $1f
    ld [hl], a
    jr jr_009_6525

jr_009_6503:
    cp $0d
    jr nz, jr_009_650c

    ld a, $20
    ld [hl], a
    jr jr_009_6525

jr_009_650c:
    cp $0e
    jr nz, jr_009_6515

    ld a, $21
    ld [hl], a
    jr jr_009_6525

jr_009_6515:
    cp $0f
    jr nz, jr_009_651e

    ld a, $2f
    ld [hl], a
    jr jr_009_6525

jr_009_651e:
    cp $10
    jr nz, jr_009_6525

    ld a, $30
    ld [hl], a

jr_009_6525:
    ld hl, $6607
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    add $e0
    ld l, a
    ld a, h
    adc $c4
    ld h, a
    push hl
    call SetFld9_6aad
    pop hl
    ld a, c
    cp $04
    jr nz, jr_009_655a

    ld a, $0d
    ld [wMenu_selection], a
    ld a, $04
    ld [wOPTN_and_Item_selection], a
    ld a, [hl]
    cp $8d
    jr z, jr_009_6568

    cp $8e
    jr z, jr_009_6568

    jp Jump_009_6606


jr_009_655a:
    or a
    jr nz, jr_009_6568

    ld a, [hl]
    cp $8d
    jp z, Jump_009_6606

    cp $8e
    jp z, Jump_009_6606

jr_009_6568:
    ld de, $c0c8

jr_009_656b:
    ld a, [de]
    inc de
    cp $9f
    jr nz, jr_009_656b

    dec de
    ld a, [hl]
    cp $8d
    jr z, jr_009_657b

    cp $8e
    jr nz, jr_009_65b2

jr_009_657b:
    dec de
    ld a, [de]
    inc de
    cp $8d
    jp z, Jump_009_6606

    cp $8e
    jr z, jr_009_6606

    push hl
    ld a, c
    ld hl, $c0d2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld b, [hl]
    pop hl
    ld a, b
    cp $01
    jr z, jr_009_65b2

    ld a, [hl]
    cp $8e
    jr z, jr_009_6606

    ld a, b
    cp $03
    jr z, jr_009_65b2

    cp $06
    jr z, jr_009_65b2

    cp $09
    jr z, jr_009_65b2

    dec de
    ld a, [de]
    inc de
    cp $5a
    jr nz, jr_009_6606

jr_009_65b2:
    ld a, [hl]
    ld [de], a
    call SetFld9_625d
    ld a, $59
    call PlaySoundEffect
    call SetFld9_6aad
    ld a, c
    ld hl, $c0d2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    push hl
    ld a, [wOPTN_and_Item_selection]
    ld c, $11
    call Mul8x8To16
    ld a, [wMenu_selection]
    add l
    ld b, a
    ld a, $05
    call Div8x8
    ld a, b
    pop hl
    ld [hl], a
    call SetFld9_6aad
    ld a, c
    cp $04
    jr nz, jr_009_6606

    ld a, $0d
    ld [wMenu_selection], a
    ld a, $04
    ld [wOPTN_and_Item_selection], a
    jr jr_009_6606

Jump_009_65f3:
    ld a, [wJoypad_current_frame]
    bit 3, a
    jr z, jr_009_6606

    ld a, $0d
    ld [wMenu_selection], a
    ld a, $04
    ld [wOPTN_and_Item_selection], a
    jr jr_009_6606

Jump_009_6606:
jr_009_6606:
    ret


    db $e1, $00, $e2, $00, $e3, $00, $e4, $00, $e5, $00, $e6, $00, $e7, $00, $e8, $00
    db $e9, $00, $ea, $00, $eb, $00, $ec, $00, $ed, $00, $ef, $00, $f0, $00, $f1, $00
    db $f2, $00, $21, $01, $22, $01, $23, $01, $24, $01, $25, $01, $26, $01, $27, $01
    db $28, $01, $29, $01, $2a, $01, $2b, $01, $2c, $01, $2d, $01, $2f, $01, $30, $01
    db $31, $01, $32, $01, $61, $01, $62, $01, $63, $01, $64, $01, $65, $01, $66, $01
    db $67, $01, $68, $01, $69, $01, $6a, $01, $6b, $01, $6c, $01, $6d, $01, $6f, $01
    db $70, $01, $71, $01, $72, $01, $a1, $01, $a2, $01, $a3, $01, $a4, $01, $a5, $01
    db $a6, $01, $a7, $01, $a8, $01, $a9, $01, $aa, $01, $ab, $01, $ac, $01, $ad, $01
    db $af, $01, $b0, $01, $b1, $01, $b2, $01, $e1, $01, $e2, $01, $e3, $01, $e4, $01
    db $e5, $01, $e6, $01, $e7, $01, $e8, $01, $e9, $01, $ea, $01, $eb, $01, $ec, $01
    db $ed, $01, $ef, $01, $f0, $01, $f1, $01, $f2, $01, $ff, $ff


    xor a
    ld [wCursorBlinkTimer], a
    call LoadFld9_69f6
    ld a, [$c0c8]
    cp $9f
    jr nz, jr_009_66ca

    call LoadFld9_688e          ; name still blank at END -> a random family name (text mode 3, below)
    call SetFld9_68d9
    call SetFld9_625d

jr_009_66ca:
    call SetFld9_68ef
    jr c, jr_009_66d9

    ld hl, $c905
    inc [hl]
    ld hl, $c905
    inc [hl]
    jr jr_009_66ec

jr_009_66d9:
    ld hl, $020a
    call SetupTilemapTransfer
    ld de, $2e07
    call LoadFld9_40c9
    call LoadFld9_40fa
    ld hl, $c905
    inc [hl]

jr_009_66ec:
    ret


    ld a, [$c825]
    or a
    ret nz

    call SetFld9_625d
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ret


    ld a, [$c8f4]
    cp $00
    jr z, jr_009_6728

    ld a, [$c8f5]
    ld l, a
    ld h, $05
    ld de, $c190
    call SetupVRAMParams
    ld hl, $c190

jr_009_6718:
    ld a, [hl+]
    cp $f0
    jr nz, jr_009_6718

    dec hl
    ld a, [$c8f6]
    and $01
    add $a7
    ld [hl+], a
    ld [hl], $f0

jr_009_6728:
    ld hl, $c180
    ld de, $c0c8
    ld b, $08

jr_009_6730:
    ld a, [de]
    cp $9f
    jr z, jr_009_673a

    ld [hl+], a
    inc de
    dec b
    jr nz, jr_009_6730

jr_009_673a:
    ld a, $00
    ld [$df0e], a
    ld [hl], $f0
    ld hl, $0209
    ld a, [$c8f4]
    cp $00
    jr z, jr_009_6756

    call FuncFld9_692a
    ld hl, $0245
    jr c, jr_009_6756

    ld hl, $020f

jr_009_6756:
    call SetupTilemapTransfer
    ld de, $2e07
    call LoadFld9_40c9
    call LoadFld9_40fa
    ld hl, $c905
    inc [hl]
    xor a
    ld [$c8de], a
    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, $5c
    call PlaySoundEffect
    ld de, $6eb0
    call LoadFld9_40c9
    call ClrFld9_442a
    ld de, $67d7
    ld a, [$c8de]
    call FuncFld9_4530
    call LoadFld9_40fa
    ld hl, $c905
    inc [hl]
    ret


    ld de, $67d7
    ld hl, $c8de
    ld b, $02
    call FuncFld9_42f1
    ld a, [wJoypad_current_frame]
    bit 1, a
    jr z, jr_009_67be

jr_009_67a1:
    call SetFld9_625d
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    ld hl, $c905
    dec [hl]
    jr jr_009_67d6

jr_009_67be:
    ld a, [wJoypad_current_frame]
    bit 0, a
    jp z, Jump_009_67d6

    ld a, $59
    call PlaySoundEffect
    ld a, [$c8de]
    cp $81
    jr z, jr_009_67a1

    ld hl, $c905
    inc [hl]

Jump_009_67d6:
jr_009_67d6:
    ret


    db $2f, $01, $6f, $01, $ff, $ff

    ld a, [$c8f2]
    ld l, a
    ld a, [$c8f3]
    ld h, a
    ld bc, $0008
    ld a, $f0
    call FillNBytesWithRegA
    ld a, [$c8f2]
    ld l, a
    ld a, [$c8f3]
    ld h, a
    ld de, $c0c8
    ld b, $08

jr_009_67fa:
    ld a, [de]
    cp $9f
    jr z, jr_009_6804

    ld [hl+], a
    inc de
    dec b
    jr nz, jr_009_67fa

jr_009_6804:
    ld hl, wGameState
    bit 7, [hl]
    jr nz, jr_009_6812

    ld a, [$c8ef]
    cp $ff
    jr z, jr_009_687a

jr_009_6812:
    call SetFld9_4236
    call LoadFld9_40fa
    ld hl, $0b01
    rst $10
    ld hl, $0b02
    rst $10
    call UpdateOAMSprites
    call GetBGMapAddress
    ld a, [wInGateworld]
    or a
    jr nz, jr_009_6832

    ld hl, $0604
    rst $10
    jr jr_009_687a

jr_009_6832:
    ld de, $2e15
    ld hl, $8500
    call WaitDMATransfer
    ld de, $2e16
    ld hl, $8540
    call WaitDMATransfer
    ld de, $2e17
    ld hl, $8580
    call WaitDMATransfer
    ld de, MenuBorderFillLeft
    ld hl, $85c0
    call WaitDMATransfer
    ld de, $2e19
    ld hl, $8600
    call WaitDMATransfer
    ld de, $2e1a
    ld hl, $8640
    call WaitDMATransfer
    ld de, $2e1b
    ld hl, $8680
    call WaitDMATransfer
    ld de, $2e1c
    ld hl, $86c0
    call WaitDMATransfer

jr_009_687a:
    ld hl, wGameState
    bit 7, [hl]
    jr nz, jr_009_6888

    res 4, [hl]
    xor a
    ld [$c905], a
    ret


jr_009_6888:
    ld hl, wGameState
    res 7, [hl]
    ret


LoadFld9_688e:
    ld a, [$c8f4]
    cp $00
    jr nz, jr_009_68aa

    ld a, $d3
    ld [$c0c8], a
    ld a, $d4
    ld [$c0c9], a
    ld a, $d5
    ld [$c0ca], a
    ld a, $d6
    ld [$c0cb], a
    ret


; Random NAME for a monster left unnamed (S108: the naming screen calls this when
; the name is still blank at END — the PRE-FILL is the species' default nickname,
; text mode 7, FuncFld9_621f) ($C8F4 = species + $10, set by the recruit / script
; callers; $C8F4 = 0 -> the 4 placeholder glyphs $D3-$D6).
; Text mode 3 (bank $41 FamilyNamePoolTable, 160 ids) holds 16 names per
; family: id = family<<4 | ($C8F6 bit 0, the gender bit of struct +$0B)*8
; | RNG & 7. Written to the name buffer $C0C8.
jr_009_68aa:
    call GenerateRNG
    ld a, [$c8f4]
    sub $10
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10                         ; $DA33 = the species' family (info byte 0)
    ld a, [$da33]
    ld c, a
    ld a, [wRNG1]
    and $07
    swap c
    or c
    ld c, a                         ; C = family<<4 | RNG&7
    ld a, [$c8f6]
    and $01
    add a
    add a
    add a
    add c                           ; + gender*8
    ld l, a
    ld h, $03                       ; H = text mode 3 (family name pools)
    ld de, $c0c8
    call SetupVRAMParams
    ret


SetFld9_68d9:
    ld hl, $c0c8
    ld b, $10

jr_009_68de:
    ld a, [hl]
    cp $f0
    jr z, jr_009_68e8

    inc hl
    dec b
    jr nz, jr_009_68de

    ret


jr_009_68e8:
    ld a, $9f
    ld [hl+], a
    dec b
    jr nz, jr_009_68e8

    ret


SetFld9_68ef:
    ld hl, $c0c8
    ld a, [hl+]
    cp [hl]
    jr nz, jr_009_6904

    inc hl
    cp [hl]
    jr nz, jr_009_6904

    inc hl
    cp [hl]
    jr nz, jr_009_6904

    inc hl
    ld a, [hl]
    cp $9f
    jr z, jr_009_6917

jr_009_6904:
    ld hl, $6985

jr_009_6907:
    ld de, $c0c8
    ld b, $08
    push hl

jr_009_690d:
    ld a, [de]
    cp [hl]
    inc hl
    inc de
    jr nz, jr_009_6919

    dec b
    jr nz, jr_009_690d

    pop hl

jr_009_6917:
    scf
    ret


jr_009_6919:
    pop hl
    ld a, l
    add $08
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    cp $ff
    jr nz, jr_009_6907

    scf
    ccf
    ret


FuncFld9_692a:
    ld c, $00

jr_009_692c:
    ld a, c
    push bc
    ld hl, $cac1
    call GetMonsterDataPtr
    pop bc
    ld a, [hl]
    or a
    jr z, jr_009_6982

    ld a, l
    add $01
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [$c8f2]
    ld e, a
    ld a, [$c8f3]
    ld d, a
    ld a, e
    sub l
    ld e, a
    ld a, d
    sbc h
    ld d, a
    ld a, d
    or e
    jr z, jr_009_697c

    ld de, $c0c8
    ld b, $08

jr_009_6958:
    ld a, [de]

jr_009_6959:
    cp $9f
    jr z, jr_009_696f

    cp $f0
    jr z, jr_009_696f

    cp $00
    jr z, jr_009_696f

    cp [hl]
    inc hl
    inc de
    jr nz, jr_009_697c

    dec b
    jr nz, jr_009_6958

jr_009_696d:
    scf
    ret


jr_009_696f:
    ld a, [hl]
    cp $9f
    jr z, jr_009_696d

    cp $f0
    jr z, jr_009_696d

    cp $00
    jr z, jr_009_696d

jr_009_697c:
    inc c
    ld a, c
    cp $14
    jr nz, jr_009_692c

jr_009_6982:
    scf
    ccf
    ret

    db $34, $55, $42, $8e, $9f, $9f, $9f, $9f, $34, $55, $42, $8e, $2d, $9f, $9f, $9f
    db $34, $55, $34, $55, $9f, $9f, $9f, $9f, $28, $43, $55, $2d, $9f, $9f, $9f, $9f
    db $43, $55, $2d, $9f, $9f, $9f, $9f, $9f, $28, $46, $2d, $9f, $9f, $9f, $9f, $9f
    db $31, $36, $2b, $30, $9f, $9f, $9f, $9f, $68, $6d, $62, $67, $9f, $9f, $9f, $9f
    db $26, $55, $2d, $9f, $9f, $9f, $9f, $9f, $2a, $55, $33, $43, $9f, $9f, $9f, $9f
    db $62, $9f, $9f, $9f, $9f, $9f, $9f, $9f, $62, $62, $9f, $9f, $9f, $9f, $9f, $9f
    db $62, $62, $62, $9f, $9f, $9f, $9f, $9f, $62, $62, $62, $62, $9f, $9f, $9f, $9f
    db $ff


LoadFld9_69f6:
    ld a, [wOPTN_and_Item_selection]
    ld c, $11
    call Mul8x8To16
    ld a, [wMenu_selection]
    add l
    ld de, $6607
    ld c, a
    bit 7, a
    jr nz, jr_009_6a1a

    ld a, [wCursorBlinkTimer]
    and $0f
    push af
    ld a, [wCursorBlinkTimer]
    inc a
    ld [wCursorBlinkTimer], a
    pop af
    ld a, c
    ret nz

jr_009_6a1a:
    ld c, a
    ld b, $00

Jump_009_6a1d:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, c
    and $7f
    cp b
    ld a, $e0
    jr nz, jr_009_6a4d

    ld a, $a0
    bit 7, c
    jr nz, jr_009_6a4d

    ld a, [wCursorBlinkTimer]
    bit 4, a
    ld a, $e0
    jr nz, jr_009_6a4d

    ld a, $a0

jr_009_6a4d:
    ldh [$d7], a
    ld a, b
    cp $41
    jr z, jr_009_6a7f

    cp $42
    jr z, jr_009_6a7f

    cp $43
    jr z, jr_009_6a7f

    cp $52
    jr z, jr_009_6a7f

    cp $53
    jr z, jr_009_6a7f

    cp $54
    jr z, jr_009_6a7f

    call HramFld9_6a96
    ld a, b
    cp $40
    jr z, jr_009_6a76

    cp $51
    jr z, jr_009_6a79

    jr jr_009_6a7f

jr_009_6a76:
    call SaveFld9_6a83

jr_009_6a79:
    call SaveFld9_6a83
    call SaveFld9_6a83

jr_009_6a7f:
    inc b
    jp Jump_009_6a1d


SaveFld9_6a83:
    push af
    ld hl, $ffd5
    inc [hl]
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    pop af

HramFld9_6a96:
    ldh a, [$d7]
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    ret


SetFld9_6aad:
    ld hl, $c0c8
    ld b, $08
    ld c, $00

jr_009_6ab4:
    ld a, [hl+]
    dec b
    ret z

    inc de
    cp $8d
    jr z, jr_009_6ab4

    cp $8e
    jr z, jr_009_6ab4

    cp $9f
    jr z, jr_009_6ab4

    inc c
    jr jr_009_6ab4

    ret


CallFld9_6ac8:
    call SetFld9_6aad
    ld de, $6b06
    ld b, $00

jr_009_6ad0:
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]
    ld h, a
    inc de
    and l
    cp $ff
    ret z

    ld a, l
    ldh [$d5], a
    ld a, h
    ldh [$d6], a
    push de
    push bc
    call SaveFld9_4076
    pop bc
    pop de
    ld a, c
    cp b
    ld a, $e0
    jr nz, jr_009_6aef

    ld a, $a0

jr_009_6aef:
    call Write_gfx_tile
    push af
    ldh a, [$d5]
    ld l, a
    ldh a, [$d6]
    ld h, a
    ld a, l
    add $00
    ld l, a
    ld a, h
    adc $c5
    ld h, a
    pop af
    ld [hl], a
    inc b
    jr jr_009_6ad0

    ld l, b
    nop
    ld l, c
    nop
    ld l, d
    nop
    ld l, e
    nop
    rst $38
    rst $38
FollowerGfxTable09:
FieldPtrLookupTable:   ; (mgbdis name, kept: referenced by the readers / patches)
    ; FOLLOWER (walking) gfx-ID table — one of the EIGHT per-screen copies
    ; (MONSTER_DATA 'Follower-art table has EIGHT copies'; bank $01's
    ; ScreenTransDataTable is the overworld one). Read by the naming / evaluator screens $61FB.
    ; Index = species + $10 -> gfx-ID (bank<<8 | index) -> $<bank>:$4001 + index*2.
    ; 231 words: 16 non-monster entries, then species 0-214; ids 215+ read past the end (never followers).
    ; A re-arted species writes the SAME new gfx-ID into all eight copies
    ; (S107: compiler region art_walk_09, gamedata.art).
    ; Re-sectioned S107 (tools/resection_monster_art_tables.py), byte-identical.
; Entry 0 is also the naming screen's hero icon: bank $09 loads this sheet to
; VRAM $8500 and draws sprite type 0 (frames 0 / 1, tile base $50) through bank
; $04 entries 2 / 3 — the player shape (S121 trace).
    dw $2f00   ; [  0] default
    dw $3140   ; [  1] non-monster (loader index 1-15)
    dw $3140   ; [  2] non-monster (loader index 1-15)
    dw $3140   ; [  3] non-monster (loader index 1-15)
    dw $3140   ; [  4] non-monster (loader index 1-15)
    dw $3140   ; [  5] non-monster (loader index 1-15)
    dw $3140   ; [  6] non-monster (loader index 1-15)
    dw $3140   ; [  7] non-monster (loader index 1-15)
    dw $3140   ; [  8] non-monster (loader index 1-15)
    dw $3140   ; [  9] non-monster (loader index 1-15)
    dw $3140   ; [ 10] non-monster (loader index 1-15)
    dw $3140   ; [ 11] non-monster (loader index 1-15)
    dw $3140   ; [ 12] non-monster (loader index 1-15)
    dw $3140   ; [ 13] non-monster (loader index 1-15)
    dw $3140   ; [ 14] non-monster (loader index 1-15)
    dw $3140   ; [ 15] non-monster (loader index 1-15)
    dw $2f01   ; [ 16] species 0 DrakSlime
    dw $2f02   ; [ 17] species 1 SpotSlime
    dw $2f03   ; [ 18] species 2 WingSlime
    dw $2f04   ; [ 19] species 3 TreeSlime
    dw $2f05   ; [ 20] species 4 Snaily
    dw $2f06   ; [ 21] species 5 SlimeNite
    dw $2f07   ; [ 22] species 6 Babble
    dw $2f08   ; [ 23] species 7 BoxSlime
    dw $2f09   ; [ 24] species 8 Slime
    dw $2f0a   ; [ 25] species 9 Healer
    dw $2f0b   ; [ 26] species 10 FangSlime
    dw $2f0c   ; [ 27] species 11 RockSlime
    dw $2f0d   ; [ 28] species 12 SlimeBorg
    dw $2f0e   ; [ 29] species 13 Slabbit
    dw $2f0f   ; [ 30] species 14 SpotKing
    dw $2f10   ; [ 31] species 15 KingSlime
    dw $3800   ; [ 32] species 16 Metaly
    dw $3801   ; [ 33] species 17 Metabble
    dw $3802   ; [ 34] species 18 MetalKing
    dw $3803   ; [ 35] species 19 GoldSlime
    dw $3804   ; [ 36] species 20 DragonKid
    dw $3805   ; [ 37] species 21 Tortragon
    dw $3806   ; [ 38] species 22 Pteranod
    dw $3807   ; [ 39] species 23 Gasgon
    dw $3808   ; [ 40] species 24 FairyDrak
    dw $3809   ; [ 41] species 25 LizardMan
    dw $380a   ; [ 42] species 26 Poisongon
    dw $380b   ; [ 43] species 27 Swordgon
    dw $380c   ; [ 44] species 28 Dragon
    dw $380d   ; [ 45] species 29 MiniDrak
    dw $380e   ; [ 46] species 30 MadDragon
    dw $380f   ; [ 47] species 31 Rayburn
    dw $3810   ; [ 48] species 32 Chamelgon
    dw $3811   ; [ 49] species 33 LizardFly
    dw $3812   ; [ 50] species 34 Andreal
    dw $3813   ; [ 51] species 35 KingCobra
    dw $3814   ; [ 52] species 36 Spikerous
    dw $3815   ; [ 53] species 37 GreatDrak
    dw $3816   ; [ 54] species 38 Crestpent
    dw $3817   ; [ 55] species 39 WingSnake
    dw $3818   ; [ 56] species 40 Coatol
    dw $3819   ; [ 57] species 41 Orochi
    dw $381a   ; [ 58] species 42 BattleRex
    dw $381b   ; [ 59] species 43 SkyDragon
    dw $381c   ; [ 60] species 44 Divinegon
    dw $381d   ; [ 61] species 45 Tonguella
    dw $381e   ; [ 62] species 46 Almiraj
    dw $381f   ; [ 63] species 47 CatFly
    dw $3820   ; [ 64] species 48 PillowRat
    dw $3821   ; [ 65] species 49 Saccer
    dw $3822   ; [ 66] species 50 GulpBeast
    dw $3823   ; [ 67] species 51 Skullroo
    dw $3824   ; [ 68] species 52 WindBeast
    dw $3825   ; [ 69] species 53 Anteater
    dw $3826   ; [ 70] species 54 SuperTen
    dw $3827   ; [ 71] species 55 IronTurt
    dw $3828   ; [ 72] species 56 Mommonja
    dw $3829   ; [ 73] species 57 HammerMan
    dw $382a   ; [ 74] species 58 Grizzly
    dw $382b   ; [ 75] species 59 Yeti
    dw $382c   ; [ 76] species 60 MadGopher
    dw $382d   ; [ 77] species 61 FairyRat
    dw $382e   ; [ 78] species 62 Unicorn
    dw $382f   ; [ 79] species 63 Goategon
    dw $3830   ; [ 80] species 64 WildApe
    dw $3831   ; [ 81] species 65 Trumpeter
    dw $3832   ; [ 82] species 66 KingLeo
    dw $3833   ; [ 83] species 67 DarkHorn
    dw $3834   ; [ 84] species 68 MadCat
    dw $3835   ; [ 85] species 69 BigEye
    dw $3836   ; [ 86] species 70 Picky
    dw $3837   ; [ 87] species 71 Wyvern
    dw $3838   ; [ 88] species 72 BullBird
    dw $3839   ; [ 89] species 73 Florajay
    dw $383a   ; [ 90] species 74 DuckKite
    dw $383b   ; [ 91] species 75 MadPecker
    dw $383c   ; [ 92] species 76 MadRaven
    dw $383d   ; [ 93] species 77 MistyWing
    dw $383e   ; [ 94] species 78 Dracky
    dw $383f   ; [ 95] species 79 BigRoost
    dw $3840   ; [ 96] species 80 StubBird
    dw $3841   ; [ 97] species 81 LandOwl
    dw $3842   ; [ 98] species 82 MadGoose
    dw $3843   ; [ 99] species 83 MadCondor
    dw $3844   ; [100] species 84 Blizzardy
    dw $3845   ; [101] species 85 Phoenix
    dw $3846   ; [102] species 86 ZapBird
    dw $3847   ; [103] species 87 WhipBird
    dw $3900   ; [104] species 88 FunkyBird
    dw $3901   ; [105] species 89 RainHawk
    dw $3902   ; [106] species 90 MadPlant
    dw $3903   ; [107] species 91 FireWeed
    dw $3904   ; [108] species 92 FloraMan
    dw $3905   ; [109] species 93 WingTree
    dw $3906   ; [110] species 94 CactiBall
    dw $3907   ; [111] species 95 Gulpple
    dw $3908   ; [112] species 96 Toadstool
    dw $3909   ; [113] species 97 AmberWeed
    dw $390a   ; [114] species 98 Stubsuck
    dw $390b   ; [115] species 99 Oniono
    dw $390c   ; [116] species 100 DanceVegi
    dw $390d   ; [117] species 101 TreeBoy
    dw $390e   ; [118] species 102 FaceTree
    dw $390f   ; [119] species 103 HerbMan
    dw $3910   ; [120] species 104 BeanMan
    dw $3911   ; [121] species 105 EvilSeed
    dw $3912   ; [122] species 106 ManEater
    dw $3913   ; [123] species 107 Snapper
    dw $3914   ; [124] species 108 Rosevine
    dw $3915   ; [125] species 109 Watabou
    dw $3916   ; [126] species 110 GiantSlug
    dw $3917   ; [127] species 111 Catapila
    dw $3918   ; [128] species 112 Gophecada
    dw $3919   ; [129] species 113 Butterfly
    dw $391a   ; [130] species 114 WeedBug
    dw $391b   ; [131] species 115 GiantWorm
    dw $391c   ; [132] species 116 Lipsy
    dw $391d   ; [133] species 117 StagBug
    dw $391e   ; [134] species 118 ArmyAnt
    dw $391f   ; [135] species 119 GoHopper
    dw $3920   ; [136] species 120 TailEater
    dw $3921   ; [137] species 121 ArmorPede
    dw $3922   ; [138] species 122 Eyeder
    dw $3923   ; [139] species 123 GiantMoth
    dw $3924   ; [140] species 124 Droll
    dw $3925   ; [141] species 125 ArmyCrab
    dw $3926   ; [142] species 126 MadHornet
    dw $3927   ; [143] species 127 HornBeet
    dw $3928   ; [144] species 128 Armorpion
    dw $3929   ; [145] species 129 Digster
    dw $392a   ; [146] species 130 Pixy
    dw $392b   ; [147] species 131 ArcDemon
    dw $392c   ; [148] species 132 AgDevil
    dw $392d   ; [149] species 133 Demonite
    dw $392e   ; [150] species 134 DarkEye
    dw $392f   ; [151] species 135 EyeBall
    dw $3930   ; [152] species 136 SkulRider
    dw $3931   ; [153] species 137 EvilBeast
    dw $3932   ; [154] species 138 1EyeClown
    dw $3933   ; [155] species 139 Gremlin
    dw $3934   ; [156] species 140 MedusaEye
    dw $3935   ; [157] species 141 Lionex
    dw $3936   ; [158] species 142 GoatHorn
    dw $3937   ; [159] species 143 Orc
    dw $3938   ; [160] species 144 Ogre
    dw $3939   ; [161] species 145 GateGuard
    dw $393a   ; [162] species 146 ChopClown
    dw $393b   ; [163] species 147 Grendal
    dw $393c   ; [164] species 148 Akubar
    dw $393d   ; [165] species 149 MadKnight
    dw $393e   ; [166] species 150 Gigantes
    dw $393f   ; [167] species 151 Centasaur
    dw $3940   ; [168] species 152 EvilArmor
    dw $3941   ; [169] species 153 Jamirus
    dw $3942   ; [170] species 154 Durran
    dw $3943   ; [171] species 155 Spooky
    dw $3944   ; [172] species 156 Skullgon
    dw $3945   ; [173] species 157 Putrepup
    dw $3946   ; [174] species 158 RotRaven
    dw $3947   ; [175] species 159 Mummy
    dw $3a00   ; [176] species 160 DarkCrab
    dw $3a01   ; [177] species 161 DeadNite
    dw $3a02   ; [178] species 162 Shadow
    dw $3a03   ; [179] species 163 Hork
    dw $3a04   ; [180] species 164 Mudron
    dw $3a05   ; [181] species 165 NiteWhip
    dw $3a06   ; [182] species 166 MadSpirit
    dw $3a07   ; [183] species 167 WindMerge
    dw $3a08   ; [184] species 168 Reaper
    dw $3a09   ; [185] species 169 DeadNoble
    dw $3a0a   ; [186] species 170 WhiteKing
    dw $3a0b   ; [187] species 171 BoneSlave
    dw $3a0c   ; [188] species 172 Skeletor
    dw $3a0d   ; [189] species 173 Servant
    dw $3a0e   ; [190] species 174 Copycat
    dw $3a0f   ; [191] species 175 JewelBag
    dw $3a10   ; [192] species 176 EvilWand
    dw $3a11   ; [193] species 177 MadCandle
    dw $3a12   ; [194] species 178 CoilBird
    dw $3a13   ; [195] species 179 Facer
    dw $3a14   ; [196] species 180 SpikyBoy
    dw $3a15   ; [197] species 181 MadMirror
    dw $3a16   ; [198] species 182 RogueNite
    dw $3a17   ; [199] species 183 Goopi
    dw $3a18   ; [200] species 184 Voodoll
    dw $3a19   ; [201] species 185 MetalDrak
    dw $3a1a   ; [202] species 186 Balzak
    dw $3a1b   ; [203] species 187 SabreMan
    dw $3a1c   ; [204] species 188 CurseLamp
    dw $3a1d   ; [205] species 189 Roboster
    dw $3a1e   ; [206] species 190 EvilPot
    dw $3a1f   ; [207] species 191 Gismo
    dw $3a20   ; [208] species 192 LavaMan
    dw $3a21   ; [209] species 193 IceMan
    dw $3a22   ; [210] species 194 Mimic
    dw $3a23   ; [211] species 195 MudDoll
    dw $3a24   ; [212] species 196 Golem
    dw $3a25   ; [213] species 197 StoneMan
    dw $3a26   ; [214] species 198 BombCrag
    dw $3a27   ; [215] species 199 GoldGolem
    dw $3a28   ; [216] species 200 DracoLord
    dw $3a29   ; [217] species 201 DracoLord
    dw $3a2a   ; [218] species 202 Hargon
    dw $3a2b   ; [219] species 203 Sidoh
    dw $3a2c   ; [220] species 204 Baramos
    dw $3a2d   ; [221] species 205 Zoma
    dw $3a2e   ; [222] species 206 Pizzaro
    dw $3a2f   ; [223] species 207 Esterk
    dw $3a30   ; [224] species 208 Mirudraas
    dw $3a31   ; [225] species 209 Mirudraas
    dw $3a32   ; [226] species 210 Mudou
    dw $3a33   ; [227] species 211 DeathMore
    dw $3a34   ; [228] species 212 DeathMore
    dw $3a35   ; [229] species 213 DeathMore
    dw $3a36   ; [230] species 214 Darkdrium
; NOTE: unreferenced fake-decode labels removed with this block: jr_009_6b57, jr_009_6b5d, jr_009_6b63, jr_009_6b69, jr_009_6b6f, jr_009_6b75, jr_009_6b7b, jr_009_6b81, jr_009_6b87, jr_009_6b8d, jr_009_6b93, jr_009_6b99, jr_009_6b9f, jr_009_6ba5, jr_009_6bab, jr_009_6bb1, jr_009_6bb7, jr_009_6bbd, jr_009_6bc3, jr_009_6bc9, jr_009_6bcf, jr_009_6bd5, jr_009_6bdb, jr_009_6be1, jr_009_6be7, jr_009_6bea, jr_009_6bf0, jr_009_6bf3, jr_009_6bf6, jr_009_6bf9, jr_009_6bfc, jr_009_6bff, jr_009_6c02, jr_009_6c05, jr_009_6c08, jr_009_6c0b, jr_009_6c0e, jr_009_6c14, jr_009_6c17, jr_009_6c1a, jr_009_6c20, jr_009_6c26, jr_009_6c4b, jr_009_6c5b, jr_009_6c6b, jr_009_6c7b, jr_009_6c8b, jr_009_6cdc
    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28

jr_009_6cec:
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $38
    add hl, sp
    ld a, [hl-]
    dec sp
    inc a
    dec a

jr_009_6cfc:
    ld a, $3f
    ld b, b
    adc b
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    rst $38
    ret c

    cp $e0

jr_009_6d0c:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $41
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, b
    ld c, c
    sub c
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $4a
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld d, d
    sbc d
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $53
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    ld e, d
    ld e, e
    and e
    and h
    and l
    and [hl]
    and a
    xor b
    xor c
    xor d
    xor e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $5c
    ld e, l
    ld e, [hl]
    ld e, a
    ld h, b
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    xor h
    xor l
    xor [hl]
    xor a
    or b
    or c
    or d
    or e
    or h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $65
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $6e
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    cp [hl]
    cp a
    ret nz

    pop bc
    jp nz, $c4c3

    push bc
    add $ff
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $77
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    rst $00
    ret z

    ret


    jp z, $cccb

    call $cfce
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $b0
    or c
    or d
    or e
    or h
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
    ret nc

    pop de
    jp nc, $ffd3

    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld sp, $e032
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    xor b
    and a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    inc c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $dd
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    xor d
    call nc, $e0e0
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub $d5
    sbc $de
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    push de
    xor e
    and l
    xor c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    add c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld b, b
    ld bc, $effa
    rst $28
    ei
    ret c

    cp $e0
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    db $fd
    reti


    ld b, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e5], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    adc b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    push de
    and a
    xor b
    xor c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    xor d
    xor e
    xor h
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    and l
    and [hl]
    and a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    xor c
    xor d
    xor e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld l, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld l, h
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $dd
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld b, [hl]
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $a0
    and c
    and d
    and e
    ldh [$dd], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub d
    sbc b
    sbc h
    db $e3
    ldh [$9c], a
    sub e
    sub e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    db $e3
    sub l
    sub c
    sub [hl]
    ldh [$9a], a
    db $e3
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub c
    sub h
    push de
    sub c
    sub [hl]
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub $d5
    db $e3
    sub b
    sbc b
    sub b
    sbc c
    push de
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub $97
    push de
    push de
    db $e3
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    push de
    and d
    sub l
    sbc c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add h
    add l
    add [hl]
    add a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc b
    adc c
    adc d
    adc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc h
    adc l
    adc [hl]
    adc a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    dec c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $9e
    sub b
    sub $99
    push de
    sbc b
    db $e4
    and b
    and c
    and d
    and e
    ldh [$e0], a
    ldh [$e4], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $da
    and h
    and l
    and [hl]
    and a
    ldh [$db], a
    xor b
    xor c
    xor d
    xor e
    ldh [$dc], a
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    cp $e0
    sbc a
    db $e4
    ldh [$e0], a
    ldh [$e0], a
    sbc a
    db $e4
    ldh [$e0], a
    ldh [$e0], a
    sbc a
    db $e4
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    add b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $84
    ldh [$80], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $85
    ldh [$81], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $86
    ldh [$82], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $87
    ldh [$83], a
    ldh [$91], a
    sub a
    sub b
    sub $d6
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    adc d
    sbc b
    push de
    push de
    sub d
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub h
    sub b
    sbc c
    sub c
    sub h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld b, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    ld b, b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sbc e
    sub h
    sbc h
    ldh [rIE], a
    ret c

    db $ec
    db $eb
    db $eb
    db $eb
    db $eb
    db $eb
    db $ed
    ret c

    cp $e0
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    add hl, bc
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e0], a
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    xor c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e0], a
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld c, c
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e0], a
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    ld b, b
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$e0], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    add a
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    and b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    and c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    and d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    and e
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    push de
    rst $18
    sbc a
    sbc $e0
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    sbc $d5
    sub $d6
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    push de
    and l
    and c
    and e
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    add a
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    sbc e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    sbc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    sbc [hl]
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and h
    and l
    and [hl]
    and a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor b
    xor c
    xor d
    xor e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    xor h
    xor l
    xor [hl]
    xor a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    add b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ldh [$9e], a
    sbc a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$a0], a
    and c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $63
    ldh [$9e], a
    sbc a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $63
    ldh [$a0], a
    and c
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    add a
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    adc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    adc l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    adc [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    adc a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $fd
    reti


    inc c
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    and c
    and a
    xor c
    and h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and h
    and d
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld c, $01
    ld a, [$efef]
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    call nc, $d6d5
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc l
    sbc h
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld l, h
    ld l, l
    ld l, [hl]
    ld l, a
    ld [hl], b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld [$fa00], sp
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    add b
    add c
    add d
    add e
    add h
    add l
    add [hl]
    add a
    adc b
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    adc c
    adc d
    adc e
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    sbc b
    sbc c
    sbc d
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc e
    sbc h
    sbc l
    sbc [hl]
    sbc a
    and b
    and c
    and d
    and e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    and h
    and l
    and [hl]
    and a
    xor b
    xor c
    xor d
    xor e
    xor h
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    ld bc, $0202
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    inc bc
    ret c

    inc b
    add b
    add c
    add d
    add e
    add h
    add l
    nop
    nop
    inc d
    dec d
    ld d, $17
    jr jr_009_7b0f

    ld a, [de]
    dec de
    inc e
    nop
    dec b
    ret c

    inc b
    add [hl]
    add a
    adc b
    adc c
    adc d
    adc e
    nop
    ld a, [bc]
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    dec bc
    inc c

jr_009_7b0f:
    dec b
    ret c

    inc b
    adc h
    adc l
    adc [hl]
    adc a
    sub b
    sub c
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    sub d
    sub e
    sub h
    sub l
    sub [hl]
    sub a
    ld de, $0000
    dec e
    ld e, $1f
    jr nz, jr_009_7b56

    ld [hl+], a
    inc hl
    inc h
    dec h
    dec b
    ret c

    inc b
    sbc b
    sbc c
    sbc d
    sbc e
    sbc h
    sbc l
    ld [de], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    sbc [hl]
    sbc a
    and b
    and c
    and d

jr_009_7b56:
    and e
    nop
    nop
    nop
    ld h, $27
    jr z, jr_009_7b87

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $05
    ret c

    inc b
    dec c
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    ld c, $0e
    rrca
    dec b
    ret c

    inc b
    and l
    and [hl]
    and a
    xor b
    xor c
    xor d
    nop
    nop
    nop
    cpl
    jr nc, jr_009_7bb8

jr_009_7b87:
    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]
    ld [hl], $37
    dec b
    ret c

    inc b
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    stop
    jr c, jr_009_7bd4

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ld a, $3f
    ld b, b
    dec b
    ret c

    inc b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, b
    ld c, c
    dec b

jr_009_7bb8:
    ret c

    inc b
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    dec b
    ret c

    inc b
    ld c, d
    ld c, e
    ld c, h
    ld c, l
    ld c, [hl]

jr_009_7bd4:
    ld c, a
    ld d, b
    ld d, c
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ld e, b
    ld e, c
    ld e, d
    ld e, e
    dec b
    ret c

    inc b
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    dec b
    ret c

    inc b
    ld e, h
    ld e, l
    ld e, [hl]
    ld e, a
    ld h, b
    ld h, c
    ld h, d
    ld h, e
    ld h, h
    ld h, l
    ld h, [hl]
    ld h, a
    ld l, b
    ld l, c
    ld l, d
    ld l, e
    ld l, h
    ld l, l
    dec b
    ret c

    inc b
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    inc de
    dec b
    ret c

    inc b
    ld l, [hl]
    ld l, a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], h
    ld [hl], l
    db $76
    ld [hl], a
    ld a, b
    ld a, c
    ld a, d
    ld a, e
    ld a, h
    ld a, l
    ld a, [hl]
    ld a, a
    dec b
    ret c

    ld b, $07
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0808], sp
    ld [$0908], sp
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    rst $38
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $fd
    reti


    nop
    ld bc, $effa
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    sub l
    sbc l
    sub e
    sbc h
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $e0
    sbc h
    sub [hl]
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    ld h, $00
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $e0
    nop
    ld bc, $0302
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee

jr_009_7cc9:
    db $fd
    reti


    and b
    nop
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $24
    dec h
    ld h, $27
    jr z, jr_009_7cc9

    ld a, $3f
    ld b, b
    ld b, c
    ld b, d
    ldh [$e0], a
    sub c
    sub d
    sub e
    sub h
    sub l
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $29
    ld a, [hl+]
    dec hl
    inc l
    dec l
    ldh [rSCX], a
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ldh [$e0], a
    ld c, c
    ld c, e
    ld c, l
    adc l
    adc [hl]
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $2e
    cpl
    jr nc, jr_009_7d6c

    ld [hl-], a
    ldh [rOBP0], a
    ldh [rWY], a
    ldh [$4c], a
    ldh [$e0], a
    ld h, b
    ld l, d
    ld h, b

jr_009_7d47:
    ld [hl], b
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $33
    inc [hl]
    dec [hl]
    scf
    jr c, jr_009_7d47

    ld c, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld d, d

jr_009_7d6c:
    ldh [$e0], a
    ld b, a
    sbc b
    ld d, b
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $39
    ld a, [hl-]
    dec sp
    inc a
    dec a
    ldh [rHDMA3], a
    ld d, h
    ld d, l
    ld [hl], $9c
    ldh [$e0], a
    jr z, jr_009_7ded

    ld d, b
    ldh [$e0], a
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    and b
    nop
    ld a, [$efef]
    rst $28

jr_009_7dcf:
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $24
    dec h
    ld h, $27
    jr z, jr_009_7e10

    ld a, [hl+]
    dec hl
    inc l
    dec l
    ld l, $2f

jr_009_7ded:
    jr nc, jr_009_7dcf

    inc b
    dec b
    ld b, $07
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $31
    ld [hl-], a
    inc sp
    inc [hl]
    dec [hl]

jr_009_7e10:
    ld [hl], $37
    jr c, jr_009_7e4d

    ld a, [hl-]
    dec sp
    inc a
    dec a
    ldh [$08], a
    add hl, bc
    ld a, [bc]
    dec bc
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $3e
    ccf
    ld b, b
    ld b, c
    ld b, d
    ld b, e
    ld b, h
    ld b, l
    ld b, [hl]
    ld b, a
    ld c, b
    ld c, c
    ld c, d
    ldh [$0c], a
    dec c
    ld h, e
    ld h, h
    rst $38
    ret c

    cp $e0
    ldh [$e0], a

jr_009_7e4d:
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $4b
    ld c, h
    ld c, l
    ld c, [hl]
    ld c, a
    ld d, b
    ld d, c
    ld d, d
    ld d, e
    ld d, h
    ld d, l
    ld d, [hl]
    ld d, a
    ldh [rNR51], a
    inc h
    ld h, $2e
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $5c
    ld e, [hl]
    ld e, a
    ld h, b
    ld h, c
    ld h, d
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    jr z, jr_009_7eca

    daa
    ldh [rIE], a
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop
    nop

jr_009_7eca:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
