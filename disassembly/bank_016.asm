; =============================================================================
; BANK $16 — BREEDING SYSTEM
; =============================================================================
; Contains:
;   - Breeding initialization (entry 0 → BreedingInit at $4015)
;   - Offspring determination (entry 2 → BreedingResolve at $456E)
;   - Offspring determination alt (entry 3 → $45A3, same logic minus $44D0 call)
;   - Offspring skill inheritance (entry 4 → $474A)
;   - Resistance inheritance (Call_016_4360/$4373)
;
; BREEDING ALGORITHM (Call_016_456e):
;   1. Call_016_4653 — Compute offspring "plus" value from parents
;      Then search SPECIAL RECIPE TABLE at $4B30 (825 entries × 5 bytes)
;      Format: [parent1_match, parent2_match, min_plus, result_species, plus_mod]
;      Matches: specific species OR family code ($F0-$F9)
;      Checked FIRST — takes priority over family table
;
;   2. Call_016_45d5 → Call_016_45ff — Search FAMILY RECIPE TABLE at $4974
;      Format: 2-byte pairs [B, C] with $FFFF separators between result species
;      D (result species index) increments at EVERY entry
;      EXACT species match: returns immediately
;      FAMILY match: stores result but KEEPS SCANNING (last family match wins)
;      Two passes: first with specific parent2, then with parent2→family
;
;   3. Fallback — offspring = parent 1 species ($DA6F)
;
;   4. Mutation system (~1-5% RNG, at $44DA) can override result post-recipe
;
; KEY DATA TABLES:
;   $4B30: Special recipe table — 825 entries × 5 bytes, $FF terminated
;   $4974: Family recipe table — 2-byte pairs, $0000 terminated
;          215 result species indexed by position (separators = $FFFF)
;
; RAM VARIABLES:
;   $DA6F: Parent 1 (pedigree) species ID
;   $DA70: Parent 2 (mate) species ID (or family code $F0-$F9 after conversion)
;   $DA71: Result species ID (output, $FF = not yet found)
;   $DA72: Parent 1 family code ($F0-$F9)
;   $DA73: Parent 1 family code (for special table)
;   $DA74: Parent 2 family code (for special table)
;   $DA75: Parent 1 party slot index
;   $DA76: Parent 2 party slot index
;   $DA77: Offspring "plus" value (0-99)
;   $CAC0: Current monster slot index
;   $CB23+idx*$95: Monster "plus" value in party struct (offset $62)
;
; Sources: pure disassembly analysis, breeding_complete.json
; =============================================================================

; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $016", ROMX[$4000], BANK[$16]
    db $16 ;rom bank

    ; Bank $16 jump table (10 entries)
    dw label16_4015          ; Entry 0: BreedingInit — find empty slot, init offspring
    dw label16_485c          ; Entry 1: Unknown
    dw Call_016_456e          ; Entry 2: BreedingResolve — determine offspring species
    dw label16_45a3          ; Entry 3: BreedingResolve alt (no mutation step)
    dw label16_474a          ; Entry 4: Skill/stat inheritance
    dw label16_5b4e          ; Entry 5
    dw label16_5fe4          ; Entry 6
    dw Call_016_6db0          ; Entry 7
    dw label16_6f05          ; Entry 8
    dw LoadFloorDataPointer          ; Entry 9

label16_4015:
    ld de, $cac1
    ld b, $14
    ld c, $00

jr_016_401c:
    ld a, [de]
    or a
    jr z, jr_016_402d

    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    inc c
    dec b
    jr nz, jr_016_401c

    ret


jr_016_402d:
    ld a, c
    ld [$cac0], a
    ld [$ca40], a
    ld hl, $cac1
    call Call_016_41b1
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $caea
    call Call_016_41b1
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    call Call_016_41b1
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $cac1
    call Call_016_41b1
    ld [hl], $01
    ld a, [$d66e]
    ld [$da6f], a
    ld a, [$d703]
    ld [$da70], a
    ld a, $14
    ld [$da75], a
    ld a, $15
    ld [$da76], a
    call Call_016_456e
    ld hl, $caca
    call Call_016_41b1
    ld a, [$da71]
    ld [hl], a
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [wTempSpeciesId]
    ld hl, $ca94
    call SetBitInArray
    ld hl, $cacb
    call Call_016_41b1
    ld a, [$da33]
    ld [hl], a
    ld a, [$da77]
    push af
    ld hl, $cb23
    call Call_016_41b1
    pop af
    cp $63
    jr c, jr_016_40b3

    ld a, $63

jr_016_40b3:
    ld [hl], a
    ld hl, $cb23
    call Call_016_41b1
    ld a, [hl]
    ld l, a
    ld h, $00
    add hl, hl
    ld a, [$da34]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, h
    or a
    jr nz, jr_016_40d7

    ld a, l
    cp $02
    jr nc, jr_016_40d3

    ld a, $02

jr_016_40d3:
    cp $63
    jr c, jr_016_40d9

jr_016_40d7:
    ld a, $63

jr_016_40d9:
    push af
    ld hl, $cb0d
    call Call_016_41b1
    pop af
    ld [hl], a
    ld hl, $cb0c
    call Call_016_41b1
    ld [hl], $01
    ld hl, $cb13
    call Call_016_41b8
    push bc
    ld hl, $cb11
    call Call_016_41b1
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld hl, $cb17
    call Call_016_41b8
    push bc
    ld hl, $cb15
    call Call_016_41b1
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld hl, $cb19
    call Call_016_41b8
    ld hl, $cb1b
    call Call_016_41b8
    ld hl, $cb1d
    call Call_016_41b8
    ld hl, $cb1f
    call Call_016_41b8
    ld hl, $cb25
    call Call_016_41ff
    ld hl, $cb26
    call Call_016_41ff
    ld hl, $cb28
    call Call_016_41ff
    ld hl, $cb27
    call Call_016_41ff
    ld hl, $cb29
    ld de, $da42
    ld b, $1b
    call Call_016_4227
    call Call_016_4360
    call GenerateRNG
    ld hl, $44cc
    ld a, [$da36]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wRNG1]
    cp [hl]
    jr z, jr_016_4169

    jr nc, jr_016_4169

    ld hl, $cacc
    call Call_016_41b1
    ld [hl], $01

jr_016_4169:
    ld hl, $cb24
    call Call_016_41b1
    ld [hl], $01
    call Call_016_4238
    ld de, $da39
    ld b, $03
    call Call_016_4496
    ld a, [$d66e]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call Call_016_4496
    ld a, [$d703]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call Call_016_4496
    ld de, $d68e
    ld b, $08
    call Call_016_4496
    ld de, $d723
    ld b, $08
    call Call_016_4496
    ret


Call_016_41b1:
    ld a, [$cac0]
    call GetMonsterDataPtr
    ret


Call_016_41b8:
    push hl
    ld a, l
    add $a4
    ld l, a
    ld a, h
    adc $0b
    ld h, a
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ld a, l
    add $94
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl+]
    add c
    ld c, a
    ld a, [hl]
    adc b
    ld b, a
    srl b
    rr c
    srl b
    rr c
    pop hl
    push bc
    call Call_016_41b1
    pop bc
    push hl
    push bc
    push bc
    call Call_016_4313
    pop bc
    call Mul16x8To24
    ld a, $32
    call Div16x8To16
    pop bc
    add hl, bc
    ld c, l
    ld b, h
    ld a, c
    or b
    jr nz, jr_016_41fa

    ld bc, $0001

jr_016_41fa:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


Call_016_41ff:
    push hl
    ld a, l
    add $a4
    ld l, a
    ld a, h
    adc $0b
    ld h, a
    ld a, [hl]
    ld c, a
    ld b, $00
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    add c
    ld c, a
    ld a, $00
    add b
    ld b, a
    srl b
    rr c
    pop hl
    push bc
    call Call_016_41b1
    pop bc
    ld [hl], c
    ret


Call_016_4227:
    push bc
    push de
    ld a, [$cac0]
    call GetMonsterDataPtr
    pop de
    pop bc

jr_016_4231:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_016_4231

    ret


Call_016_4238:
    ld a, [$d670]
    and $01
    or a
    jp nz, Jump_016_42aa

    ld hl, $cad6
    call Call_016_41b1
    ld a, [$d66e]
    ld [hl], a
    ld hl, $cad8
    ld de, $d671
    ld b, $08
    call Call_016_4227
    ld hl, $cae0
    call Call_016_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb44
    ld de, $d666
    ld b, $08
    call Call_016_4227
    ld hl, $cb4c
    call Call_016_41b1
    ld a, [$d6c7]
    ld [hl], a
    ld hl, $cad7
    call Call_016_41b1
    ld a, [$d703]
    ld [hl], a
    ld hl, $cae1
    ld de, $d706
    ld b, $08
    call Call_016_4227
    ld hl, $cae9
    call Call_016_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb4d
    ld de, $d6fb
    ld b, $08
    call Call_016_4227
    ld hl, $cb55
    call Call_016_41b1
    ld a, [$d75c]
    ld [hl], a
    ret


Jump_016_42aa:
    ld hl, $cad6
    call Call_016_41b1
    ld a, [$d703]
    ld [hl], a
    ld hl, $cad8
    ld de, $d706
    ld b, $08
    call Call_016_4227
    ld hl, $cae0
    call Call_016_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb44
    ld de, $d6fb
    ld b, $08
    call Call_016_4227
    ld hl, $cb4c
    call Call_016_41b1
    ld a, [$d75c]
    ld [hl], a
    ld hl, $cad7
    call Call_016_41b1
    ld a, [$d66e]
    ld [hl], a
    ld hl, $cae1
    ld de, $d671
    ld b, $08
    call Call_016_4227
    ld hl, $cae9
    call Call_016_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb4d
    ld de, $d666
    ld b, $08
    call Call_016_4227
    ld hl, $cb55
    call Call_016_41b1
    ld a, [$d6c7]
    ld [hl], a
    ret


Call_016_4313:
    ld c, $00
    ld hl, $d671
    call Call_016_434f
    ld a, [$d67a]
    cp $ff
    ld hl, $d6e8
    call nz, Call_016_434f
    ld a, [$d67b]
    cp $ff
    ld hl, $d6f1
    call nz, Call_016_434f
    ld hl, $d706
    call Call_016_434f
    ld a, [$d70f]
    cp $ff
    ld hl, $d77d
    call nz, Call_016_434f
    ld a, [$d710]
    cp $ff
    ld hl, $d786
    call nz, Call_016_434f
    ld a, c
    ret


Call_016_434f:
    ld de, $ca42
    ld b, $09

jr_016_4354:
    ld a, [de]
    cp [hl]
    jr z, jr_016_435a

    inc c
    ret


jr_016_435a:
    inc de
    inc hl
    dec b
    jr nz, jr_016_4354

    ret


Call_016_4360:
    xor a
    ld [$da72], a
    ld b, $1b

jr_016_4366:
    push bc
    call Call_016_4373
    ld hl, $da72
    inc [hl]
    pop bc
    dec b
    jr nz, jr_016_4366

    ret


Call_016_4373:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call Call_016_41b1
    ld a, [hl]
    cp $03
    ret z

    cp $02
    jp z, Jump_016_43fc

    ld a, [$da72]
    ld hl, $d6cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    push af
    ld a, [$da72]
    ld hl, $d762
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    add [hl]
    and $07
    rst $00
    cp b
    ld b, e
    cp b
    ld b, e
    cp b
    ld b, e
    cp c
    ld b, e
    add $43
    db $d3
    ld b, e
    db $ec
    ld b, e
    ret


    ld a, [$da77]
    ld b, a
    ld a, $64
    call Call_016_4444
    call c, Call_016_4481
    ret


    ld a, [$da77]
    ld b, a
    ld a, $1e
    call Call_016_4444
    call c, Call_016_4481
    ret


    ld a, [$da77]
    ld b, a
    ld a, $0a
    call Call_016_4444
    call c, Call_016_4481
    ld a, [$da77]
    ld b, a
    ld a, $1e
    call Call_016_4444
    call c, Call_016_4481
    ret


    call Call_016_4481
    ld a, [$da77]
    ld b, a
    ld a, $14
    call Call_016_4444
    call c, Call_016_4481
    ret


Jump_016_43fc:
    ld a, [$da72]
    ld hl, $d6cd
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    push af
    ld a, [$da72]
    ld hl, $d762

Call_016_4410:
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    add [hl]
    and $07
    rst $00
    add hl, hl
    ld b, h
    add hl, hl
    ld b, h
    add hl, hl
    ld b, h
    add hl, hl
    ld b, h
    add hl, hl
    ld b, h
    ld a, [hl+]
    ld b, h
    scf
    ld b, h
    ret


    ld a, [$da77]
    ld b, a
    ld a, $c8
    call Call_016_4444
    call c, Call_016_446c
    ret


    ld a, [$da77]
    ld b, a
    ld a, $28
    call Call_016_4444
    call c, Call_016_446c
    ret


Call_016_4444:
    push bc
    push af
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    pop af
    call Div16x8To16
    pop bc
    cp b
    ret


    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call Call_016_41b1
    ld a, [hl]
    or a
    ret z

    dec [hl]
    ret


Call_016_446c:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call Call_016_41b1
    ld a, [hl]
    cp $03
    ret z

    inc [hl]
    ret


Call_016_4481:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call Call_016_41b1
    ld a, [hl]
    cp $02
    ret z

    inc [hl]
    ret


Call_016_4496:
jr_016_4496:
    ld a, [de]
    inc de
    push bc
    push de
    call Call_016_44a3
    pop de
    pop bc
    dec b
    jr nz, jr_016_4496

    ret


Call_016_44a3:
    cp $ff
    ret z

    ld hl, UnevolvedSkillMap
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    push af
    ld hl, $caf2
    call Call_016_41b1
    pop af
    ld b, $19
    ld c, a

jr_016_44be:
    ld a, [hl]
    cp c
    ret z

    cp $ff
    jr nz, jr_016_44c7

    ld [hl], c
    ret


jr_016_44c7:
    inc hl
    dec b
    jr nz, jr_016_44be

    ret


    db $00, $1a, $80, $d6

    ld a, [$c86c]
    or a
    ret nz

    xor a
    ld [$d9e6], a
    ret


    ld a, [$da71]
    cp $ff
    jr z, jr_016_450f

    call GenerateRNG
    ld a, [wRNG1]
    cp $03
    ret nc

    ld b, $c8
    ld d, $d7
    call Call_016_453d
    ld a, [wRNG2]
    ld b, a
    ld a, c
    or a
    ret z

    call Div8x8
    ld b, $c8
    ld d, $d7
    ld e, a
    call Call_016_4553
    ld a, b
    ld [$da71], a
    ld hl, $d9e6
    inc [hl]
    cp $ff
    ret z

    ret


jr_016_450f:
    call GenerateRNG
    ld a, [wRNG1]
    cp $0e
    ret nc

    ld b, $00
    ld d, $c8
    call Call_016_453d
    ld a, [wRNG2]
    ld b, a
    ld a, c
    or a
    ret z

    call Div8x8
    ld b, $00
    ld d, $c8
    ld e, a
    call Call_016_4553
    ld a, b
    ld [$da71], a
    cp $ff
    ret z

    ld hl, $d9e6
    inc [hl]
    ret


Call_016_453d:
    ld c, $00

jr_016_453f:
    push bc
    push de
    ld hl, $ca94
    ld a, b
    call TestBitInArray
    pop de
    pop bc
    jr z, jr_016_454d

    inc c

jr_016_454d:
    inc b
    ld a, b
    cp d
    jr nz, jr_016_453f

    ret


Call_016_4553:
    ld c, $00

jr_016_4555:
    push bc
    push de
    ld hl, $ca94
    ld a, b
    call TestBitInArray
    pop de
    pop bc
    jr z, jr_016_4566

    ld a, c
    cp e
    ret z

    inc c

jr_016_4566:
    inc b
    ld a, b
    cp d
    jr nz, jr_016_4555

    ld b, $ff
    ret


; BreedingResolve — Determine offspring species from two parents
; Input: $DA6F = parent 1 species, $DA70 = parent 2 species
;        $DA75/$DA76 = parent party slot indices
; Output: $DA71 = result species, $DA77 = offspring plus value
Call_016_456e:
    ld a, $ff
    ld [$da71], a            ; result = not found
    ld a, $ff
    ld [$da72], a
    ld a, $ff
    ld [$da73], a
    ld a, $ff
    ld [$da74], a
    ld a, $ff
    ld [$da77], a
    call Call_016_4653        ; Step 1: compute plus, search special table ($4B30)
    ld a, [$da71]
    cp $ff
    ret nz                   ; if special table found a result, done

    call Call_016_45d5        ; Step 2: search family table ($4974)
    call $44d0                ; Step 3: clear utility (checks $C86C link flag)
    ld a, [$da71]
    cp $ff
    ret nz                   ; if family table found a result, done

    ld a, [$da6f]            ; Step 4: fallback — offspring = parent 1 species
    ld [$da71], a
    ret

label16_45a3:
    ld a, $ff
    ld [$da71], a
    ld a, $ff
    ld [$da72], a
    ld a, $ff
    ld [$da73], a
    ld a, $ff
    ld [$da74], a
    ld a, $ff
    ld [$da77], a
    call Call_016_4653
    ld a, [$da71]
    cp $ff
    ret nz

    call Call_016_45d5
    ld a, [$da71]
    cp $ff
    ret nz

    ld a, [$da6f]
    ld [$da71], a
    ret


; BreedingFamilySearch — Search family recipe table with parent swap
; First pass: parent1 specific + parent2 specific → exact matches only
; If no match: convert parent2 to family code, search again
Call_016_45d5:
    ld a, [$da70]            ; parent 2
    cp $f0
    jr nc, jr_016_45ff       ; if already family-coded, skip first pass

    ld a, [$da6f]            ; save parent 1
    push af
    call Call_016_45ff        ; first pass: parent2 still specific
    pop af
    ld [$da6f], a            ; restore parent 1
    ld a, [$da71]
    cp $ff
    ret nz                   ; found something, return

    ld a, [$da70]            ; convert parent 2 species → family code
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10                  ; load parent 2 monster info
    ld a, [$da33]            ; family byte (offset 0)
    add $f0                  ; convert to family code ($F0-$F9)
    ld [$da70], a

; BreedingTableScan — Search family recipe table at $4974
; Converts parent 1 to family code, then scans all entries
Call_016_45ff:
jr_016_45ff:
    ld a, [$da6f]            ; parent 1
    cp $f0
    jr nc, jr_016_4615       ; if already family-coded, skip conversion

    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10                  ; load parent 1 monster info
    ld a, [$da33]            ; family byte
    add $f0                  ; convert to family code
    ld [$da72], a            ; parent 1 family code

jr_016_4615:
    ld hl, $4974             ; family recipe table base
    ld d, $ff                ; D = result species index (starts at $FF, first inc → 0)

; Family table scan loop
; Table format: 2-byte pairs [B, C], $FFFF = separator (next result species), $0000 = end
; D increments at every entry (including separators)
; B = parent 1 matcher (species or family code)
; C = parent 2 matcher (species or family code)
jr_016_461a:
    inc d                    ; result species index++
    ld b, [hl]               ; B = entry parent 1 matcher
    inc hl
    ld c, [hl]               ; C = entry parent 2 matcher
    inc hl
    ld a, b
    or c
    ret z                    ; $0000 = end of table

    ld a, b
    and c
    cp $ff
    jr z, jr_016_461a        ; $FFFF = separator, skip (D already incremented)

    ; Check parent 2 ($DA70) against C
    ld a, [$da70]
    and $f0
    cp $f0
    jr nz, jr_016_4636       ; parent 2 is specific species → exact compare

    ; Parent 2 is family-coded: special handling for Boss family
    ld a, c
    cp $fa                   ; Boss family ($FA) matches any family parent 2
    jr z, jr_016_463c

jr_016_4636:
    ld a, [$da70]
    cp c                     ; compare parent 2 with C
    jr nz, jr_016_461a       ; no match → next entry

jr_016_463c:
    ; Parent 2 matched. Now check parent 1 against B
    ld a, [$da6f]
    cp b
    jr z, jr_016_464e        ; EXACT species match → immediate return

    ld a, [$da72]            ; try family match
    cp b
    jr nz, jr_016_464c       ; no family match either → skip

    ld a, d
    ld [$da71], a            ; FAMILY match → store result, keep scanning (last wins)

jr_016_464c:
    jr jr_016_461a            ; continue scanning

jr_016_464e:
    ld a, d                  ; EXACT match → store result and return immediately
    ld [$da71], a
    ret


; BreedingSpecialAndPlus — Compute plus value, then search special table ($4B30)
; Computes offspring plus from parents' plus values and levels
; Then converts parent species to family codes ($DA73/$DA74)
; Finally searches the 825-entry special recipe table
Call_016_4653:
    ld a, [$da75]
    ld hl, $cb23
    call GetMonsterDataPtr
    ld a, [hl]
    ld b, a
    ld a, [$c86c]
    or a
    jr nz, jr_016_467d

    ld a, [$da75]
    ld hl, $cb23
    call GetMonsterDataPtr
    ld b, [hl]
    push bc
    ld a, [$da76]
    ld hl, $cb23
    call GetMonsterDataPtr
    ld a, [hl]
    pop bc
    cp b
    jr nc, jr_016_467e

jr_016_467d:
    ld a, b

jr_016_467e:
    inc a
    ld [$da77], a
    ld a, [$da75]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld b, [hl]
    push bc
    ld a, [$da76]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    pop bc
    add b
    ld c, $04
    cp $64
    jr nc, jr_016_46b3

    ld c, $03
    cp $4c
    jr nc, jr_016_46b3

    ld c, $02
    cp $3c
    jr nc, jr_016_46b3

    ld c, $01
    cp $28
    jr nc, jr_016_46b3

    ld c, $00

jr_016_46b3:
    ld a, [$da77]
    add c
    ld [$da77], a
    ld a, [$da77]
    cp $63
    jr c, jr_016_46c6

    ld a, $63
    ld [$da77], a

jr_016_46c6:
    ld a, [$da6f]
    cp $f0
    jr nc, jr_016_46dc

    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    add $f0
    ld [$da73], a

jr_016_46dc:
    ld a, [$da70]
    cp $f0
    jr nc, jr_016_46f2

    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [$da33]
    add $f0
    ld [$da74], a

jr_016_46f2:
    ld hl, $4b30             ; special recipe table base (825 entries × 5 bytes)

; Special table scan loop
jr_016_46f5:
    ld a, [hl]
    cp $ff                   ; $FF = end of table
    jr z, jr_016_4710

    push hl
    call Call_016_471c        ; check this entry against parents
    pop hl
    ld a, [$da71]
    cp $ff
    jr nz, jr_016_4710       ; found a match → done

    ld a, l
    add $05                  ; advance to next 5-byte entry
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_016_46f5

jr_016_4710:
    ld a, [$da77]            ; clamp plus to max 99
    cp $63
    ret c

    ld a, $63
    ld [$da77], a
    ret


; SpecialEntryCheck — Check one 5-byte special table entry
; Format: [parent1_match, parent2_match, min_plus, result_species, plus_mod]
; Matches parent species (specific) or family code ($DA73/$DA74)
; Plus threshold: offspring plus ($DA77) must be >= entry byte 2
Call_016_471c:
    ld a, [$da6f]            ; parent 1 species (specific)
    cp [hl]
    jr z, jr_016_4728        ; exact parent 1 match

    ld a, [$da73]            ; parent 1 family code
    cp [hl]
    jr nz, jr_016_4749       ; no match → skip

jr_016_4728:
    inc hl
    ld a, [$da70]            ; parent 2 species (specific)
    cp [hl]
    jr z, jr_016_4735        ; exact parent 2 match

    ld a, [$da74]            ; parent 2 family code
    cp [hl]
    jr nz, jr_016_4749       ; no match → skip

jr_016_4735:
    inc hl
    ld a, [$da77]            ; offspring plus value
    cp [hl]
    jr c, jr_016_4749        ; plus < threshold → skip

    inc hl
    ld a, [hl]               ; result species ID
    ld [$da71], a            ; store result
    inc hl
    ld a, [$da77]
    add [hl]                 ; add plus modifier
    ld [$da77], a

jr_016_4749:
    ret


label16_474a:
    ld hl, $cb21
    call Call_016_47e0
    xor a
    ld [hl+], a
    ld [hl], a
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call Call_016_47e7
    ld hl, $cad5
    call Call_016_47e0
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $c0d8
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caca
    call Call_016_47e0
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call Call_016_47f8
    ld hl, $cad6
    call Call_016_47e0
    ld a, [hl]
    cp $ff
    jr z, jr_016_47b9

    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call Call_016_47f8
    ld hl, $cad7
    call Call_016_47e0
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call Call_016_47f8

jr_016_47b9:
    ld hl, $caf2
    call Call_016_47e0
    ld e, l
    ld d, h
    ld b, $19
    call Call_016_4805
    ld hl, $caf2
    call Call_016_47e0
    ld de, $c0d8
    ld b, $19

jr_016_47d1:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_016_47d1

    ld hl, $cb24
    call Call_016_47e0
    ld [hl], $00
    ret


Call_016_47e0:
    ld a, [$cac0]
    call GetMonsterDataPtr
    ret


Call_016_47e7:
    push bc
    push de
    ld a, [$cac0]
    call GetMonsterDataPtr
    pop de
    pop bc

jr_016_47f1:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_016_47f1

    ret


Call_016_47f8:
jr_016_47f8:
    ld a, [de]
    inc de
    push bc
    push de
    call Call_016_4838
    pop de
    pop bc
    dec b
    jr nz, jr_016_47f8

    ret


Call_016_4805:
jr_016_4805:
    push bc
    push de
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    ld b, a
    push bc
    ld hl, $cb23
    call Call_016_47e0
    pop bc
    ld a, [hl]
    cp b
    pop de
    pop bc
    jr jr_016_482b

    inc de
    dec b
    jr nz, jr_016_4805

    ret


jr_016_482b:
    ld a, [de]
    inc de
    push bc
    push de
    call Call_016_4838
    pop de
    pop bc
    dec b
    jr nz, jr_016_4805

    ret


Call_016_4838:
    cp $ff
    ret z

    ld hl, UnevolvedSkillMap
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    ret z

    ld hl, $c0d8
    ld b, $19
    ld c, a

jr_016_484e:
    ld a, [hl]
    cp c
    ret z

    cp $ff
    jr nz, jr_016_4857

    ld [hl], c
    ret


jr_016_4857:
    inc hl
    dec b
    jr nz, jr_016_484e

    ret

label16_485c:
    ld a, [$da6f]
    ld l, a
    ld h, $00
    add hl, hl
    ld a, l
    add $74
    ld l, a
    ld a, h
    adc $49
    ld h, a
    ld a, [hl+]
    ld [$da71], a
    ld a, [hl]
    ld [$da72], a
    ret

; ---------------------------------------------------------------
; UnevolvedSkillMap — 256 bytes
; Maps skill ID (as array index) → base skill ID in evolution chain.
; Example: Blazemore ($01) → Blaze ($00), Explodet ($08) → Bang ($06).
; $FF = skill cannot be inherited (fake/special skills only).
; Used during breeding to inherit evolved versions of parent skills.
; ---------------------------------------------------------------
UnevolvedSkillMap:
    db $00, $00, $00, $03, $03, $03, $06, $06, $06, $09, $09, $09, $0c, $0c, $0c, $0f
    db $0f, $0f, $12, $12, $14, $15, $15, $17, $18, $19, $1a, $1a, $1c, $1c, $1e, $1e
    db $20, $20, $22, $22, $24, $25, $26, $27, $27, $29, $2a, $2b, $2b, $2b, $2e, $2e
    db $30, $30, $32, $33, $34, $35, $36, $37, $38, $39, $ff, $3b, $3c, $3d, $3e, $3f
    db $40, $41, $42, $43, $44, $45, $46, $47, $48, $49, $4a, $4b, $4c, $4d, $4e, $4f
    db $50, $50, $52, $52, $54, $55, $56, $57, $58, $58, $5a, $5b, $5c, $5c, $5c, $5c
    db $60, $60, $60, $60, $64, $65, $66, $67, $68, $69, $6a, $6b, $6c, $6c, $6e, $6f
    db $70, $71, $72, $73, $74, $75, $75, $77, $78, $79, $79, $7b, $7b, $7d, $7e, $7f
    db $80, $81, $82, $83, $84, $84, $84, $84, $88, $88, $8a, $8a, $8c, $ff, $8e, $8f
    db $90, $91, $92, $93, $94, $95, $96, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $d5, $d6, $d7, $d8, $d9, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $f0, $f1, $f0, $f2, $f0, $f3, $f0, $f4, $f0, $f5, $f0, $f6, $f0, $f7, $f0, $f8
    db $ff, $ff, $f0, $5a, $f0, $2e, $f0, $c6, $f0, $bd, $f0, $33, $ff, $ff, $f0, $f9
    db $f0, $b9, $10, $10, $11, $11, $12, $12, $f1, $f0, $f1, $f2, $f1, $f3, $f1, $f4
    db $f1, $f5, $f1, $f6, $f1, $f7, $f1, $f8, $14, $14, $f1, $46, $f1, $32, $f1, $53
    db $f1, $b8, $f1, $77, $f1, $5f, $f1, $06, $f1, $7d, $ff, $ff, $f1, $4f, $26, $26
    db $27, $27, $22, $8c, $f1, $8d, $f1, $55, $2b, $29, $f2, $f0, $f2, $f1, $f2, $f3
    db $f2, $f4, $f2, $f5, $ff, $ff, $f2, $f7, $f2, $f8, $ff, $ff, $f2, $a4, $f2, $15
    db $f2, $4a, $f2, $62, $f2, $f6, $f2, $8f, $f2, $bb, $f2, $21, $f2, $0a, $f2, $00
    db $f2, $4b, $40, $40, $41, $41, $f2, $f9, $f2, $1c, $f2, $87, $f3, $f0, $f3, $f1
    db $f3, $f2, $f3, $f4, $f3, $f5, $f3, $f6, $f3, $f7, $f3, $f8, $ff, $ff, $ff, $ff
    db $f3, $0b, $ff, $ff, $f3, $7c, $f3, $b2, $f3, $c1, $f3, $bf, $f3, $f9, $f3, $1f
    db $f3, $64, $54, $55, $f4, $f0, $f4, $f1, $f4, $f2, $f4, $f3, $f4, $f5, $f4, $f6
    db $f4, $f7, $f4, $f8, $ff, $ff, $f4, $70, $f4, $b3, $f4, $82, $f4, $a5, $f4, $58
    db $f4, $30, $f4, $86, $69, $69, $6a, $6a, $f4, $f9, $ff, $ff, $f5, $f0, $f5, $f1
    db $f5, $f2, $f5, $f3, $f5, $f4, $f5, $f6, $f5, $f7, $f5, $f8, $ff, $ff, $ff, $ff
    db $f5, $5c, $f5, $37, $f5, $61, $f5, $31, $f5, $9b, $f5, $a0, $f5, $3d, $75, $75
    db $7f, $7f, $f5, $f9, $f6, $f0, $f6, $f9, $ff, $ff, $f6, $f3, $f6, $f4, $f6, $f5
    db $f6, $f7, $f6, $f8, $ff, $ff, $f6, $f2, $f6, $f1, $f6, $19, $f6, $43, $f6, $68
    db $f6, $39, $85, $85, $8a, $8a, $f6, $1e, $93, $93, $f6, $b6, $f6, $45, $ff, $ff
    db $f6, $79, $94, $59, $97, $c7, $f7, $f0, $f7, $1b, $f7, $f2, $f7, $f3, $f7, $f4
    db $f7, $f5, $f7, $f6, $f7, $f8, $ff, $ff, $f7, $6e, $f7, $4d, $f7, $f1, $f7, $34
    db $f7, $72, $a1, $a1, $f7, $f9, $a3, $a3, $ab, $ab, $ac, $ac, $ff, $ff, $f8, $f0
    db $f8, $f1, $f8, $f2, $f8, $f3, $f8, $f4, $f8, $f5, $f8, $f6, $f8, $f7, $ff, $ff
    db $f8, $74, $f8, $22, $f8, $f9, $f8, $73, $f8, $5d, $f8, $88, $f8, $04, $b7, $5b
    db $b9, $83, $bd, $42, $f8, $07, $b7, $b7, $c3, $c3, $c4, $c4, $b4, $b4, $c1, $c0
    db $ad, $25, $c8, $2c, $aa, $12, $99, $6c, $ca, $29, $c8, $cb, $9a, $2c, $ce, $42
    db $cf, $13, $d0, $24, $cc, $43, $cd, $d0, $d3, $80, $d4, $d2, $d5, $6d, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $00, $00, $00, $1b, $00, $0c
    db $00, $00, $24, $00, $0c, $00, $00, $25, $00, $0c, $00, $00, $2a, $00, $0c, $00
    db $00, $2b, $00, $0c, $00, $05, $1b, $00, $0c, $00, $05, $24, $00, $0c, $00, $05
    db $25, $00, $0c, $00, $05, $2a, $00, $0c, $00, $05, $2b, $00, $0c, $00, $0b, $1b
    db $00, $0c, $00, $0b, $24, $00, $0c, $00, $0b, $25, $00, $0c, $00, $0b, $2a, $00
    db $0c, $00, $0b, $2b, $00, $0c, $00, $11, $1b, $00, $0c, $00, $11, $24, $00, $0c
    db $00, $11, $25, $00, $0c, $00, $11, $2a, $00, $0c, $00, $11, $2b, $00, $0c, $00
    db $0f, $25, $00, $0e, $00, $0f, $2a, $00, $0e, $00, $0f, $2c, $00, $0e, $00, $0f
    db $3e, $00, $0e, $00, $0f, $42, $00, $0e, $00, $0f, $53, $00, $0e, $00, $0f, $56
    db $00, $0e, $00, $0f, $57, $00, $0e, $00, $0f, $96, $00, $0e, $00, $0f, $97, $00
    db $0e, $00, $0f, $a9, $00, $0e, $00, $0f, $aa, $00, $0e, $00, $12, $25, $00, $0e
    db $00, $12, $2a, $00, $0e, $00, $12, $2c, $00, $0e, $00, $12, $3e, $00, $0e, $00
    db $12, $42, $00, $0e, $00, $12, $53, $00, $0e, $00, $12, $56, $00, $0e, $00, $12
    db $57, $00, $0e, $00, $12, $96, $00, $0e, $00, $12, $97, $00, $0e, $00, $12, $a9
    db $00, $0e, $00, $12, $aa, $00, $0e, $00, $0e, $25, $00, $0f, $00, $0e, $2a, $00
    db $0f, $00, $0e, $2c, $00, $0f, $00, $0e, $3e, $00, $0f, $00, $0e, $42, $00, $0f
    db $00, $0e, $53, $00, $0f, $00, $0e, $56, $00, $0f, $00, $0e, $57, $00, $0f, $00
    db $0e, $96, $00, $0f, $00, $0e, $97, $00, $0f, $00, $0e, $a9, $00, $0f, $00, $0e
    db $aa, $00, $0f, $00, $08, $08, $05, $0f, $00, $01, $01, $05, $0e, $00, $0e, $c7
    db $00, $13, $00, $0f, $c7, $00, $13, $00, $12, $c7, $00, $13, $00, $0e, $b9, $00
    db $12, $00, $0f, $b9, $00, $12, $00, $14, $14, $04, $25, $00, $14, $14, $00, $1c
    db $00, $1c, $1c, $04, $25, $00, $17, $3f, $00, $22, $00, $17, $41, $00, $22, $00
    db $17, $53, $00, $22, $00, $17, $57, $00, $22, $00, $17, $58, $00, $22, $00, $17
    db $83, $00, $22, $00, $17, $8d, $00, $22, $00, $17, $8e, $00, $22, $00, $17, $90
    db $00, $22, $00, $17, $94, $00, $22, $00, $17, $a9, $00, $22, $00, $17, $c4, $00
    db $22, $00, $1e, $3f, $00, $22, $00, $1e, $41, $00, $22, $00, $1e, $53, $00, $22
    db $00, $1e, $57, $00, $22, $00, $1e, $58, $00, $22, $00, $1e, $83, $00, $22, $00
    db $1e, $8d, $00, $22, $00, $1e, $8e, $00, $22, $00, $1e, $90, $00, $22, $00, $1e
    db $94, $00, $22, $00, $1e, $a9, $00, $22, $00, $1e, $c4, $00, $22, $00, $2a, $3f
    db $00, $22, $00, $2a, $41, $00, $22, $00, $2a, $53, $00, $22, $00, $2a, $57, $00
    db $22, $00, $2a, $58, $00, $22, $00, $2a, $83, $00, $22, $00, $2a, $8d, $00, $22
    db $00, $2a, $8e, $00, $22, $00, $2a, $90, $00, $22, $00, $2a, $94, $00, $22, $00
    db $2a, $a9, $00, $22, $00, $2a, $c4, $00, $22, $00, $2b, $3f, $00, $22, $00, $2b
    db $41, $00, $22, $00, $2b, $53, $00, $22, $00, $2b, $57, $00, $22, $00, $2b, $58
    db $00, $22, $00, $2b, $83, $00, $22, $00, $2b, $8d, $00, $22, $00, $2b, $8e, $00
    db $22, $00, $2b, $90, $00, $22, $00, $2b, $94, $00, $22, $00, $2b, $a9, $00, $22
    db $00, $2b, $c4, $00, $22, $00, $19, $02, $00, $1f, $00, $19, $41, $00, $1f, $00
    db $19, $44, $00, $1f, $00, $19, $66, $00, $1f, $00, $19, $8d, $00, $1f, $00, $19
    db $8e, $00, $1f, $00, $19, $91, $00, $1f, $00, $19, $96, $00, $1f, $00, $16, $43
    db $00, $28, $00, $16, $95, $00, $28, $00, $16, $ae, $00, $28, $00, $16, $c5, $00
    db $28, $00, $17, $43, $00, $28, $00, $17, $95, $00, $28, $00, $17, $ae, $00, $28
    db $00, $17, $c5, $00, $28, $00, $19, $43, $00, $28, $00, $19, $95, $00, $28, $00
    db $19, $ae, $00, $28, $00, $19, $c5, $00, $28, $00, $2a, $43, $00, $28, $00, $2a
    db $95, $00, $28, $00, $2a, $ae, $00, $28, $00, $2a, $c5, $00, $28, $00, $2b, $43
    db $00, $28, $00, $2b, $95, $00, $28, $00, $2b, $ae, $00, $28, $00, $2b, $c5, $00
    db $28, $00, $22, $0c, $00, $b9, $00, $22, $0f, $00, $b9, $00, $22, $81, $00, $b9
    db $00, $22, $9c, $00, $b9, $00, $22, $bd, $00, $b9, $00, $22, $c4, $00, $b9, $00
    db $22, $c5, $00, $b9, $00, $24, $0c, $00, $b9, $00, $24, $0f, $00, $b9, $00, $24
    db $81, $00, $b9, $00, $24, $9c, $00, $b9, $00, $24, $bd, $00, $b9, $00, $24, $c4
    db $00, $b9, $00, $24, $c5, $00, $b9, $00, $25, $0c, $00, $b9, $00, $25, $0f, $00
    db $b9, $00, $25, $81, $00, $b9, $00, $25, $9c, $00, $b9, $00, $25, $bd, $00, $b9
    db $00, $25, $c4, $00, $b9, $00, $25, $c5, $00, $b9, $00, $22, $8c, $00, $29, $00
    db $25, $8c, $00, $29, $00, $37, $16, $00, $3b, $00, $37, $17, $00, $3b, $00, $37
    db $1b, $00, $3b, $00, $37, $1e, $00, $3b, $00, $37, $2a, $00, $3b, $00, $37, $2b
    db $00, $3b, $00, $3f, $16, $00, $3b, $00, $3f, $17, $00, $3b, $00, $3f, $1b, $00
    db $3b, $00, $3f, $1e, $00, $3b, $00, $3f, $2a, $00, $3b, $00, $3f, $2b, $00, $3b
    db $00, $40, $16, $00, $3b, $00, $40, $17, $00, $3b, $00, $40, $1b, $00, $3b, $00
    db $40, $1e, $00, $3b, $00, $40, $2a, $00, $3b, $00, $40, $2b, $00, $3b, $00, $44
    db $16, $00, $3b, $00, $44, $17, $00, $3b, $00, $44, $1b, $00, $3b, $00, $44, $1e
    db $00, $3b, $00, $44, $2a, $00, $3b, $00, $44, $2b, $00, $3b, $00, $2d, $03, $00
    db $36, $00, $2d, $0a, $00, $36, $00, $2d, $1e, $00, $36, $00, $2d, $58, $00, $36
    db $00, $2d, $5a, $00, $36, $00, $2d, $66, $00, $36, $00, $2d, $74, $00, $36, $00
    db $2d, $85, $00, $36, $00, $2d, $8b, $00, $36, $00, $2d, $ae, $00, $36, $00, $2d
    db $af, $00, $36, $00, $2d, $c2, $00, $36, $00, $32, $03, $00, $36, $00, $32, $0a
    db $00, $36, $00, $32, $1e, $00, $36, $00, $32, $58, $00, $36, $00, $32, $5a, $00
    db $36, $00, $32, $66, $00, $36, $00, $32, $74, $00, $36, $00, $32, $85, $00, $36
    db $00, $32, $8b, $00, $36, $00, $32, $ae, $00, $36, $00, $32, $af, $00, $36, $00
    db $32, $c2, $00, $36, $00, $2d, $51, $00, $41, $00, $2d, $53, $00, $41, $00, $2d
    db $56, $00, $41, $00, $2d, $57, $00, $41, $00, $32, $51, $00, $41, $00, $32, $53
    db $00, $41, $00, $32, $56, $00, $41, $00, $32, $57, $00, $41, $00, $3a, $51, $00
    db $41, $00, $3a, $53, $00, $41, $00, $3a, $56, $00, $41, $00, $3a, $57, $00, $41
    db $00, $3b, $51, $00, $41, $00, $3b, $53, $00, $41, $00, $3b, $56, $00, $41, $00
    db $3b, $57, $00, $41, $00, $2d, $81, $00, $32, $00, $2d, $9c, $00, $32, $00, $2d
    db $a9, $00, $32, $00, $2d, $aa, $00, $32, $00, $2d, $ac, $00, $32, $00, $3a, $81
    db $00, $32, $00, $3a, $9c, $00, $32, $00, $3a, $a9, $00, $32, $00, $3a, $aa, $00
    db $32, $00, $3a, $ac, $00, $32, $00, $3b, $81, $00, $32, $00, $3b, $9c, $00, $32
    db $00, $3b, $a9, $00, $32, $00, $3b, $aa, $00, $32, $00, $3b, $ac, $00, $32, $00
    db $3e, $81, $00, $32, $00, $3e, $9c, $00, $32, $00, $3e, $a9, $00, $32, $00, $3e
    db $aa, $00, $32, $00, $3e, $ac, $00, $32, $00, $40, $81, $00, $32, $00, $40, $9c
    db $00, $32, $00, $40, $a9, $00, $32, $00, $40, $aa, $00, $32, $00, $40, $ac, $00
    db $32, $00, $41, $81, $00, $32, $00, $41, $9c, $00, $32, $00, $41, $a9, $00, $32
    db $00, $41, $aa, $00, $32, $00, $41, $ac, $00, $32, $00, $37, $b9, $00, $32, $00
    db $37, $bd, $00, $32, $00, $37, $c0, $00, $32, $00, $37, $c1, $00, $32, $00, $37
    db $c4, $00, $32, $00, $37, $c5, $00, $32, $00, $3a, $b9, $00, $32, $00, $3a, $bd
    db $00, $32, $00, $3a, $c0, $00, $32, $00, $3a, $c1, $00, $32, $00, $3a, $c4, $00
    db $32, $00, $3a, $c5, $00, $32, $00, $3b, $b9, $00, $32, $00, $3b, $bd, $00, $32
    db $00, $3b, $c0, $00, $32, $00, $3b, $c1, $00, $32, $00, $3b, $c4, $00, $32, $00
    db $3b, $c5, $00, $32, $00, $3e, $b9, $00, $32, $00, $3e, $bd, $00, $32, $00, $3e
    db $c0, $00, $32, $00, $3e, $c1, $00, $32, $00, $3e, $c4, $00, $32, $00, $3e, $c5
    db $00, $32, $00, $3f, $b9, $00, $32, $00, $3f, $bd, $00, $32, $00, $3f, $c0, $00
    db $32, $00, $3f, $c1, $00, $32, $00, $3f, $c4, $00, $32, $00, $3f, $c5, $00, $32
    db $00, $40, $b9, $00, $32, $00, $40, $bd, $00, $32, $00, $40, $c0, $00, $32, $00
    db $40, $c1, $00, $32, $00, $40, $c4, $00, $32, $00, $40, $c5, $00, $32, $00, $32
    db $b9, $00, $41, $00, $32, $ba, $00, $41, $00, $32, $bd, $00, $41, $00, $32, $c0
    db $00, $41, $00, $32, $c1, $00, $41, $00, $32, $c4, $00, $41, $00, $32, $c5, $00
    db $41, $00, $41, $b9, $00, $42, $00, $41, $ba, $00, $42, $00, $41, $c7, $00, $42
    db $00, $51, $0b, $00, $57, $00, $51, $0c, $00, $57, $00, $51, $81, $00, $57, $00
    db $51, $b9, $00, $57, $00, $51, $c4, $00, $57, $00, $51, $c5, $00, $57, $00, $52
    db $0b, $00, $57, $00, $52, $0c, $00, $57, $00, $52, $81, $00, $57, $00, $52, $b9
    db $00, $57, $00, $52, $c4, $00, $57, $00, $52, $c5, $00, $57, $00, $53, $0b, $00
    db $57, $00, $53, $0c, $00, $57, $00, $53, $81, $00, $57, $00, $53, $b9, $00, $57
    db $00, $53, $c4, $00, $57, $00, $53, $c5, $00, $57, $00, $54, $0b, $00, $57, $00
    db $54, $0c, $00, $57, $00, $54, $81, $00, $57, $00, $54, $b9, $00, $57, $00, $54
    db $c4, $00, $57, $00, $54, $c5, $00, $57, $00, $56, $0b, $00, $57, $00, $56, $0c
    db $00, $57, $00, $56, $81, $00, $57, $00, $56, $b9, $00, $57, $00, $56, $c4, $00
    db $57, $00, $56, $c5, $00, $57, $00, $53, $bf, $00, $56, $00, $55, $bf, $00, $56
    db $00, $57, $bf, $00, $56, $00, $71, $71, $00, $7c, $00, $71, $78, $00, $7c, $00
    db $71, $7a, $00, $7c, $00, $78, $71, $00, $7c, $00, $78, $78, $00, $7c, $00, $78
    db $7a, $00, $7c, $00, $7a, $71, $00, $7c, $00, $7a, $78, $00, $7c, $00, $7a, $7a
    db $00, $7c, $00, $84, $0e, $00, $83, $00, $84, $0f, $00, $83, $00, $84, $12, $00
    db $83, $00, $84, $22, $00, $83, $00, $84, $25, $00, $83, $00, $84, $29, $00, $83
    db $00, $84, $41, $00, $83, $00, $84, $42, $00, $83, $00, $84, $56, $00, $83, $00
    db $84, $57, $00, $83, $00, $84, $b9, $00, $83, $00, $84, $c5, $00, $83, $00, $93
    db $0e, $00, $83, $00, $93, $0f, $00, $83, $00, $93, $12, $00, $83, $00, $93, $22
    db $00, $83, $00, $93, $25, $00, $83, $00, $93, $29, $00, $83, $00, $93, $41, $00
    db $83, $00, $93, $42, $00, $83, $00, $93, $56, $00, $83, $00, $93, $57, $00, $83
    db $00, $93, $b9, $00, $83, $00, $93, $c5, $00, $83, $00, $96, $0e, $00, $83, $00
    db $96, $0f, $00, $83, $00, $96, $12, $00, $83, $00, $96, $22, $00, $83, $00, $96
    db $25, $00, $83, $00, $96, $29, $00, $83, $00, $96, $41, $00, $83, $00, $96, $42
    db $00, $83, $00, $96, $56, $00, $83, $00, $96, $57, $00, $83, $00, $96, $b9, $00
    db $83, $00, $96, $c5, $00, $83, $00, $84, $0c, $00, $91, $00, $84, $1b, $00, $91
    db $00, $84, $28, $00, $91, $00, $84, $4d, $00, $91, $00, $84, $53, $00, $91, $00
    db $84, $6c, $00, $91, $00, $84, $7b, $00, $91, $00, $84, $9c, $00, $91, $00, $84
    db $a9, $00, $91, $00, $84, $aa, $00, $91, $00, $93, $0c, $00, $91, $00, $93, $1b
    db $00, $91, $00, $93, $28, $00, $91, $00, $93, $4d, $00, $91, $00, $93, $53, $00
    db $91, $00, $93, $6c, $00, $91, $00, $93, $7b, $00, $91, $00, $93, $9c, $00, $91
    db $00, $93, $a9, $00, $91, $00, $93, $aa, $00, $91, $00, $96, $0c, $00, $91, $00
    db $96, $1b, $00, $91, $00, $96, $28, $00, $91, $00, $96, $4d, $00, $91, $00, $96
    db $53, $00, $91, $00, $96, $6c, $00, $91, $00, $96, $7b, $00, $91, $00, $96, $9c
    db $00, $91, $00, $96, $a9, $00, $91, $00, $96, $aa, $00, $91, $00, $84, $32, $00
    db $90, $00, $84, $3e, $00, $90, $00, $84, $81, $00, $90, $00, $84, $bd, $00, $90
    db $00, $93, $32, $00, $90, $00, $93, $3e, $00, $90, $00, $93, $81, $00, $90, $00
    db $93, $bd, $00, $90, $00, $96, $32, $00, $90, $00, $96, $3e, $00, $90, $00, $96
    db $81, $00, $90, $00, $96, $bd, $00, $90, $00, $83, $91, $00, $94, $00, $9f, $0b
    db $00, $ab, $00, $9f, $0c, $00, $ab, $00, $9f, $51, $00, $ab, $00, $9f, $52, $00
    db $ab, $00, $9f, $5c, $00, $ab, $00, $9f, $7f, $00, $ab, $00, $9f, $8b, $00, $ab
    db $00, $a1, $0b, $00, $ab, $00, $a1, $0c, $00, $ab, $00, $a1, $51, $00, $ab, $00
    db $a1, $52, $00, $ab, $00, $a1, $5c, $00, $ab, $00, $a1, $7f, $00, $ab, $00, $a1
    db $8b, $00, $ab, $00, $a3, $0b, $00, $ab, $00, $a3, $0c, $00, $ab, $00, $a3, $51
    db $00, $ab, $00, $a3, $52, $00, $ab, $00, $a3, $5c, $00, $ab, $00, $a3, $7f, $00
    db $ab, $00, $a3, $8b, $00, $ab, $00, $9f, $32, $00, $ac, $00, $9f, $3a, $00, $ac
    db $00, $9f, $44, $00, $ac, $00, $9f, $4c, $00, $ac, $00, $9f, $53, $00, $ac, $00
    db $9f, $89, $00, $ac, $00, $9f, $90, $00, $ac, $00, $9f, $c4, $00, $ac, $00, $9f
    db $c5, $00, $ac, $00, $a1, $32, $00, $ac, $00, $a1, $3a, $00, $ac, $00, $a1, $44
    db $00, $ac, $00, $a1, $4c, $00, $ac, $00, $a1, $53, $00, $ac, $00, $a1, $89, $00
    db $ac, $00, $a1, $90, $00, $ac, $00, $a1, $c4, $00, $ac, $00, $a1, $c5, $00, $ac
    db $00, $a3, $32, $00, $ac, $00, $a3, $3a, $00, $ac, $00, $a3, $44, $00, $ac, $00
    db $a3, $4c, $00, $ac, $00, $a3, $53, $00, $ac, $00, $a3, $89, $00, $ac, $00, $a3
    db $90, $00, $ac, $00, $a3, $c4, $00, $ac, $00, $a3, $c5, $00, $ac, $00, $a4, $32
    db $00, $ac, $00, $a4, $3a, $00, $ac, $00, $a4, $44, $00, $ac, $00, $a4, $4c, $00
    db $ac, $00, $a4, $53, $00, $ac, $00, $a4, $89, $00, $ac, $00, $a4, $90, $00, $ac
    db $00, $a4, $c4, $00, $ac, $00, $a4, $c5, $00, $ac, $00, $a4, $83, $00, $a9, $00
    db $a4, $8d, $00, $a9, $00, $a4, $91, $00, $a9, $00, $a4, $b9, $00, $a9, $00, $a4
    db $bd, $00, $a9, $00, $a6, $83, $00, $a9, $00, $a6, $8d, $00, $a9, $00, $a6, $91
    db $00, $a9, $00, $a6, $b9, $00, $a9, $00, $a6, $bd, $00, $a9, $00, $ab, $83, $00
    db $a9, $00, $ab, $8d, $00, $a9, $00, $ab, $91, $00, $a9, $00, $ab, $b9, $00, $a9
    db $00, $ab, $bd, $00, $a9, $00, $ac, $83, $00, $a9, $00, $ac, $8d, $00, $a9, $00
    db $ac, $91, $00, $a9, $00, $ac, $b9, $00, $a9, $00, $ac, $bd, $00, $a9, $00, $9c
    db $0e, $00, $aa, $00, $9c, $0f, $00, $aa, $00, $9c, $12, $00, $aa, $00, $9c, $22
    db $00, $aa, $00, $9c, $25, $00, $aa, $00, $9c, $42, $00, $aa, $00, $9c, $54, $00
    db $aa, $00, $9c, $56, $00, $aa, $00, $9c, $57, $00, $aa, $00, $9c, $c7, $00, $aa
    db $00, $a9, $0e, $00, $aa, $00, $a9, $0f, $00, $aa, $00, $a9, $12, $00, $aa, $00
    db $a9, $22, $00, $aa, $00, $a9, $25, $00, $aa, $00, $a9, $42, $00, $aa, $00, $a9
    db $54, $00, $aa, $00, $a9, $56, $00, $aa, $00, $a9, $57, $00, $aa, $00, $a9, $c7
    db $00, $aa, $00, $ab, $0e, $00, $aa, $00, $ab, $0f, $00, $aa, $00, $ab, $12, $00
    db $aa, $00, $ab, $22, $00, $aa, $00, $ab, $25, $00, $aa, $00, $ab, $42, $00, $aa
    db $00, $ab, $54, $00, $aa, $00, $ab, $56, $00, $aa, $00, $ab, $57, $00, $aa, $00
    db $ab, $c7, $00, $aa, $00, $ac, $0e, $00, $aa, $00, $ac, $0f, $00, $aa, $00, $ac
    db $12, $00, $aa, $00, $ac, $22, $00, $aa, $00, $ac, $25, $00, $aa, $00, $ac, $42
    db $00, $aa, $00, $ac, $54, $00, $aa, $00, $ac, $56, $00, $aa, $00, $ac, $57, $00
    db $aa, $00, $ac, $c7, $00, $aa, $00, $9c, $ae, $00, $a9, $00, $a1, $ae, $00, $a9
    db $00, $a4, $ae, $00, $a9, $00, $ab, $ae, $00, $a9, $00, $ac, $ae, $00, $a9, $00
    db $c4, $00, $00, $b8, $00, $c4, $04, $00, $b8, $00, $c4, $05, $00, $b8, $00, $c4
    db $0b, $00, $b8, $00, $c5, $00, $00, $b8, $00, $c5, $04, $00, $b8, $00, $c5, $05
    db $00, $b8, $00, $c5, $0b, $00, $b8, $00, $b0, $51, $00, $bb, $00, $b0, $52, $00
    db $bb, $00, $b0, $55, $00, $bb, $00, $b0, $58, $00, $bb, $00, $b8, $51, $00, $bb
    db $00, $b8, $52, $00, $bb, $00, $b8, $55, $00, $bb, $00, $b8, $58, $00, $bb, $00
    db $c4, $51, $00, $bb, $00, $c4, $52, $00, $bb, $00, $c4, $55, $00, $bb, $00, $c4
    db $58, $00, $bb, $00, $c5, $51, $00, $bb, $00, $c5, $52, $00, $bb, $00, $c5, $55
    db $00, $bb, $00, $c5, $58, $00, $bb, $00, $b1, $00, $00, $bf, $00, $b1, $47, $00
    db $bf, $00, $b1, $4d, $00, $bf, $00, $b1, $55, $00, $bf, $00, $b1, $5b, $00, $bf
    db $00, $b1, $69, $00, $bf, $00, $b5, $00, $00, $bf, $00, $b5, $47, $00, $bf, $00
    db $b5, $4d, $00, $bf, $00, $b5, $55, $00, $bf, $00, $b5, $5b, $00, $bf, $00, $b5
    db $69, $00, $bf, $00, $b7, $00, $00, $bf, $00, $b7, $47, $00, $bf, $00, $b7, $4d
    db $00, $bf, $00, $b7, $55, $00, $bf, $00, $b7, $5b, $00, $bf, $00, $b7, $69, $00
    db $bf, $00, $bb, $0c, $00, $bd, $00, $bb, $25, $00, $bd, $00, $bb, $3e, $00, $bd
    db $00, $bb, $90, $00, $bd, $00, $bb, $93, $00, $bd, $00, $bb, $98, $00, $bd, $00
    db $bb, $a9, $00, $bd, $00, $bb, $ac, $00, $bd, $00, $b9, $9c, $00, $c1, $00, $b9
    db $aa, $00, $c1, $00, $b9, $29, $00, $c0, $00, $b9, $42, $00, $c0, $00, $b9, $56
    db $00, $c0, $00, $b9, $83, $00, $c0, $00, $b9, $97, $00, $c0, $00, $bd, $32, $00
    db $42, $00, $bd, $36, $00, $42, $00, $bd, $3e, $00, $42, $00, $bd, $41, $00, $42
    db $00, $bd, $43, $00, $42, $00, $bd, $44, $00, $42, $00, $bd, $42, $00, $c1, $00
    db $94, $59, $00, $99, $00, $59, $94, $00, $99, $00, $c7, $97, $00, $9a, $00, $97
    db $c7, $00, $9a, $00, $ad, $22, $00, $c8, $00, $ad, $25, $00, $c8, $00, $aa, $12
    db $00, $ca, $00, $99, $6c, $00, $cb, $00, $ca, $29, $00, $cc, $00, $c8, $cb, $00
    db $cd, $00, $c9, $cb, $00, $cd, $00, $9a, $2c, $00, $ce, $00, $ce, $42, $00, $cf
    db $00, $cf, $13, $00, $d0, $00, $d0, $24, $00, $d1, $00, $cc, $43, $00, $d2, $00
    db $cd, $d0, $00, $d3, $00, $cd, $d1, $00, $d3, $00, $d0, $cd, $00, $d3, $00, $d1
    db $cd, $00, $d3, $00, $d3, $80, $00, $d4, $00, $d4, $d2, $00, $d5, $00, $d5, $6d
    db $00, $d6, $00, $17, $f2, $00, $1e, $00, $3a, $f1, $00, $32, $00, $3b, $f1, $00
    db $32, $00, $41, $f1, $00, $32, $00, $45, $f1, $00, $32, $00, $2e, $f1, $00, $40
    db $00, $36, $f1, $00, $41, $00, $2d, $f0, $00, $3e, $00, $32, $f0, $00, $3e, $00
    db $3a, $f0, $00, $3e, $00, $3b, $f0, $00, $3e, $00, $3f, $f0, $00, $3e, $00, $40
    db $f0, $00, $3e, $00, $41, $f0, $00, $3e, $00, $2f, $f3, $00, $34, $00, $3a, $f6
    db $00, $32, $00, $31, $f1, $00, $35, $00, $47, $f1, $00, $52, $00, $51, $f1, $00
    db $52, $00, $53, $f1, $00, $52, $00, $55, $f1, $00, $52, $00, $48, $f2, $00, $51
    db $00, $51, $f6, $00, $53, $00, $47, $f7, $00, $52, $00, $51, $f7, $00, $52, $00
    db $53, $f7, $00, $52, $00, $55, $f7, $00, $52, $00, $46, $f0, $00, $4e, $00, $5a
    db $f2, $00, $64, $00, $64, $f6, $00, $67, $00, $67, $f1, $00, $66, $00, $61, $f2
    db $00, $62, $00, $6e, $f0, $00, $76, $00, $74, $f0, $00, $7c, $00, $6f, $f2, $00
    db $7a, $00, $73, $f8, $00, $79, $00, $71, $f6, $00, $7b, $00, $7a, $f7, $00, $7e
    db $00, $7c, $f7, $00, $7e, $00, $72, $f4, $00, $78, $00, $7c, $f1, $00, $79, $00
    db $79, $f6, $00, $7f, $00, $82, $f0, $00, $8a, $00, $85, $f0, $00, $8a, $00, $87
    db $f0, $00, $8a, $00, $86, $f7, $00, $8c, $00, $8a, $f7, $00, $8c, $00, $8b, $f7
    db $00, $8c, $00, $88, $f1, $00, $84, $00, $89, $f1, $00, $84, $00, $8b, $f1, $00
    db $84, $00, $8c, $f1, $00, $84, $00, $88, $f2, $00, $93, $00, $89, $f2, $00, $93
    db $00, $8b, $f2, $00, $93, $00, $8c, $f2, $00, $93, $00, $88, $f7, $00, $96, $00
    db $89, $f7, $00, $96, $00, $8b, $f7, $00, $96, $00, $8c, $f7, $00, $96, $00, $83
    db $f1, $00, $97, $00, $83, $f8, $00, $98, $00, $83, $f7, $00, $8d, $00, $83, $f2
    db $00, $8e, $00, $91, $f1, $00, $90, $00, $91, $f8, $00, $98, $00, $91, $f7, $00
    db $83, $00, $91, $f2, $00, $97, $00, $90, $f1, $00, $83, $00, $90, $f8, $00, $98
    db $00, $90, $f2, $00, $97, $00, $90, $f7, $00, $91, $00, $9b, $f2, $00, $a3, $00
    db $9b, $f6, $00, $a8, $00, $a3, $f6, $00, $a8, $00, $a0, $f6, $00, $a5, $00, $a6
    db $f6, $00, $a5, $00, $9c, $f3, $00, $a6, $00, $a1, $f3, $00, $a6, $00, $a4, $f3
    db $00, $a6, $00, $a9, $f3, $00, $a6, $00, $ab, $f3, $00, $a6, $00, $ac, $f3, $00
    db $a6, $00, $9e, $f3, $00, $a7, $00, $aa, $f6, $00, $ad, $00, $9c, $f1, $00, $9c
    db $00, $a9, $f1, $00, $9c, $00, $aa, $f1, $00, $9c, $00, $ab, $f1, $00, $9c, $00
    db $ac, $f1, $00, $9c, $00, $a6, $f1, $00, $ac, $00, $af, $f0, $00, $b7, $00, $bd
    db $f1, $00, $b9, $00, $bf, $f6, $00, $be, $00, $c0, $f6, $00, $ba, $00, $c1, $f6
    db $00, $ba, $00, $b9, $f1, $00, $b9, $02, $bd, $f5, $00, $c6, $00, $bd, $f7, $00
    db $c2, $00, $bd, $f3, $00, $bc, $00, $f0, $30, $00, $09, $00, $f0, $58, $00, $09
    db $00, $f0, $ae, $00, $09, $00, $f0, $1a, $00, $06, $00, $f0, $7b, $00, $06, $00
    db $f0, $f9, $00, $0f, $02, $f0, $a1, $00, $0b, $00, $f0, $c4, $00, $0b, $00, $f0
    db $c5, $00, $0b, $00, $f0, $32, $00, $0a, $00, $f0, $41, $00, $0a, $00, $f0, $42
    db $00, $0a, $00, $f0, $43, $00, $0a, $00, $f0, $44, $00, $0a, $00, $f0, $b9, $00
    db $10, $00, $f0, $81, $00, $0b, $00, $f1, $f9, $00, $29, $00, $f1, $0e, $00, $25
    db $00, $f1, $0f, $00, $25, $00, $f1, $12, $00, $25, $00, $f1, $2a, $00, $25, $00
    db $f1, $3e, $00, $25, $00, $f1, $56, $00, $25, $00, $f1, $57, $00, $25, $00, $f1
    db $96, $00, $25, $00, $f1, $97, $00, $25, $00, $f1, $42, $00, $2a, $00, $f1, $90
    db $00, $2a, $00, $f1, $95, $00, $2a, $00, $f1, $98, $00, $2a, $00, $f1, $9c, $00
    db $9c, $00, $f1, $a9, $00, $9c, $00, $f1, $aa, $00, $9c, $00, $f1, $ad, $00, $9c
    db $00, $f1, $81, $00, $24, $00, $f2, $19, $00, $3f, $00, $f2, $b9, $00, $3a, $00
    db $f2, $bd, $00, $3a, $00, $f2, $c0, $00, $3a, $00, $f2, $c1, $00, $3a, $00, $f2
    db $c4, $00, $3a, $00, $f2, $c5, $00, $3a, $00, $f3, $00, $00, $55, $00, $f3, $32
    db $00, $55, $00, $f3, $37, $00, $55, $00, $f3, $3a, $00, $55, $00, $f3, $83, $00
    db $55, $00, $f3, $ae, $00, $55, $00, $f3, $c0, $00, $55, $00, $f3, $10, $00, $54
    db $00, $f3, $11, $00, $54, $00, $f3, $36, $00, $54, $00, $f3, $3b, $00, $54, $00
    db $f3, $3f, $00, $54, $00, $f3, $41, $00, $54, $00, $f3, $9c, $00, $54, $00, $f3
    db $a9, $00, $54, $00, $f3, $aa, $00, $54, $00, $f3, $ac, $00, $54, $00, $f3, $ad
    db $00, $54, $00, $f4, $0b, $00, $69, $00, $f4, $45, $00, $69, $00, $f4, $4a, $00
    db $69, $00, $f4, $71, $00, $69, $00, $f4, $7a, $00, $69, $00, $f4, $87, $00, $69
    db $00, $f4, $b5, $00, $69, $00, $f7, $1b, $00, $9c, $00, $f7, $1b, $00, $9c, $00
    db $f7, $1f, $00, $9c, $00, $f7, $22, $00, $9c, $00, $f7, $25, $00, $9c, $00, $f7
    db $29, $00, $9c, $00, $f7, $2a, $00, $9c, $00, $f7, $2c, $00, $9c, $00, $f7, $07
    db $00, $a4, $00, $f7, $0a, $00, $a4, $00, $f7, $2d, $00, $a4, $00, $f7, $3b, $00
    db $a4, $00, $f7, $58, $00, $a4, $00, $f7, $5a, $00, $a4, $00, $f7, $64, $00, $a4
    db $00, $f7, $74, $00, $a4, $00, $f7, $7c, $00, $a4, $00, $f8, $32, $00, $bd, $00
    db $f8, $3a, $00, $bd, $00, $f8, $41, $00, $bd, $00, $f8, $42, $00, $bd, $00, $f8
    db $7f, $00, $c5, $00, $f8, $81, $00, $c5, $00, $ff


label16_5b4e:
    ld a, [wInGateworld]
    or a
    ret z

    ld a, [$c8ea]
    bit 7, a
    ret nz

    ld hl, wCurrentFloor
    inc [hl]
    xor a
    ld [$c93e], a
    ld a, [wInGateworld]
    bit 7, a
    jr nz, jr_016_5b72

    ld a, [wMapID]
    ld [wGateID], a
    xor a
    ld [wCurrentFloor], a

jr_016_5b72:
    ld hl, $010c
    rst $10
    ld a, [wGateID]
    add a
    add a
    add a
    ld hl, GateFloorDataTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wFloorType1], a
    ld a, [hl+]
    ld [wFloorType2], a
    ld a, [hl+]
    ld [wFloorType3], a
    push hl
    ld a, [hl+]
    ld [wLastFloor], a
    ld a, [hl+]
    ld [wBossMapType], a
    inc hl
    inc hl
    ld a, [hl]
    ld [wBossTileset], a
    pop hl
    ld a, [wCurrentFloor]
    ld b, a
    inc a
    cp [hl]
    jr z, jr_016_5be1

    ld a, [wGateID]
    or a
    jr z, jr_016_5bbf

    ld a, [wRNG1]
    bit 4, a
    jr z, jr_016_5bbf

    ld a, $03
    call Div8x8
    cp $02
    jr z, jr_016_5c1c

jr_016_5bbf:
    ld a, [wFloorType1]
    add a
    add a
    add a
    add a
    ld hl, FloorTypeSelectionTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call SelectFloorType
    ld [wFloorType1], a
    ld a, [wFloorType1]
    ld [wMapID], a
    ld a, $01
    ld [wInGateworld], a
    ret


jr_016_5be1:
    ld a, [wGateID]
    add a
    add a
    add a
    ld hl, GateFloorDataTable + 4
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld a, [hl+]
    swap a
    ld b, a
    and $f0
    or $08
    ld [wWarpSpawnXLo], a
    ld a, b
    and $0f
    ld [wWarpSpawnXHi], a
    ld a, [hl+]
    swap a
    ld b, a
    and $f0
    or $08
    ld [wWarpSpawnYLo], a
    ld a, b
    and $0f
    ld [wWarpSpawnYHi], a
    ret


jr_016_5c1c:
    ld a, [wFloorType2]
    add a
    add a
    add a
    ld hl, FloorTypeSelectionTable2
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call SelectFloorType
    ld [wFloorType2], a
    rst $00
    ld b, d
    ld e, h
    cp c
    ld e, h
    bit 3, h
    db $ec
    ld e, h
    dec c
    ld e, l
    ld l, $5d
    ret c

    ld e, [hl]
    ld c, h
    ld e, a
    call Call_016_6db0

Call_016_5c45:
    ld a, [wRNG1]
    ld b, a
    ld a, $03
    call Div8x8
    cp $01
    jr z, jr_016_5c77

    cp $02
    jr z, jr_016_5c98

    ld a, $5a
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5c77:
    ld a, $5b
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5c98:
    ld a, $5c
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0068
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


    ld hl, $d9cf
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    call Call_016_6ddb
    call Call_016_5c45
    ret


    ld a, $53
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0068
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


    ld a, $51
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0068
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


    ld a, $50
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0068
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


    xor a
    ld [$d9cf], a
    ld [$d9d0], a
    call Call_016_5e38
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [$d9d1], a
    ld a, h
    ld [$d9d2], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [$d9d3], a
    ld a, h
    ld [$d9d4], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [$d9d5], a
    ld a, h
    ld [$d9d6], a
    call Call_016_5e38
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [$d9d9], a
    ld a, h
    ld [$d9da], a
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [$d9db], a
    ld a, h
    ld [$d9dc], a
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [$d9dd], a
    ld a, h
    ld [$d9de], a
    call Call_016_5e38
    ld hl, $d7ca
    call Call_016_5dc6
    ld a, $52
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0068
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    xor a
    ld [wColiseumBattle], a
    ret


Call_016_5dc6:
    push hl
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl+], a
    ld a, $ff
    ld [hl+], a
    xor a
    ld [hl], a
    pop hl
    push hl
    ld a, [wTempEnemyId1]
    ld l, a
    ld a, [$da04]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call Call_016_5e2e
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, [$da02]
    or a
    ret z

    push hl
    ld a, [$da05]
    ld l, a
    ld a, [$da06]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call Call_016_5e2e
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ld a, [$da02]
    cp $01
    ret z

    push hl
    ld a, [$da07]
    ld l, a
    ld a, [$da08]
    ld h, a
    ld a, l
    ld [wTempEnemyStatsId], a
    ld a, h
    ld [$da13], a
    call Call_016_5e2e
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ret


Call_016_5e2e:
    ld hl, $1401
    rst $10
    ld a, [$da18]
    add $10
    ret


Call_016_5e38:
    ld hl, $0000
    ld c, $00
    ld a, [$ca8e]
    call Call_016_5e91
    ld a, [$ca8f]
    call Call_016_5e91
    ld a, [$ca90]
    call Call_016_5e91
    ld a, c
    call Div16x8To16
    ld a, l
    ld hl, $0209
    cp $04
    jr c, jr_016_5ea7

    ld hl, $0d12
    cp $0a
    jr c, jr_016_5ea7

    ld hl, $2112
    cp $10
    jr c, jr_016_5ea7

    ld hl, $3912
    cp $16
    jr c, jr_016_5ea7

    ld hl, $5112
    cp $1c
    jr c, jr_016_5ea7

    ld hl, $6912
    cp $22
    jr c, jr_016_5ea7

    ld hl, $8112
    cp $28
    jr c, jr_016_5ea7

    ld hl, $9d12
    cp $2e
    jr c, jr_016_5ea7

    ld hl, $b512
    jr jr_016_5ea7

Call_016_5e91:
    cp $ff
    ret z

    push bc
    push hl
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    pop hl
    pop bc
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    inc c
    ret


jr_016_5ea7:
    ld a, $02
    ld [$da02], a
    call Call_016_5ec9
    ld [wTempEnemyId1], a
    call Call_016_5ec9
    ld [$da05], a
    call Call_016_5ec9
    ld [$da07], a
    xor a
    ld [$da04], a
    ld [$da06], a
    ld [$da08], a
    ret


Call_016_5ec9:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, l
    call Div8x8
    pop hl
    add h
    ret


    ld a, [wRNG1]
    ld b, a
    ld a, $03
    call Div8x8
    cp $01
    jr z, jr_016_5f0a

    cp $02
    jr z, jr_016_5f2b

    ld a, $57
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $00f8
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $00b8
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5f0a:
    ld a, $58
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0018
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0028
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5f2b:
    ld a, $59
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0018
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0028
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


    ld a, [wRNG1]
    ld b, a
    ld a, $03
    call Div8x8
    cp $01
    jr z, jr_016_5f7e

    cp $02
    jr z, jr_016_5f9f

    ld a, $54
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $00d8
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $00d8
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5f7e:
    ld a, $55
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $0048
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $0168
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


jr_016_5f9f:
    ld a, $56
    ld [wMapID], a
    ld a, $00
    ld [wInGateworld], a
    ld hl, $00e8
    ld a, l
    ld [wWarpSpawnXLo], a
    ld a, h
    ld [wWarpSpawnXHi], a
    ld hl, $00b8
    ld a, l
    ld [wWarpSpawnYLo], a
    ld a, h
    ld [wWarpSpawnYHi], a
    ret


SelectFloorType:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    pop hl
    ld c, a
    ld b, $ff

jr_016_5fd5:
    ld a, [hl]
    inc b
    inc hl
    or a
    jr z, jr_016_5fd5

    cp $64
    jr z, jr_016_5fe2

    cp c
    jr c, jr_016_5fd5

jr_016_5fe2:
    ld a, b
    ret


label16_5fe4:
    call SetRandomEncounterCounter
    ld a, [wInGateworld]
    or a
    jr nz, jr_016_6002

    ld a, $ff
    ld [$c926], a
    xor a
    ld [$c92b], a
    ld [$c92c], a
    xor a
    ld [$c92d], a
    xor a
    ld [$c92e], a
    ret


jr_016_6002:
    ld de, $2e15
    ld hl, $8500
    call WaitDMATransfer
    ld de, $2e16
    ld hl, $8540
    call WaitDMATransfer
    ld de, $2e17
    ld hl, $8580
    call WaitDMATransfer
    ld de, $2e18
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
    ld a, [$c8ea]
    bit 7, a
    jr z, label16_605b

    xor a
    ld [$c8ec], a
    ret

    db $00, $00, $00, $01, $02

label16_605b:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Div8x8
    ld hl, $6056
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [$c93f], a
    ld hl, $c950
    ld bc, $0010
    xor a
    call FillNBytesWithRegA
    ld hl, $c940
    ld bc, $0010
    ld a, $ff
    call FillNBytesWithRegA
    ld a, [$c93f]
    cp $02
    jr nz, jr_016_60b9

    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $15
    call Div8x8
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld a, l
    add $36
    ld l, a
    ld a, h
    adc $77
    ld h, a
    ld de, $c940
    ld b, $10

jr_016_60b0:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_016_60b0

    jp Jump_016_616c


jr_016_60b9:
    ld hl, $7096
    ld a, [$c93d]
    inc a
    ld b, a
    push hl
    ld a, [hl]
    ld c, a
    push bc
    ld a, b
    cp $09
    ld bc, $0000
    jr nc, jr_016_60d8

    ld a, [wRNG1]
    ld b, a

jr_016_60d1:
    inc b
    ld a, b
    and $05
    jr z, jr_016_60d1

    ld b, a

jr_016_60d8:
    push bc
    call Call_016_6800
    pop bc
    cp $0f
    jr z, jr_016_60d8

    pop bc
    push af
    ld a, c
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    ld [hl], a
    pop hl
    inc hl
    dec b

jr_016_60f2:
    push hl
    ld a, [hl]
    ld c, a
    push bc
    call Call_016_6744
    ld a, b
    or a
    ld a, $ff
    jr z, jr_016_6102

    call Call_016_6800

jr_016_6102:
    pop bc
    push af
    ld a, c
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    ld [hl], a
    pop hl
    inc hl
    dec b
    jr nz, jr_016_60f2

    ld hl, $7096
    ld b, $10

jr_016_611a:
    push hl
    ld a, [hl]
    cp $ff
    jr z, jr_016_6140

    ld c, a
    push bc
    call Call_016_6744
    ld a, b
    or a
    ld a, $0f
    jr z, jr_016_6132

    ld a, b
    xor $0f
    ld c, a
    call Call_016_6800

jr_016_6132:
    pop bc
    push af
    ld a, c
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    ld [hl], a

jr_016_6140:
    pop hl
    inc hl
    dec b
    jr nz, jr_016_611a

    ld hl, $c940
    ld b, $10

jr_016_614a:
    push bc
    push hl
    ld c, $0c
    ld a, [$c93f]
    cp $01
    jr z, jr_016_6162

    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $0c
    call Div8x8
    ld c, a

jr_016_6162:
    pop hl
    ld a, [hl]
    swap a
    add c
    ld [hl+], a
    pop bc
    dec b
    jr nz, jr_016_614a

Jump_016_616c:
    ld a, $40
    ld [$c0a9], a

jr_016_6171:
    ld a, [$c0a9]
    dec a
    ld [$c0a9], a
    jp z, $605b

    call Call_016_66ae
    ld a, [wScreenIndex]
    ld [$c960], a
    ldh a, [$a5]
    ld [$c0a5], a
    ldh a, [$a6]
    ld [$c0a6], a
    ldh a, [$a7]
    ld [$c0a7], a
    ldh a, [$a8]
    ld [$c0a8], a
    call Call_016_6afb
    jr z, jr_016_6171

    ld a, [$c0a7]
    ld [$c966], a
    and $f0
    ld l, a
    ld a, [$c0a8]
    ld [$c967], a
    sla l
    rla
    sla l
    rla
    ld h, a
    ld a, [$c0a6]
    ld [$c965], a
    ld d, a
    ld a, [$c0a5]
    ld [$c964], a
    srl d
    rra
    srl d
    rra
    srl d
    rra
    and $1e
    ld e, a
    ld d, $00
    add hl, de
    ld a, l
    ld [$c962], a
    ld a, h
    ld [$c963], a
    ld a, [$c960]
    add a
    add a
    ld hl, $2da7
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [$c964]
    add [hl]
    ld [$c964], a
    inc hl
    ld a, [$c965]
    adc [hl]
    ld [$c965], a
    inc hl
    ld a, [$c966]
    add [hl]
    ld [$c966], a
    inc hl
    ld a, [$c967]
    adc [hl]
    ld [$c967], a
    inc hl
    ld a, $40
    ld [$c0a9], a

jr_016_620a:
    ld a, [$c0a9]
    dec a
    ld [$c0a9], a
    jp z, $605b

    call Call_016_6585
    ld a, [$c960]
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, jr_016_620a

    ld a, [wScreenIndex]
    ld [$c926], a
    add a
    add a
    ld hl, $2da7
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [$c927], a
    ld a, [hl+]
    ld [$c928], a
    ld a, [hl+]
    ld [$c929], a
    ld a, [hl+]
    ld [$c92a], a
    ld hl, $c927
    ldh a, [$a5]
    add [hl]
    ld [hl+], a
    ldh a, [$a6]
    adc [hl]
    ld [hl], a
    ld hl, $c929
    ldh a, [$a7]
    add [hl]
    ld [hl+], a
    ldh a, [$a8]
    adc [hl]
    ld [hl], a
    ld a, [$cab4]
    or a
    jr z, jr_016_6262

    cp $01
    jr nz, jr_016_6266

jr_016_6262:
    xor a
    ld [$c92d], a

jr_016_6266:
    ld a, [$c92d]
    ld [$c92b], a
    cp $04
    jr z, jr_016_627e

    cp $05
    jr z, jr_016_627e

    cp $06
    jr z, jr_016_627e

    cp $07
    jr z, jr_016_627e

    jr jr_016_628a

jr_016_627e:
    call GenerateRNG
    ld a, [wRNG1]
    bit 0, a
    jr z, jr_016_62cf

    jr jr_016_629f

jr_016_628a:
    call GenerateRNG
    ld a, [wFloorType3]
    ld hl, $7886
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [wRNG1]
    cp [hl]
    jr c, jr_016_62b5

jr_016_629f:
    xor a
    ld [$c92b], a
    ld [$c92c], a
    xor a
    ld [$c92d], a
    xor a
    ld [$c92e], a
    ld a, $ff
    ld [$c926], a
    jr jr_016_62cf

jr_016_62b5:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Div8x8
    ld [$c92c], a
    call GenerateRNG
    ld a, [wRNG1]
    and $03
    ld [$c92b], a

jr_016_62cf:
    xor a
    ld [$c92d], a
    ld a, $40
    ld [$c0a9], a

Jump_016_62d8:
jr_016_62d8:
    ld a, [$c0a9]
    dec a
    ld [$c0a9], a
    jp z, $605b

    call Call_016_661b
    ld hl, $c960
    ld a, [wScreenIndex]
    cp [hl]
    jr nz, jr_016_62f1

    call Call_016_661b

jr_016_62f1:
    ld a, [wScreenIndex]
    ld [$c0af], a
    call Call_016_68c6
    jp z, Jump_016_62d8

    ld a, [$c926]
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, jr_016_62d8

    ld a, [wScreenIndex]
    ld [$c0a0], a
    add a
    add a
    ld hl, $2da7
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld [wWarpSpawnXLo], a
    ld a, [hl+]
    ld [wWarpSpawnXHi], a
    ld a, [hl+]
    ld [wWarpSpawnYLo], a
    ld a, [hl+]
    ld [wWarpSpawnYHi], a
    ldh a, [$a5]
    ld [$c0a1], a
    ldh a, [$a6]
    ld [$c0a2], a
    ldh a, [$a7]
    ld [$c0a3], a
    ldh a, [$a8]
    ld [$c0a4], a
    ld hl, wWarpSpawnXLo
    ldh a, [$a5]
    add [hl]
    ld [hl+], a
    ldh a, [$a6]
    adc [hl]
    ld [hl], a
    ld hl, wWarpSpawnYLo
    ldh a, [$a7]
    add [hl]
    ld [hl+], a
    ldh a, [$a8]
    adc [hl]
    ld [hl], a
    ld hl, $c100
    ld bc, $0010
    xor a
    call FillNBytesWithRegA
    ld a, [wFloorType3]
    ld hl, $732f
    add a
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    push af
    ld a, [wRNG1]
    ld b, a
    ld a, [hl+]
    inc a
    push hl
    call Div8x8
    pop hl
    ld b, a
    pop af
    add b
    ld b, a
    ld c, [hl]
    push bc
    ld hl, $c940
    ld b, $10
    ld c, $00

jr_016_6386:
    ld a, [hl+]
    and $f0
    cp $f0
    jr z, jr_016_638e

    inc c

jr_016_638e:
    dec b
    jr nz, jr_016_6386

    ld a, c
    pop bc
    cp $06
    jr nc, jr_016_639b

    srl b
    res 7, b

jr_016_639b:
    ld hl, $d793
    ld a, b
    or a
    jr z, jr_016_63ac

jr_016_63a2:
    push bc
    ld [hl], $ff
    call Call_016_6432
    pop bc
    dec b
    jr nz, jr_016_63a2

jr_016_63ac:
    ld [hl], $ff
    ret


Call_016_63af:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a

jr_016_63b6:
    inc b
    ld a, b
    and $0f
    ld [wScreenIndex], a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_016_63b6

    ld hl, $0b08
    rst $10
    ld hl, $c300
    call WaitLCDTransfer
    xor a
    ldh [$b7], a
    ldh [$b8], a
    xor a
    ldh [$bb], a
    ldh [$bc], a

jr_016_63e1:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $08
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $06
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call WaitInputRelease
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    jr jr_016_63e1

Call_016_6432:
    push hl
    ld a, $10
    ld [$c0a9], a
    push bc
    ld a, [wFloorType3]
    ld hl, FloorTypeSelectionTable3
    add a
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call SelectFloorType
    ld [$c0ae], a
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $64
    call Div16x8To16
    pop bc
    cp c
    jr z, jr_016_646d

    jr nc, jr_016_646d

    ld a, [$c0ae]
    add $10
    ld [$c0ae], a

Jump_016_646d:
jr_016_646d:
    ld a, [$c0a9]
    dec a
    ld [$c0a9], a
    jr nz, jr_016_6478

    pop hl
    ret


jr_016_6478:
    call Call_016_63af
    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c960]
    cp b
    jr nz, jr_016_6488

    call Call_016_63af

jr_016_6488:
    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c0af]
    cp b
    jr nz, jr_016_6495

    call Call_016_63af

jr_016_6495:
    ld a, [wScreenIndex]
    ld hl, $c100
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    or a
    jr z, jr_016_64a8

    call Call_016_63af

jr_016_64a8:
    ldh a, [$a5]
    ld [$c0aa], a
    ldh a, [$a6]
    ld [$c0ab], a
    ldh a, [$a7]
    ld [$c0ac], a
    ldh a, [$a8]
    ld [$c0ad], a
    call Call_016_6955
    jr z, jr_016_646d

    ld a, [$c0aa]
    ldh [$a5], a
    ld a, [$c0ab]
    ldh [$a6], a
    ld a, [$c0ac]
    ldh [$a7], a
    ld a, [$c0ad]
    ldh [$a8], a
    call Call_016_68c6
    jr z, jr_016_646d

    call Call_016_68ea
    jr z, jr_016_646d

    call Call_016_690e
    jr z, jr_016_646d

    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c926]
    cp b
    jp z, Jump_016_646d

    ld a, [wScreenIndex]
    ld hl, $c100
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $03
    jp z, Jump_016_646d

    inc [hl]
    ld a, [wScreenIndex]
    add a
    add a
    ld hl, $2da7
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ldh [$db], a
    ld a, [hl+]
    ldh [$dc], a
    ld a, [hl+]
    ldh [$dd], a
    ld a, [hl+]
    ldh [$de], a
    ld hl, $ffdb
    ldh a, [$a5]
    add [hl]
    ld [hl+], a
    ldh a, [$a6]
    adc [hl]
    ld [hl], a
    ld hl, $ffdd
    ldh a, [$a7]
    add [hl]
    ld [hl+], a
    ldh a, [$a8]
    adc [hl]
    ld [hl], a
    pop hl
    ld a, [$c0ae]
    ld [hl+], a
    push hl
    ld a, [$c0ae]
    and $0f
    ld hl, $7426
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $01
    jr nz, jr_016_6564

    ld a, [wFloorType3]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld e, l
    ld d, h
    add hl, hl
    add hl, de
    ld a, l
    add $36
    ld l, a
    ld a, h
    adc $74
    ld h, a
    call SelectFloorType

jr_016_6564:
    pop hl
    ld [hl+], a
    ldh a, [$db]
    swap a
    and $0f
    ld b, a
    ldh a, [$dc]
    swap a
    and $f0
    or b
    ld [hl+], a
    ldh a, [$dd]
    swap a
    and $0f
    ld b, a
    ldh a, [$de]
    swap a
    and $f0
    or b
    ld [hl+], a
    ret


Call_016_6585:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a

Jump_016_658c:
jr_016_658c:
    inc b
    ld a, b
    and $0f
    ld [wScreenIndex], a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_016_658c

    ld hl, $0b08
    rst $10
    ld hl, $c300
    call WaitLCDTransfer
    xor a
    ldh [$b7], a
    ldh [$b8], a
    xor a
    ldh [$bb], a
    ldh [$bc], a
    ld a, $40
    ldh [$d5], a

jr_016_65bb:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $08
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $06
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call WaitInputRelease
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    cp $0e
    ret z

    ldh a, [$d5]
    dec a
    ldh [$d5], a
    jr nz, jr_016_65bb

    ld a, [wScreenIndex]
    ld b, a
    jp Jump_016_658c


Call_016_661b:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a

Jump_016_6622:
jr_016_6622:
    inc b
    ld a, b
    and $0f
    ld [wScreenIndex], a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_016_6622

    ld hl, $0b08
    rst $10
    ld hl, $c300
    call WaitLCDTransfer
    xor a
    ldh [$b7], a
    ldh [$b8], a
    xor a
    ldh [$bb], a
    ldh [$bc], a
    ld a, $40
    ldh [$d5], a

jr_016_6651:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $08
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $06
    call Div8x8
    add $01
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call WaitInputRelease
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    ldh a, [$d5]
    dec a
    ldh [$d5], a
    jr nz, jr_016_6651

    ld a, [wScreenIndex]
    ld b, a
    jp Jump_016_6622


Call_016_66ae:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a

Jump_016_66b5:
jr_016_66b5:
    inc b
    ld a, b
    and $0f
    ld [wScreenIndex], a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and $f0
    cp $f0
    jr z, jr_016_66b5

    ld hl, $0b08
    rst $10
    ld hl, $c300
    call WaitLCDTransfer
    xor a
    ldh [$b7], a
    ldh [$b8], a
    xor a
    ldh [$bb], a
    ldh [$bc], a
    ld a, $40
    ldh [$d5], a

jr_016_66e4:
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $06
    call Div8x8
    add $02
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $04
    call Div8x8
    add $02
    swap a
    ld h, a
    and $f0
    or $08
    ld l, a
    ld a, h
    and $0f
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call WaitInputRelease
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    cp $0e
    ret z

    ldh a, [$d5]
    dec a
    ldh [$d5], a
    jr nz, jr_016_66e4

    ld a, [wScreenIndex]
    ld b, a
    jp Jump_016_66b5


Call_016_6744:
    ld bc, $0000
    ld d, a
    sub $04
    jr c, jr_016_676f

    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_016_6773

    add a
    add a
    ld hl, $7055
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 2, [hl]
    jr z, jr_016_676f

    ld a, $08
    or b
    ld b, a
    jr jr_016_6773

jr_016_676f:
    ld a, $08
    or c
    ld c, a

jr_016_6773:
    ld a, d
    add $04
    cp $10
    jr nc, jr_016_679d

    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_016_67a1

    add a
    add a
    ld hl, $7055
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 3, [hl]
    jr z, jr_016_679d

    ld a, $04
    or b
    ld b, a
    jr jr_016_67a1

jr_016_679d:
    ld a, $04
    or c
    ld c, a

jr_016_67a1:
    ld a, d
    and $03
    jr z, jr_016_67cb

    ld a, d
    dec a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_016_67cf

    add a
    add a
    ld hl, $7055
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 0, [hl]
    jr z, jr_016_67cb

    ld a, $02
    or b
    ld b, a
    jr jr_016_67cf

jr_016_67cb:
    ld a, $02
    or c
    ld c, a

jr_016_67cf:
    ld a, d
    and $03
    cp $03
    jr z, jr_016_67fb

    ld a, d
    inc a
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, jr_016_67ff

    add a
    add a
    ld hl, $7055
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 1, [hl]
    jr z, jr_016_67fb

    ld a, $01
    or b
    ld b, a
    jr jr_016_67ff

jr_016_67fb:
    ld a, $01
    or c
    ld c, a

jr_016_67ff:
    ret


Call_016_6800:
    ld de, $c500
    ld hl, $7055

jr_016_6806:
    ld a, [hl]
    cp $ff
    jr z, jr_016_6826

    and c
    jr nz, jr_016_681c

    ld a, [hl]
    and b
    cp b
    jr nz, jr_016_681c

    push hl
    inc hl
    ld a, [hl+]
    ld [de], a
    inc de
    ld a, [hl]
    ld [de], a
    inc de
    pop hl

jr_016_681c:
    ld a, l
    add $04
    ld l, a
    ld a, h
    adc $00
    ld h, a
    jr jr_016_6806

jr_016_6826:
    ld [de], a
    inc de
    ld [de], a
    ld hl, $c0a0
    ld bc, $0005
    ld a, $00
    call FillNBytesWithRegA
    ld hl, $c501

jr_016_6837:
    ld a, [hl+]
    cp $ff
    jr z, jr_016_684b

    inc hl
    ld de, $c0a0
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    inc a
    ld [de], a
    jr jr_016_6837

jr_016_684b:
    xor a
    ld [$c0a0], a
    ld a, [$c0a1]
    ld b, $14
    call Div8x8
    ld a, b
    ld [$c0a1], a
    ld a, [$c0a2]
    ld b, $28
    call Div8x8
    ld a, b
    ld [$c0a2], a
    ld a, [$c0a3]
    ld b, $3c
    call Div8x8
    ld a, b
    ld [$c0a3], a
    ld a, [$c0a4]
    ld b, $50
    call Div8x8
    ld a, b
    ld [$c0a4], a
    ld hl, $c501
    ld b, $00

jr_016_6884:
    ld a, [hl]
    cp $ff
    jr z, jr_016_689a

    ld de, $c0a0
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    add b
    ld b, a
    ld [hl], a
    inc hl
    inc hl
    jr jr_016_6884

jr_016_689a:
    push bc
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    pop af
    or a
    jr z, jr_016_68ad

    call Div16x8To16

jr_016_68ad:
    ld b, a
    ld hl, $c501

jr_016_68b1:
    ld a, [hl]
    cp $ff
    jr nz, jr_016_68ba

    ld a, $0f
    jr jr_016_68c5

jr_016_68ba:
    cp b
    jr c, jr_016_68c1

    dec hl
    ld a, [hl]
    jr jr_016_68c5

jr_016_68c1:
    inc hl
    inc hl
    jr jr_016_68b1

jr_016_68c5:
    ret


Call_016_68c6:
    ld hl, $c960
    ld a, [wScreenIndex]
    cp [hl]
    ret nz

    ld hl, $ffa5
    ld a, [$c0a5]
    cp [hl]
    ret nz

    inc hl
    ld a, [$c0a6]
    cp [hl]
    ret nz

    ld hl, $ffa7
    ld a, [$c0a7]
    cp [hl]
    ret nz

    inc hl
    ld a, [$c0a8]
    cp [hl]
    ret


Call_016_68ea:
    ld hl, $c0a0
    ld a, [wScreenIndex]
    cp [hl]
    ret nz

    ld hl, $ffa5
    ld a, [$c0a1]
    cp [hl]
    ret nz

    inc hl
    ld a, [$c0a2]
    cp [hl]
    ret nz

    ld hl, $ffa7
    ld a, [$c0a3]
    cp [hl]
    ret nz

    inc hl
    ld a, [$c0a4]
    cp [hl]
    ret


Call_016_690e:
    ld hl, $d793

jr_016_6911:
    ld a, [hl]
    cp $ff
    jr nz, jr_016_6918

    or a
    ret


jr_016_6918:
    push hl
    call Call_016_6924
    pop hl
    ret z

    inc hl
    inc hl
    inc hl
    inc hl
    jr jr_016_6911

Call_016_6924:
    inc hl
    inc hl
    ld b, [hl]
    inc hl
    push hl
    ld a, $0a
    call Div8x8
    ld a, b
    ldh [$da], a
    pop hl
    ld a, [hl]
    and $f8
    srl a
    ld b, a
    ldh a, [$da]
    add b
    ldh [$da], a
    ld a, [hl]
    and $07
    swap a
    or $08
    ldh [$db], a
    ld hl, $ffda
    ld a, [wScreenIndex]
    cp [hl]
    ret nz

    ld hl, $ffa7
    ldh a, [$db]
    cp [hl]
    ret


Call_016_6955:
    ld a, [$c0ae]
    and $f0
    jp z, Jump_016_6d93

    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b0], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b1], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b2], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b3], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b4], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b5], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b6], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b7], a
    ld a, [$c0aa]
    ld l, a
    ld a, [$c0ab]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0ac]
    ld l, a
    ld a, [$c0ad]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b8], a
    jp Jump_016_6c96


Call_016_6afb:
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b0], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b1], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b2], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b3], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b4], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b5], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $f0
    ld l, a
    ld a, h
    adc $ff
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b6], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b7], a
    ld a, [$c0a5]
    ld l, a
    ld a, [$c0a6]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a5], a
    ld a, h
    ldh [$a6], a
    ld a, [$c0a7]
    ld l, a
    ld a, [$c0a8]
    ld h, a
    ld a, l
    add $10
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, l
    ldh [$a7], a
    ld a, h
    ldh [$a8], a
    call Call_016_6d99
    ld a, b
    ld [$c0b8], a

Jump_016_6c96:
    ld a, [$c0b3]
    or a
    jr z, jr_016_6cb1

    ld a, [$c0b2]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b5]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b8]
    or a
    jp nz, Jump_016_6d97

jr_016_6cb1:
    ld a, [$c0b7]
    or a
    jr z, jr_016_6ccc

    ld a, [$c0b0]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b1]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b2]
    or a
    jp nz, Jump_016_6d97

jr_016_6ccc:
    ld a, [$c0b1]
    or a
    jr z, jr_016_6ce7

    ld a, [$c0b6]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b7]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b8]
    or a
    jp nz, Jump_016_6d97

jr_016_6ce7:
    ld a, [$c0b5]
    or a
    jr z, jr_016_6d02

    ld a, [$c0b0]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b3]
    or a
    jp nz, Jump_016_6d97

    ld a, [$c0b6]
    or a
    jp nz, Jump_016_6d97

jr_016_6d02:
    ld a, [$c0b0]
    or a
    jr z, jr_016_6d27

    ld a, [$c0b1]
    or a
    jr nz, jr_016_6d15

    ld a, [$c0b2]
    or a
    jp nz, Jump_016_6d97

jr_016_6d15:
    ld a, [$c0b3]
    or a
    jr nz, jr_016_6d21

    ld a, [$c0b6]
    or a
    jr nz, jr_016_6d97

jr_016_6d21:
    ld a, [$c0b8]
    or a
    jr nz, jr_016_6d97

jr_016_6d27:
    ld a, [$c0b2]
    or a
    jr z, jr_016_6d4b

    ld a, [$c0b1]
    or a
    jr nz, jr_016_6d39

    ld a, [$c0b0]
    or a
    jr nz, jr_016_6d97

jr_016_6d39:
    ld a, [$c0b5]
    or a
    jr nz, jr_016_6d45

    ld a, [$c0b8]
    or a
    jr nz, jr_016_6d97

jr_016_6d45:
    ld a, [$c0b6]
    or a
    jr nz, jr_016_6d97

jr_016_6d4b:
    ld a, [$c0b6]
    or a
    jr z, jr_016_6d6f

    ld a, [$c0b3]
    or a
    jr nz, jr_016_6d5d

    ld a, [$c0b0]
    or a
    jr nz, jr_016_6d97

jr_016_6d5d:
    ld a, [$c0b7]
    or a
    jr nz, jr_016_6d69

    ld a, [$c0b8]
    or a
    jr nz, jr_016_6d97

jr_016_6d69:
    ld a, [$c0b2]
    or a
    jr nz, jr_016_6d97

jr_016_6d6f:
    ld a, [$c0b8]
    or a
    jr z, jr_016_6d93

    ld a, [$c0b5]
    or a
    jr nz, jr_016_6d81

    ld a, [$c0b2]
    or a
    jr nz, jr_016_6d97

jr_016_6d81:
    ld a, [$c0b7]
    or a
    jr nz, jr_016_6d8d

    ld a, [$c0b6]
    or a
    jr nz, jr_016_6d97

jr_016_6d8d:
    ld a, [$c0b0]
    or a
    jr nz, jr_016_6d97

Jump_016_6d93:
jr_016_6d93:
    ld a, $01
    or a
    ret


Jump_016_6d97:
jr_016_6d97:
    xor a
    ret


Call_016_6d99:
    call WaitInputRelease
    ld b, $00
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    cp $0e
    ret z

    ld b, $01
    ret


Call_016_6db0:
    ld hl, $d9cf
    ld b, $08

jr_016_6db5:
    push bc
    push hl
    call Call_016_6dc1
    pop hl
    pop bc
    ld [hl+], a
    dec b
    jr nz, jr_016_6db5

    ret


Call_016_6dc1:
    ld a, [wFloorType3]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    ld e, l
    ld d, h
    add hl, hl
    add hl, de
    ld a, l
    add $36
    ld l, a
    ld a, h
    adc $74
    ld h, a
    call SelectFloorType
    ret


Call_016_6ddb:
    call GenerateRNG
    ld a, [wRNG1]
    and $03
    ld hl, $d9cf
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld de, $6e04
    push de
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    and $0f
    pop hl
    pop de
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    ld a, [de]
    ld [hl], a
    ret

    db $03, $04, $06, $0c, $15, $17, $18, $19, $1a, $1b, $1c, $25, $1a, $1b, $1c, $25

SetRandomEncounterCounter:
    call GenerateRNG
    ld a, [wRNG1]
    ld l, a
    ld a, [wRNG2]
    ld h, a
    ld a, $65
    call Div16x8To16
    ld hl, RandomEncounterCounterTable

jr_016_6e27:
    cp [hl]
    jr z, jr_016_6e32

    jr c, jr_016_6e32

    inc hl
    inc hl
    inc hl
    inc hl
    jr jr_016_6e27

jr_016_6e32:
    inc hl
    inc hl
    ld a, [hl+]
    ld [wEncounterCounterLo], a
    ld a, [hl+]
    ld [wEncounterCounterHi], a
    ret


; ---------------------------------------------------------------
; RandomEncounterCounterTable — 50 entries × 4 bytes
; After PRNG mod 101, the result selects a step counter before
; the next random encounter. Format per entry:
;   byte 0: PRN threshold (if PRNG result <= this, select entry)
;   byte 1: $00 (padding)
;   bytes 2-3: step counter (little-endian 16-bit)
; Last entry uses $FF threshold as catch-all.
; ---------------------------------------------------------------
RandomEncounterCounterTable:
    db $02, $00, $4c, $04 ;  3/101 chance → 1,100 steps
    db $04, $00, $b0, $04 ;  2/101 chance → 1,200 steps
    db $06, $00, $14, $05 ;  2/101 chance → 1,300 steps
    db $08, $00, $78, $05 ;  2/101 chance → 1,400 steps
    db $0a, $00, $dc, $05 ;  2/101 chance → 1,500 steps
    db $0c, $00, $40, $06 ;  2/101 chance → 1,600 steps
    db $0e, $00, $a4, $06 ;  2/101 chance → 1,700 steps
    db $10, $00, $08, $07 ;  2/101 chance → 1,800 steps
    db $12, $00, $6c, $07 ;  2/101 chance → 1,900 steps
    db $14, $00, $d0, $07 ;  2/101 chance → 2,000 steps
    db $16, $00, $34, $08 ;  2/101 chance → 2,100 steps
    db $18, $00, $98, $08 ;  2/101 chance → 2,200 steps
    db $1a, $00, $fc, $08 ;  2/101 chance → 2,300 steps
    db $1c, $00, $60, $09 ;  2/101 chance → 2,400 steps
    db $1e, $00, $c4, $09 ;  2/101 chance → 2,500 steps
    db $20, $00, $28, $0a ;  2/101 chance → 2,600 steps
    db $22, $00, $8c, $0a ;  2/101 chance → 2,700 steps
    db $24, $00, $f0, $0a ;  2/101 chance → 2,800 steps
    db $26, $00, $54, $0b ;  2/101 chance → 2,900 steps
    db $28, $00, $b8, $0b ;  2/101 chance → 3,000 steps
    db $2a, $00, $1c, $0c ;  2/101 chance → 3,100 steps
    db $2c, $00, $80, $0c ;  2/101 chance → 3,200 steps
    db $2e, $00, $e4, $0c ;  2/101 chance → 3,300 steps
    db $30, $00, $48, $0d ;  2/101 chance → 3,400 steps
    db $32, $00, $ac, $0d ;  2/101 chance → 3,500 steps
    db $34, $00, $10, $0e ;  2/101 chance → 3,600 steps
    db $36, $00, $74, $0e ;  2/101 chance → 3,700 steps
    db $38, $00, $d8, $0e ;  2/101 chance → 3,800 steps
    db $3a, $00, $3c, $0f ;  2/101 chance → 3,900 steps
    db $3c, $00, $a0, $0f ;  2/101 chance → 4,000 steps
    db $3e, $00, $04, $10 ;  2/101 chance → 4,100 steps
    db $40, $00, $68, $10 ;  2/101 chance → 4,200 steps
    db $42, $00, $cc, $10 ;  2/101 chance → 4,300 steps
    db $44, $00, $30, $11 ;  2/101 chance → 4,400 steps
    db $46, $00, $94, $11 ;  2/101 chance → 4,500 steps
    db $48, $00, $f8, $11 ;  2/101 chance → 4,600 steps
    db $4a, $00, $5c, $12 ;  2/101 chance → 4,700 steps
    db $4c, $00, $c0, $12 ;  2/101 chance → 4,800 steps
    db $4e, $00, $24, $13 ;  2/101 chance → 4,900 steps
    db $50, $00, $88, $13 ;  2/101 chance → 5,000 steps
    db $52, $00, $ec, $13 ;  2/101 chance → 5,100 steps
    db $54, $00, $50, $14 ;  2/101 chance → 5,200 steps
    db $56, $00, $b4, $14 ;  2/101 chance → 5,300 steps
    db $58, $00, $18, $15 ;  2/101 chance → 5,400 steps
    db $5a, $00, $7c, $15 ;  2/101 chance → 5,500 steps
    db $5c, $00, $e0, $15 ;  2/101 chance → 5,600 steps
    db $5e, $00, $44, $16 ;  2/101 chance → 5,700 steps
    db $60, $00, $a8, $16 ;  2/101 chance → 5,800 steps
    db $62, $00, $0c, $17 ;  2/101 chance → 5,900 steps
    db $ff, $00, $70, $17 ;  catch-all   → 6,000 steps


label16_6f05:
    ld a, [wGameState]
    bit 2, a
    ret nz

    bit 5, a
    ret nz

    bit 6, a
    ret nz

    ld a, [$c850]
    or a
    ret nz

    ld a, [$c93e]
    bit 1, a
    ret nz

    ld a, [wInGateworld]
    or a
    jr nz, jr_016_6f39

    ld bc, $0050
    ld a, [wMapID]
    cp $54
    jr z, jr_016_6f62

    cp $55
    jr z, jr_016_6f62

    cp $56
    jr z, jr_016_6f62

    ld bc, $0064
    jr jr_016_6f62

jr_016_6f39:
    ld hl, $6fab
    ld a, [wMapID]
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    jr z, jr_016_6f5f

    inc hl
    inc hl
    cp $0d
    jr z, jr_016_6f5f

    inc hl
    inc hl
    cp $0e
    jr z, jr_016_6f5f

    ret


jr_016_6f5f:
    ld a, [hl+]
    ld b, [hl]
    ld c, a

jr_016_6f62:
    push bc
    ld hl, $010d
    rst $10
    ld hl, EncounterRateModifierTable
    ld a, [$c8a9]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop bc
    call Mul16x8To24
    ld a, $40
    call Div24x8To16
    ld e, l
    ld d, h
    ld a, [wEncounterCounterLo]
    ld l, a
    ld a, [wEncounterCounterHi]
    ld h, a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    jr nc, jr_016_6fa2

    ld hl, $010b
    rst $10
    ld hl, wGameState
    set 6, [hl]
    xor a
    ld [$c905], a
    ld a, $00
    ld [$da09], a
    ret


jr_016_6fa2:
    ld a, l
    ld [wEncounterCounterLo], a
    ld a, h
    ld [wEncounterCounterHi], a
    ret

; ---------------------------------------------------------------
; EncounterRateData — 16 entries × 8 bytes
; Per-gate-floor-threshold encounter rate parameters.
; Each entry: 3 × 16-bit values (little-endian) + 2 bytes padding.
; ---------------------------------------------------------------
EncounterRateData:
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  0: 138, 138, 138
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  1: 138, 138, 138
    db $8a, $00, $96, $00, $8a, $00, $00, $00 ; entry  2: 138, 150, 138
    db $8a, $00, $8a, $00, $8c, $00, $00, $00 ; entry  3: 138, 138, 140
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  4: 138, 138, 138
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  5: 138, 138, 138
    db $8a, $00, $8a, $00, $8c, $00, $00, $00 ; entry  6: 138, 138, 140
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  7: 138, 138, 138
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry  8: 138, 138, 138
    db $96, $00, $96, $00, $96, $00, $00, $00 ; entry  9: 150, 150, 150
    db $8a, $00, $8a, $00, $8a, $00, $00, $00 ; entry 10: 138, 138, 138
    db $64, $00, $b4, $00, $fa, $00, $00, $00 ; entry 11: 100, 180, 250
    db $64, $00, $b4, $00, $b4, $00, $00, $00 ; entry 12: 100, 180, 180
    db $64, $00, $b4, $00, $fa, $00, $00, $00 ; entry 13: 100, 180, 250
    db $64, $00, $b4, $00, $b4, $00, $00, $00 ; entry 14: 100, 180, 180
    db $96, $00, $b4, $00, $96, $00, $00, $00 ; entry 15: 150, 180, 150

; ---------------------------------------------------------------
; EncounterRateModifierTable — 8 bytes
; Indexed by wC8A9 (gate floor threshold index from Bank $01).
; Multiplied with encounter counter to determine encounter rate.
; ---------------------------------------------------------------
EncounterRateModifierTable:
    db $10, $15, $20, $40, $50, $60, $70, $80

LoadFloorDataPointer:
    ld de, FloorDataPtrTable1
    ld a, [$c93f]
    cp $02
    jr nz, jr_016_7040

    ld de, FloorDataPtrTable2

jr_016_7040:
    ld a, [wScreenIndex]
    ld hl, $c940
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld l, [hl]
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ret


; ---------------------------------------------------------------
; FloorTypeSortData — 16 entries × 4 bytes
; Floor type sorting/ranking data used in gate floor generation.
; Format: [floor_type_id, sequential_index, weight, padding]
; ---------------------------------------------------------------
FloorTypeSortData:
    db $0f, $00, $04, $00 ; type $0F, idx  0, weight 4
    db $07, $01, $03, $00 ; type $07, idx  1, weight 3
    db $0b, $02, $03, $00 ; type $0B, idx  2, weight 3
    db $0d, $03, $03, $00 ; type $0D, idx  3, weight 3
    db $0e, $04, $03, $00 ; type $0E, idx  4, weight 3
    db $03, $05, $02, $00 ; type $03, idx  5, weight 2
    db $05, $06, $02, $00 ; type $05, idx  6, weight 2
    db $06, $07, $02, $00 ; type $06, idx  7, weight 2
    db $09, $08, $02, $00 ; type $09, idx  8, weight 2
    db $0a, $09, $02, $00 ; type $0A, idx  9, weight 2
    db $0c, $0a, $02, $00 ; type $0C, idx 10, weight 2
    db $08, $0b, $01, $00 ; type $08, idx 11, weight 1
    db $04, $0c, $01, $00 ; type $04, idx 12, weight 1
    db $02, $0d, $01, $00 ; type $02, idx 13, weight 1
    db $01, $0e, $01, $00 ; type $01, idx 14, weight 1
    db $00, $0f, $00, $00 ; type $00, idx 15, weight 0

    db $ff ; delimiter

; ---------------------------------------------------------------
; FloorTypeOrderTable — 16 bytes
; Permutation/ordering of floor type IDs.
; ---------------------------------------------------------------
FloorTypeOrderTable:
    db $05, $06, $0a, $09, $08, $04, $00, $01, $02, $03, $07, $0b, $0f, $0e, $0d, $0c

; ---------------------------------------------------------------
; GateFloorDataTable — 32 entries × 8 bytes
; Configuration data for each gate. Format per entry:
;   byte 0: floor_type_1 (indexes FloorTypeSelectionTable)
;   byte 1: floor_type_2 (indexes FloorTypeSelectionTable2)
;   byte 2: floor_type_3 (indexes FloorTypeSelectionTable3)
;   byte 3: last_floor (floor count before boss)
;   byte 4: boss_room_map_type
;   byte 5: boss_spawn_x
;   byte 6: boss_spawn_y
;   byte 7: boss_floor_tileset
; ---------------------------------------------------------------
GateFloorDataTable:
    db $00, $00, $00, $05, $30, $07, $02, $01 ; Gate of Beginning (last floor: 5)
    db $01, $01, $01, $05, $31, $01, $06, $01 ; Gate of Villager (last floor: 5)
    db $01, $01, $02, $06, $32, $05, $01, $01 ; Gate of Talisman (last floor: 6)
    db $02, $01, $02, $05, $33, $04, $06, $01 ; Gate of Memories (last floor: 5)
    db $02, $02, $03, $06, $34, $00, $07, $01 ; Gate of Bewilder (last floor: 6)
    db $03, $02, $03, $09, $35, $01, $06, $01 ; Gate 05 (last floor: 9)
    db $03, $02, $04, $08, $36, $05, $01, $02 ; Gate of Peace (last floor: 8)
    db $03, $03, $04, $09, $37, $05, $07, $02 ; Gate of Bravery (last floor: 9)
    db $04, $03, $05, $0c, $38, $08, $03, $02 ; Gate 08 (last floor: 12)
    db $04, $04, $05, $0b, $39, $02, $01, $02 ; Gate 09 (last floor: 11)
    db $04, $04, $05, $0b, $3c, $02, $06, $02 ; Gate 10 (last floor: 11)
    db $04, $04, $06, $0c, $10, $08, $05, $02 ; Gate 11 (last floor: 12)
    db $05, $06, $06, $0e, $3b, $04, $01, $02 ; Gate 12 (last floor: 14)
    db $05, $06, $06, $0f, $3a, $01, $07, $02 ; Gate 13 (last floor: 15)
    db $05, $06, $07, $10, $3d, $04, $07, $02 ; Gate 14 (last floor: 16)
    db $06, $07, $07, $12, $3e, $04, $01, $03 ; Gate 15 (last floor: 18)
    db $07, $07, $08, $14, $3f, $06, $03, $03 ; Gate 16 (last floor: 20)
    db $07, $05, $08, $13, $40, $04, $06, $03 ; Gate 17 (last floor: 19)
    db $08, $08, $09, $17, $42, $04, $06, $03 ; Gate of Labyrinth (last floor: 23)
    db $08, $09, $09, $19, $43, $05, $05, $03 ; Gate 19 (last floor: 25)
    db $08, $05, $09, $19, $44, $00, $03, $03 ; Gate 20 (last floor: 25)
    db $09, $0a, $0a, $1d, $45, $04, $07, $03 ; Gate 21 (last floor: 29)
    db $0a, $0b, $0b, $1e, $46, $05, $06, $03 ; Gate of Ambition (last floor: 30)
    db $0a, $0b, $0b, $1d, $47, $05, $06, $03 ; Gate 23 (last floor: 29)
    db $0a, $0b, $0b, $1b, $48, $04, $07, $03 ; Gate 24 (last floor: 27)
    db $0b, $0c, $0c, $1e, $49, $04, $07, $03 ; Gate 25 (last floor: 30)
    db $0b, $0c, $0c, $1e, $4a, $09, $07, $03 ; Gate 26 (last floor: 30)
    db $0b, $0d, $0d, $1e, $4b, $04, $07, $03 ; Gate 27 (last floor: 30)
    db $0c, $0d, $0d, $1e, $4c, $05, $05, $03 ; Gate 28 (last floor: 30)
    db $0d, $0e, $0e, $1b, $4d, $05, $07, $03 ; Arena Right Gate (last floor: 27)
    db $0e, $0e, $0e, $1e, $4e, $08, $0c, $03 ; Gate 30 (last floor: 30)
    db $0f, $0f, $0f, $63, $4f, $05, $06, $03 ; Unused Gate (last floor: 99)

; ---------------------------------------------------------------
; FloorTypeSelectionTable — 16 entries × 16 bytes
; Cumulative probability thresholds for room type selection.
; Each 16-byte row: one threshold per possible room type.
; Values are percentages (0-100/$64). $00 = skip, $64 = guaranteed.
; Used by SelectFloorType with index from GateFloorDataTable byte 0.
; ---------------------------------------------------------------
FloorTypeSelectionTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $64, $00, $00 ; type 0
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $28, $00, $64, $00, $00 ; type 1
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $28, $00, $00, $00, $64, $00, $00 ; type 2
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $14, $00, $1e, $28, $64, $00, $00 ; type 3
    db $14, $28, $3c, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $50, $64, $00 ; type 4
    db $00, $00, $00, $00, $00, $1e, $3c, $00, $00, $00, $00, $00, $00, $50, $64, $00 ; type 5
    db $00, $00, $00, $1e, $3c, $00, $00, $00, $00, $00, $00, $00, $00, $50, $64, $00 ; type 6
    db $00, $00, $00, $00, $00, $00, $00, $1e, $3c, $00, $00, $00, $00, $50, $64, $00 ; type 7
    db $00, $00, $00, $00, $00, $00, $14, $00, $28, $00, $00, $00, $3c, $00, $64, $00 ; type 8
    db $0a, $14, $1e, $23, $28, $00, $32, $00, $3c, $46, $00, $00, $50, $00, $64, $00 ; type 9
    db $00, $00, $00, $0a, $00, $00, $14, $00, $28, $00, $00, $00, $3c, $00, $50, $64 ; type 10
    db $00, $00, $00, $0a, $00, $00, $14, $00, $28, $00, $3c, $00, $50, $00, $64, $00 ; type 11
    db $0a, $00, $00, $14, $1e, $00, $28, $00, $32, $3c, $46, $00, $50, $00, $5a, $64 ; type 12
    db $00, $0a, $00, $14, $1e, $00, $28, $00, $32, $3c, $46, $00, $50, $00, $5a, $64 ; type 13
    db $00, $00, $0a, $14, $1e, $00, $28, $00, $32, $3c, $46, $00, $50, $00, $5a, $64 ; type 14
    db $05, $0a, $00, $14, $1e, $00, $28, $00, $32, $3c, $46, $00, $50, $00, $5a, $64 ; type 15

; ---------------------------------------------------------------
; FloorTypeSelectionTable2 — 16 entries × 8 bytes
; Second floor type probability table.
; Used by code at $5C1C with index from GateFloorDataTable byte 1.
; Format: 8 probability thresholds per entry.
; ---------------------------------------------------------------
FloorTypeSelectionTable2:
    db $14, $00, $00, $46, $64, $00, $00, $00 ; type 0
    db $00, $00, $00, $32, $64, $00, $00, $00 ; type 1
    db $28, $00, $00, $46, $64, $00, $00, $00 ; type 2
    db $00, $00, $00, $1e, $3c, $00, $64, $00 ; type 3
    db $00, $00, $28, $46, $64, $00, $00, $00 ; type 4
    db $00, $00, $00, $2d, $4b, $64, $00, $00 ; type 5
    db $00, $00, $00, $1e, $3c, $00, $00, $64 ; type 6
    db $0f, $14, $1e, $3c, $5a, $64, $00, $00 ; type 7
    db $0f, $14, $00, $32, $50, $00, $5a, $64 ; type 8
    db $1e, $00, $2d, $3c, $4b, $5a, $5f, $64 ; type 9
    db $0a, $1e, $28, $37, $46, $50, $5a, $64 ; type 10
    db $05, $19, $28, $2d, $32, $3c, $50, $64 ; type 11
    db $05, $1e, $28, $32, $37, $46, $50, $64 ; type 12
    db $05, $23, $32, $3c, $41, $50, $5a, $64 ; type 13
    db $05, $23, $32, $46, $4b, $5a, $5f, $64 ; type 14
    db $05, $19, $23, $2d, $37, $50, $5a, $64 ; type 15

; ---------------------------------------------------------------
; FloorTypeSelectionTable3 — 17 entries × 16 bytes
; Third floor type probability table.
; Used by Call_016_6432 with index from GateFloorDataTable byte 2.
; ---------------------------------------------------------------
FloorTypeSelectionTable3:
    db $64, $00, $00, $00, $00, $00, $00, $00, $00, $02, $02, $00, $00, $00, $00, $00 ; type 0
    db $4b, $00, $00, $00, $00, $00, $00, $64, $00, $04, $02, $00, $00, $00, $00, $00 ; type 1
    db $4b, $00, $00, $00, $00, $00, $00, $64, $00, $04, $02, $00, $00, $00, $00, $00 ; type 2
    db $50, $00, $00, $00, $00, $00, $00, $64, $00, $04, $02, $00, $00, $00, $00, $00 ; type 3
    db $50, $00, $00, $00, $00, $00, $00, $64, $00, $04, $02, $00, $00, $00, $00, $00 ; type 4
    db $50, $00, $00, $00, $00, $00, $00, $64, $00, $02, $04, $0a, $00, $00, $00, $00 ; type 5
    db $4b, $00, $00, $00, $00, $00, $00, $5f, $64, $02, $04, $0a, $00, $00, $00, $00 ; type 6
    db $50, $00, $00, $00, $00, $00, $00, $5f, $64, $02, $04, $0a, $00, $00, $00, $00 ; type 7
    db $4b, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $06, $1e, $00, $00, $00, $00 ; type 8
    db $4b, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $06, $1e, $00, $00, $00, $00 ; type 9
    db $4b, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $06, $1e, $00, $00, $00, $00 ; type 10
    db $50, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $04, $1e, $00, $00, $00, $00 ; type 11
    db $50, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $04, $1e, $00, $00, $00, $00 ; type 12
    db $50, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $04, $1e, $00, $00, $00, $00 ; type 13
    db $50, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $04, $1e, $00, $00, $00, $00 ; type 14
    db $46, $00, $00, $00, $00, $00, $00, $5a, $64, $00, $02, $1e, $00, $00, $00, $00 ; type 15
    db $01, $01, $01, $01, $01, $01, $01, $00, $ff, $01, $01, $01, $01, $01, $01, $01 ; type 16

; ---------------------------------------------------------------
; FloorLayoutData — 1120 bytes at $7436
; Floor layout configuration data.
; Indexed with ×48 multiplier from gate code.
; ---------------------------------------------------------------
FloorLayoutData:
    db $00, $5d, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7436
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $62, $63, $00 ; $7446
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $64, $00, $00, $00, $00, $00 ; $7456
    db $00, $32, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $33, $00, $34 ; $7466
    db $35, $00, $00, $53, $58, $5b, $00, $00, $00, $00, $00, $00, $00, $60, $61, $00 ; $7476
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $64, $00, $00, $00, $00, $00 ; $7486
    db $00, $32, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $33, $00 ; $7496
    db $00, $34, $35, $53, $58, $5b, $00, $00, $00, $00, $00, $00, $00, $60, $61, $00 ; $74A6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $64, $00, $00, $00, $00, $00 ; $74B6
    db $00, $24, $2a, $00, $00, $00, $00, $2c, $2e, $30, $32, $34, $00, $35, $00, $36 ; $74C6
    db $37, $00, $00, $4f, $54, $57, $00, $00, $00, $5a, $5b, $00, $00, $60, $61, $00 ; $74D6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $64, $00, $00, $00, $00, $00 ; $74E6
    db $00, $16, $20, $00, $00, $25, $00, $2a, $2c, $2e, $30, $32, $00, $00, $33, $00 ; $74F6
    db $00, $34, $35, $49, $4e, $51, $52, $53, $00, $56, $58, $59, $00, $5e, $5f, $00 ; $7506
    db $00, $00, $00, $00, $00, $00, $00, $61, $00, $00, $64, $00, $00, $00, $00, $00 ; $7516
    db $00, $11, $25, $00, $00, $29, $2a, $2f, $31, $33, $35, $37, $38, $39, $00, $3a ; $7526
    db $3b, $00, $00, $40, $4f, $52, $53, $54, $55, $00, $57, $59, $00, $5d, $5e, $00 ; $7536
    db $00, $00, $00, $00, $00, $00, $00, $61, $00, $00, $64, $00, $00, $00, $00, $00 ; $7546
    db $00, $02, $1b, $00, $20, $23, $24, $29, $2b, $2d, $2f, $31, $32, $00, $33, $00 ; $7556
    db $00, $34, $35, $00, $49, $53, $54, $55, $56, $00, $58, $00, $59, $5c, $5d, $00 ; $7566
    db $00, $00, $00, $00, $00, $00, $00, $61, $00, $00, $64, $00, $00, $00, $00, $00 ; $7576
    db $00, $00, $1f, $00, $24, $26, $28, $2a, $2c, $2e, $30, $32, $33, $34, $00, $35 ; $7586
    db $00, $00, $00, $00, $44, $53, $54, $55, $56, $00, $58, $00, $59, $5b, $5c, $00 ; $7596
    db $00, $00, $00, $00, $00, $00, $00, $60, $61, $00, $64, $00, $00, $00, $00, $00 ; $75A6
    db $00, $00, $1b, $00, $20, $21, $24, $26, $28, $2a, $2c, $2e, $2f, $30, $00, $00 ; $75B6
    db $31, $32, $33, $00, $3d, $51, $53, $55, $56, $00, $58, $00, $59, $5b, $5c, $00 ; $75C6
    db $00, $00, $00, $00, $00, $00, $00, $60, $61, $00, $64, $00, $00, $00, $00, $00 ; $75D6
    db $00, $00, $12, $00, $17, $00, $1b, $1d, $1f, $21, $23, $25, $26, $27, $28, $00 ; $75E6
    db $29, $2a, $2b, $00, $30, $49, $4b, $4e, $4f, $00, $50, $00, $52, $54, $55, $00 ; $75F6
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $7606
    db $00, $00, $12, $00, $17, $00, $1b, $1d, $1f, $21, $23, $25, $26, $27, $00, $28 ; $7616
    db $29, $2a, $2b, $00, $00, $49, $4b, $4e, $4f, $00, $50, $00, $52, $54, $55, $00 ; $7626
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $7636
    db $00, $00, $11, $00, $16, $00, $1a, $1b, $1e, $20, $22, $24, $25, $00, $26, $28 ; $7646
    db $00, $29, $00, $00, $00, $45, $47, $4c, $00, $00, $4d, $00, $50, $54, $55, $00 ; $7656
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $7666
    db $00, $00, $11, $00, $16, $00, $1a, $1c, $1e, $20, $22, $24, $25, $26, $00, $00 ; $7676
    db $27, $00, $29, $00, $00, $45, $47, $4c, $00, $00, $4d, $00, $50, $54, $55, $00 ; $7686
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $7696
    db $00, $00, $11, $00, $16, $00, $1a, $1c, $1e, $20, $22, $24, $25, $00, $27, $28 ; $76A6
    db $00, $29, $00, $00, $00, $45, $47, $4c, $00, $00, $4d, $00, $50, $54, $55, $00 ; $76B6
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $76C6
    db $00, $00, $11, $00, $16, $00, $1a, $1c, $1e, $20, $22, $24, $25, $26, $00, $00 ; $76D6
    db $28, $00, $29, $00, $00, $45, $47, $4c, $00, $00, $4d, $00, $50, $54, $55, $00 ; $76E6
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $76F6
    db $00, $00, $0f, $00, $14, $00, $18, $1a, $1c, $1e, $20, $22, $23, $24, $25, $26 ; $7706
    db $27, $28, $29, $00, $00, $45, $47, $4c, $00, $00, $4d, $00, $50, $54, $55, $00 ; $7716
    db $00, $00, $00, $00, $00, $00, $00, $5d, $5f, $00, $64, $00, $00, $00, $00, $00 ; $7726
    db $60, $10, $10, $70, $30, $00, $00, $40, $30, $00, $00, $40, $80, $20, $20, $90 ; $7736
    db $60, $70, $60, $70, $30, $40, $30, $40, $30, $40, $30, $40, $80, $22, $23, $90 ; $7746
    db $60, $70, $60, $70, $80, $0c, $0d, $90, $60, $0b, $0a, $70, $80, $90, $80, $90 ; $7756
    db $60, $70, $60, $70, $30, $40, $33, $90, $30, $40, $31, $70, $80, $22, $23, $90 ; $7766
    db $60, $70, $60, $70, $30, $40, $80, $42, $30, $07, $10, $41, $80, $20, $20, $90 ; $7776
    db $61, $72, $61, $72, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $b0, $82, $92, $b0 ; $7786
    db $64, $50, $50, $74, $a0, $f0, $f0, $a0, $a0, $f0, $f0, $a0, $84, $50, $50, $94 ; $7796
    db $64, $50, $12, $74, $a0, $60, $41, $a0, $a0, $80, $90, $a0, $84, $50, $50, $94 ; $77A6
    db $64, $16, $16, $74, $36, $01, $01, $46, $36, $01, $01, $46, $84, $26, $26, $94 ; $77B6
    db $64, $50, $50, $74, $84, $50, $50, $45, $64, $50, $50, $44, $84, $50, $50, $94 ; $77C6
    db $64, $14, $15, $74, $35, $94, $84, $45, $34, $74, $64, $44, $84, $24, $25, $94 ; $77D6
    db $64, $16, $16, $74, $35, $26, $26, $94, $34, $16, $16, $74, $84, $26, $26, $94 ; $77E6
    db $64, $12, $50, $74, $a0, $34, $74, $a0, $a0, $84, $94, $a0, $84, $50, $50, $94 ; $77F6
    db $60, $10, $70, $c0, $30, $00, $40, $a0, $80, $20, $42, $a0, $e0, $50, $21, $94 ; $7806
    db $60, $70, $e0, $74, $30, $07, $11, $43, $30, $08, $90, $a0, $80, $90, $e0, $94 ; $7816
    db $e0, $71, $c0, $c0, $64, $21, $45, $a0, $a0, $64, $21, $45, $b0, $b0, $e0, $91 ; $7826
    db $f0, $64, $74, $f0, $64, $94, $84, $74, $84, $74, $64, $94, $f0, $84, $94, $f0 ; $7836
    db $64, $16, $16, $74, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $a0, $84, $26, $26, $94 ; $7846
    db $e0, $71, $62, $d0, $61, $0a, $0b, $72, $b0, $33, $42, $b0, $e0, $91, $81, $d0 ; $7856
    db $64, $71, $62, $74, $a0, $31, $41, $a0, $a0, $33, $42, $a0, $84, $91, $81, $94 ; $7866
    db $64, $71, $62, $74, $b0, $a1, $a1, $b0, $62, $94, $84, $71, $81, $51, $52, $91 ; $7876
    db $00, $0d, $0d, $0d, $0d, $0d, $1a, $1a, $1a, $1a, $1a, $26, $26, $26, $26, $26 ; $7886

; ---------------------------------------------------------------
; FloorDataPtrTable1 — 512 bytes at $7896
; Pointer/data table loaded when $C93F != 2.
; Referenced by code at $7033 (ld de, FloorDataPtrTable1).
; ---------------------------------------------------------------
FloorDataPtrTable1:
    db $10, $28, $11, $28, $12, $28, $13, $28, $14, $28, $15, $28, $00, $2b, $01, $2b ; $7896
    db $02, $2b, $03, $2b, $04, $2b, $05, $2b, $14, $2c, $10, $28, $10, $28, $10, $28 ; $78A6
    db $16, $28, $17, $28, $18, $28, $19, $28, $1a, $28, $1b, $28, $06, $2b, $07, $2b ; $78B6
    db $08, $2b, $09, $2b, $0a, $2b, $0b, $2b, $15, $2c, $10, $28, $10, $28, $10, $28 ; $78C6
    db $00, $27, $01, $27, $02, $27, $03, $27, $04, $27, $05, $27, $0c, $2b, $0d, $2b ; $78D6
    db $0e, $2b, $0f, $2b, $10, $2b, $11, $2b, $16, $2c, $10, $28, $10, $28, $10, $28 ; $78E6
    db $06, $27, $07, $27, $08, $27, $09, $27, $0a, $27, $0b, $27, $12, $2b, $13, $2b ; $78F6
    db $14, $2b, $15, $2b, $16, $2b, $17, $2b, $17, $2c, $10, $28, $10, $28, $10, $28 ; $7906
    db $0c, $27, $0d, $27, $0e, $27, $0f, $27, $10, $27, $11, $27, $18, $2b, $19, $2b ; $7916
    db $1a, $2b, $1b, $2b, $1c, $2b, $1d, $2b, $18, $2c, $10, $28, $10, $28, $10, $28 ; $7926
    db $12, $27, $13, $27, $14, $27, $15, $27, $16, $27, $17, $27, $1e, $2b, $1f, $2b ; $7936
    db $20, $2b, $21, $2b, $22, $2b, $23, $2b, $19, $2c, $10, $28, $10, $28, $10, $28 ; $7946
    db $18, $27, $19, $27, $1a, $27, $1b, $27, $1c, $27, $1d, $27, $24, $2b, $25, $2b ; $7956
    db $26, $2b, $27, $2b, $28, $2b, $29, $2b, $1a, $2c, $10, $28, $10, $28, $10, $28 ; $7966
    db $1e, $27, $1f, $27, $20, $27, $21, $27, $22, $27, $23, $27, $2a, $2b, $2b, $2b ; $7976
    db $2c, $2b, $2d, $2b, $2e, $2b, $2f, $2b, $1b, $2c, $10, $28, $10, $28, $10, $28 ; $7986
    db $24, $27, $25, $27, $26, $27, $27, $27, $28, $27, $29, $27, $30, $2b, $31, $2b ; $7996
    db $32, $2b, $33, $2b, $34, $2b, $35, $2b, $1c, $2c, $10, $28, $10, $28, $10, $28 ; $79A6
    db $2a, $27, $2b, $27, $2c, $27, $2d, $27, $2e, $27, $2f, $27, $36, $2b, $37, $2b ; $79B6
    db $38, $2b, $39, $2b, $3a, $2b, $3b, $2b, $1d, $2c, $10, $28, $10, $28, $10, $28 ; $79C6
    db $30, $27, $31, $27, $32, $27, $33, $27, $34, $27, $35, $27, $3c, $2b, $3d, $2b ; $79D6
    db $3e, $2b, $3f, $2b, $40, $2b, $41, $2b, $1e, $2c, $10, $28, $10, $28, $10, $28 ; $79E6
    db $36, $27, $37, $27, $38, $27, $39, $27, $3a, $27, $3b, $27, $42, $2b, $43, $2b ; $79F6
    db $44, $2b, $45, $2b, $46, $2b, $47, $2b, $1f, $2c, $10, $28, $10, $28, $10, $28 ; $7A06
    db $3c, $27, $3d, $27, $3e, $27, $3f, $27, $40, $27, $41, $27, $02, $2c, $03, $2c ; $7A16
    db $04, $2c, $05, $2c, $06, $2c, $07, $2c, $20, $2c, $10, $28, $10, $28, $10, $28 ; $7A26
    db $42, $27, $43, $27, $44, $27, $45, $27, $46, $27, $47, $27, $08, $2c, $09, $2c ; $7A36
    db $0a, $2c, $0b, $2c, $0c, $2c, $0d, $2c, $21, $2c, $10, $28, $10, $28, $10, $28 ; $7A46
    db $48, $27, $49, $27, $4a, $27, $4b, $27, $4c, $27, $4d, $27, $0e, $2c, $0f, $2c ; $7A56
    db $10, $2c, $11, $2c, $12, $2c, $13, $2c, $22, $2c, $10, $28, $10, $28, $10, $28 ; $7A66
    db $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27 ; $7A76
    db $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27 ; $7A86

; ---------------------------------------------------------------
; FloorDataPtrTable2 — at $7A96
; Pointer/data table loaded when $C93F == 2.
; Referenced by code at $7033 (ld de, $7A96).
; ---------------------------------------------------------------
FloorDataPtrTable2:
    db $23, $2c, $24, $2c, $25, $2c, $26, $2c, $27, $2c, $28, $2c, $29, $2c, $2a, $2c ; $7A96
    db $2b, $2c, $2c, $2c, $2d, $2c, $2e, $2c, $2f, $2c, $30, $2c, $23, $2c, $23, $2c ; $7AA6
    db $00, $3b, $01, $3b, $02, $3b, $03, $3b, $04, $3b, $05, $3b, $06, $3b, $23, $2c ; $7AB6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7AC6
    db $07, $3b, $08, $3b, $09, $3b, $0a, $3b, $0b, $3b, $0c, $3b, $0d, $3b, $23, $2c ; $7AD6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7AE6
    db $0e, $3b, $0f, $3b, $10, $3b, $11, $3b, $12, $3b, $13, $3b, $14, $3b, $23, $2c ; $7AF6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B06
    db $37, $3a, $38, $3a, $39, $3a, $3a, $3a, $3b, $3a, $3c, $3a, $3d, $3a, $23, $2c ; $7B16
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B26
    db $3e, $3a, $3f, $3a, $40, $3a, $41, $3a, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B36
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B46
    db $42, $3a, $43, $3a, $44, $3a, $45, $3a, $46, $3a, $23, $2c, $23, $2c, $23, $2c ; $7B56
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B66
    db $47, $3a, $48, $3a, $49, $3a, $4a, $3a, $4b, $3a, $23, $2c, $23, $2c, $23, $2c ; $7B76
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7B86
    db $4c, $3a, $4d, $3a, $4e, $3a, $4f, $3a, $50, $3a, $23, $2c, $23, $2c, $23, $2c ; $7B96
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7BA6
    db $15, $3b, $16, $3b, $17, $3b, $18, $3b, $19, $3b, $23, $2c, $23, $2c, $23, $2c ; $7BB6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7BC6
    db $1a, $3b, $1b, $3b, $1c, $3b, $1d, $3b, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7BD6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7BE6
    db $1e, $3b, $1f, $3b, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7BF6
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C06
    db $20, $3b, $21, $3b, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C16
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C26
    db $22, $3b, $23, $3b, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C36
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C46
    db $24, $3b, $25, $3b, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C56
    db $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c, $23, $2c ; $7C66
    db $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27 ; $7C76
    db $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27, $4e, $27 ; $7C86
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7C96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CD6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CE6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7CF6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D06
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D16
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D26
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D36
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D46
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D56
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D66
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D76
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D86
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7D96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DD6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DE6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7DF6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E06
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E16
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E26
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E36
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E46
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E56
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E66
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E76
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E86
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7E96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7EA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7EB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7EC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7ED6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7EE6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7EF6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F06
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F16
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F26
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F36
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F46
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F56
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F66
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F76
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F86
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7F96
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FA6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FB6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FC6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FD6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FE6
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00 ; $7FF6
