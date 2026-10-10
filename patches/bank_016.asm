; =============================================================================
; BANK $16 — BREEDING SYSTEM
; =============================================================================
; Contains:
;   - Breeding initialization (entry 0 → BreedingInit at $4015)
;   - Offspring determination (entry 2 → BreedingResolve at $456E)
;   - Offspring determination alt (entry 3 → $45A3, same logic minus $44D0 call)
;   - BIRTH finalizer (entry 4 → BreedBirthFinalize $474A; S130 — not
;     "skill/stat inheritance": it runs at the birth, egg flag +$63 -> 0)
;   - Offspring stats / AI / resistances / learn queue (S130 names):
;     BreedStatInherit, BreedAIAverage, BreedResistInherit/BreedResistOne
;
; BREEDING ALGORITHM (Call_016_456e):
;   1. BreedPlusAndSpecial — Compute offspring "plus" value from parents
;      Then search SPECIAL RECIPE TABLE at $4B30 (825 entries × 5 bytes)
;      Format: [parent1_match, parent2_match, min_plus, result_species, plus_mod]
;      Matches: specific species OR family code ($F0-$F9)
;      Checked FIRST — takes priority over family table
;
;   2. BreedFamilySearch → BreedFamilyScan — Search FAMILY RECIPE TABLE at $4974
;      Format: 2-byte pairs [B, C] with $FFFF separators between result species
;      D (result species index) increments at EVERY entry
;      EXACT species match: returns immediately
;      FAMILY match: stores result but KEEPS SCANNING (last family match wins)
;      Two passes: first with specific parent2, then with parent2→family
;
;   3. Fallback — offspring = parent 1 species ($DA6F)
;
;   4. (NO mutation in the shipped game — S113, measured: the "rare breed"
;      routine BreedRareMutation_Unreferenced ($44DA) has no caller anywhere
;      in the ROM, so $D9E6 is never set and the bank $0D "Wow! It's a rare
;      breed!" line never shows. BREEDING_SYSTEM "The resolver as measured".)
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
    dw BreedCreateOffspring   ; Entry 0: create the offspring in the first empty roster slot (callers: $0A:$4A8D, $0A:$56F8, $15:$5B7D)
    dw label16_485c          ; Entry 1: Unknown
    dw BreedResolveOffspring  ; Entry 2: offspring species + plus (no far caller: BreedCreateOffspring calls it)
    dw BreedResolvePreview    ; Entry 3: same result, no $44D0 call — the shrine's pair evaluator (bank $0A $5470)
    dw BreedBirthFinalize          ; Entry 4: BIRTH finalizer (S130; callers $04 ScriptCmd3A_ToBreedingScene, $0A label5c5b)
    dw label16_5b4e          ; Entry 5
    dw EncounterSeedOnRoomLoad ; Entry 6 (was label16_5fe4; S114 name)
    dw SetBrd_6db0          ; Entry 7
    dw EncounterStep         ; Entry 8 (was label16_6f05; S114 name)
    dw LoadFloorDataPointer          ; Entry 9

; BreedCreateOffspring (entry 0, S113 annotation) — builds the egg/offspring.
; Scans the roster for the first empty slot (+$00 = 0), zeroes it, then:
;   $DA6F/$DA70 = the two parents' species from the staging records
;   ($D66E pedigree / $D703 mate), $DA75/$DA76 = their slot numbers, read
;   by BreedPlusAndSpecial for plus + level ($14/$15 in vanilla; $28/$29 in
;   this FX1 build — the S113 fix below), then
;   BreedResolveOffspring -> species ($DA71) + plus ($DA77, stored max 99).
;   level +$4B = 1; max level +$4C ($CB0D) = clamp(info level cap +
;   2*plus, 2..99); female +$0B ($CACC) = 1 when wRNG1 <
;   BreedGenderThreshold[ratio] (the info row's female ratio, $DA36).
; [S130] offspring fields (simulator/raising.py breed; census 400 + 400
; second-generation + 400 births, 0 mismatches): stats BreedStatInherit
; (MaxHP/HP, MaxMP/MP, ATK, DEF, AGL, INT); AI +$64..+$67 BreedAIAverage
; (carry-drop bug); resistances +$68 = the species' then BreedResistInherit;
; gender; egg flag +$63 := 1; BreedPedigreeNames (+$15/+$16, names, plus);
; learn queue +$31 = own natural 3, pedigree species' 3, mate species' 3,
; pedigree's 8 known, mate's 8 known, each through UnevolvedSkillMap ($FF =
; never), first 25 distinct (InheritSkillList); known skills +$29 stay $FF.
BreedCreateOffspring:
    ld de, $cac1
    ld b, $28  ; FX1: 40 slots
    ld c, $00

jr_016_401c:
    ld a, [de]
    or a
    jr z, jr_016_402d

    push bc                     ; CF3 (S60): slot advance -> bank $73 entry 2
    push hl                     ; (DE += $95 with the WRAM<->SRAM boundary hop
    ld hl, $7302                ; at slot 2->3). Same-size 8-byte window.
    rst $10                     ; BC/HL preserved (rst $10 clobbers BC via its
    pop hl                      ; `ld bc,$4001` table index — walkers keep live
    pop bc                      ; counters in BC). A/flags clobbered as vanilla.
    inc c
    dec b
    jr nz, jr_016_401c

    ret


jr_016_402d:
    ld a, c
    ld [$cac0], a
    ld [$ca40], a
    ld hl, $cac1
    call LoadBrd_41b1
    ld bc, $0095
    xor a
    call FillNBytesWithRegA
    ld hl, $caea
    call LoadBrd_41b1
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caf2
    call LoadBrd_41b1
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $cac1
    call LoadBrd_41b1
    ld [hl], $01
    ld a, [$d66e]
    ld [$da6f], a
    ld a, [$d703]
    ld [$da70], a
    ld a, $28                ; S113 FIX: the parents' STAGING indices since FX1 (S71) = 40/41
    ld [$da75], a            ;   ($D665/$D6FA via the GMDP decode). Was $14/$15 = farm slots
    ld a, $29                ;   20/21 in FX1 builds: the egg's plus + level bonus came from
    ld [$da76], a            ;   those (empty: plus 1, no + recipe ever fired). PyBoy S113.
    call BreedResolveOffspring
    ld hl, $caca
    call LoadBrd_41b1
    ld a, [$da71]
    ld [hl], a
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld a, [wTempSpeciesId]
    ld hl, $ca94
    call SetBitInArray
    ld hl, $cacb
    call LoadBrd_41b1
    ld a, [$da33]
    ld [hl], a
    ld a, [$da77]
    push af
    ld hl, $cb23
    call LoadBrd_41b1
    pop af
    cp $63
    jr c, jr_016_40b3

    ld a, $63

jr_016_40b3:
    ld [hl], a
    ld hl, $cb23
    call LoadBrd_41b1
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
    call LoadBrd_41b1
    pop af
    ld [hl], a
    ld hl, $cb0c
    call LoadBrd_41b1
    ld [hl], $01
    ld hl, $cb13
    call BreedStatInherit
    push bc
    ld hl, $cb11
    call LoadBrd_41b1
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld hl, $cb17
    call BreedStatInherit
    push bc
    ld hl, $cb15
    call LoadBrd_41b1
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld hl, $cb19
    call BreedStatInherit
    ld hl, $cb1b
    call BreedStatInherit
    ld hl, $cb1d
    call BreedStatInherit
    ld hl, $cb1f
    call BreedStatInherit
    ld hl, $cb25
    call BreedAIAverage
    ld hl, $cb26
    call BreedAIAverage
    ld hl, $cb28
    call BreedAIAverage
    ld hl, $cb27
    call BreedAIAverage
    ld hl, $cb29
    ld de, $da42
    ld b, $1b
    call SaveBrd_4227
    call BreedResistInherit
    call GenerateRNG
    ld hl, BreedGenderThreshold        ; [female ratio] (S113 label; = $14:$459E bytes)
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
    call LoadBrd_41b1
    ld [hl], $01

jr_016_4169:
    ld hl, $cb24             ; [S130] egg flag +$63 := 1 (cleared at birth)
    call LoadBrd_41b1
    ld [hl], $01
    call BreedPedigreeNames
    ld de, $da39
    ld b, $03
    call InheritSkillList
    ld a, [$d66e]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call InheritSkillList
    ld a, [$d703]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call InheritSkillList
    ld de, $d68e
    ld b, $08
    call InheritSkillList
    ld de, $d723
    ld b, $08
    call InheritSkillList
    ret


LoadBrd_41b1:
    ld a, [$cac0]
    call GetMonsterDataPtr
    ret


; [S130] BreedStatInherit — HL = $CAC1 + stat field (u16). s = (pedigree +
; mate) >> 2 (16-bit sum, two srl/rr; parents = staging slots at +$0BA4 and
; +$0BA4+$95); k = PedigreeForeignCount; stat = s + s*k/50 (Mul16x8To24,
; Div16x8To16 by $32); 0 -> 1. Returns BC = the stat (caller copies MaxHP /
; MaxMP into HP / MP). Measured S130, 0 mismatches.
BreedStatInherit:
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
    call LoadBrd_41b1
    pop bc
    push hl
    push bc
    push bc
    call PedigreeForeignCount
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


; [S130] BreedAIAverage — VANILLA BUG: `add c / ld c,a / ld a,$00 / add b`
; drops the carry (should be `adc b`), so value = ((pedigree + mate) & $FF)
; >> 1 instead of the average (two 200s give 72). Measured 400/400.
BreedAIAverage:
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
    call LoadBrd_41b1
    pop bc
    ld [hl], c
    ret


SaveBrd_4227:
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


; [S130] BreedPedigreeNames — father first: pedigree +$0B female -> the mate
; is written as +$15 (swap, Jump_016_42aa). For parent 1 / 2: species ->
; +$15 / +$16; master name (+$0C, 8 B) -> +$17 / +$20 (9th byte := $CA4A);
; NICKNAME (+$01, 8 B) -> +$83 / +$8C; plus (+$62) -> +$8B / +$94.
BreedPedigreeNames:
    ld a, [$d670]
    and $01
    or a
    jp nz, Jump_016_42aa

    ld hl, $cad6
    call LoadBrd_41b1
    ld a, [$d66e]
    ld [hl], a
    ld hl, $cad8
    ld de, $d671
    ld b, $08
    call SaveBrd_4227
    ld hl, $cae0
    call LoadBrd_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb44
    ld de, $d666
    ld b, $08
    call SaveBrd_4227
    ld hl, $cb4c
    call LoadBrd_41b1
    ld a, [$d6c7]
    ld [hl], a
    ld hl, $cad7
    call LoadBrd_41b1
    ld a, [$d703]
    ld [hl], a
    ld hl, $cae1
    ld de, $d706
    ld b, $08
    call SaveBrd_4227
    ld hl, $cae9
    call LoadBrd_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb4d
    ld de, $d6fb
    ld b, $08
    call SaveBrd_4227
    ld hl, $cb55
    call LoadBrd_41b1
    ld a, [$d75c]
    ld [hl], a
    ret


Jump_016_42aa:
    ld hl, $cad6
    call LoadBrd_41b1
    ld a, [$d703]
    ld [hl], a
    ld hl, $cad8
    ld de, $d706
    ld b, $08
    call SaveBrd_4227
    ld hl, $cae0
    call LoadBrd_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb44
    ld de, $d6fb
    ld b, $08
    call SaveBrd_4227
    ld hl, $cb4c
    call LoadBrd_41b1
    ld a, [$d75c]
    ld [hl], a
    ld hl, $cad7
    call LoadBrd_41b1
    ld a, [$d66e]
    ld [hl], a
    ld hl, $cae1
    ld de, $d671
    ld b, $08
    call SaveBrd_4227
    ld hl, $cae9
    call LoadBrd_41b1
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $cb4d
    ld de, $d666
    ld b, $08
    call SaveBrd_4227
    ld hl, $cb55
    call LoadBrd_41b1
    ld a, [$d6c7]
    ld [hl], a
    ret


; [S130] PedigreeForeignCount — A = k = how many pedigree names differ from
; the player's name $CA42 (9 B, PedigreeNameDiffers): each parent's master
; +$0C, and for a parent with a pedigree (+$15 / +$16 != $FF) its +$83 /
; +$8C (the grandparents' nicknames, 9 B each, so the 9th = their plus
; byte). A bred parent counts 2 unless a nickname equals the player's name:
; second-generation offspring get about +4..8 % (measured 400/400).
PedigreeForeignCount:
    ld c, $00
    ld hl, $d671
    call PedigreeNameDiffers
    ld a, [$d67a]
    cp $ff
    ld hl, $d6e8
    call nz, PedigreeNameDiffers
    ld a, [$d67b]
    cp $ff
    ld hl, $d6f1
    call nz, PedigreeNameDiffers
    ld hl, $d706
    call PedigreeNameDiffers
    ld a, [$d70f]
    cp $ff
    ld hl, $d77d
    call nz, PedigreeNameDiffers
    ld a, [$d710]
    cp $ff
    ld hl, $d786
    call nz, PedigreeNameDiffers
    ld a, c
    ret


; [S130] PedigreeNameDiffers — C += 1 when the 9 bytes at HL differ from
; the player's name $CA42.
PedigreeNameDiffers:
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


; [S130] BreedResistInherit — the 27 resistances +$68 ($DA72 = index), each
; through BreedResistOne.
BreedResistInherit:
    xor a
    ld [$da72], a
    ld b, $1b

jr_016_4366:
    push bc
    call BreedResistOne
    ld hl, $da72
    inc [hl]
    pop bc
    dec b
    jr nz, jr_016_4366

    ret


; [S130] BreedResistOne — own (species) level 3 keeps; own 2 -> table
; BreedResistMidTable, own 0/1 -> BreedResistLowTable, each on (pedigree
; + mate resistance) & 7 (parents' +$68 at $D6CD / $D762; 7 never occurs).
BreedResistOne:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call LoadBrd_41b1
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
; [S130] BreedResistLowTable ($43AA) — own resistance 0/1, by (p1 + p2) & 7.
; Was misassembled as code (b8 43 b8 43 b8 43 b9 43 c6 43 d3 43 ec 43);
; byte-identical dw list. "mod N < plus" = BreedPlusRoll (RNG16 mod N vs
; the offspring's plus $DA77); a success = ResistUpTo2 (+1, cap 2).
BreedResistLowTable:
    dw BreedResistNone       ; sum 0: nothing
    dw BreedResistNone       ; sum 1: nothing
    dw BreedResistNone       ; sum 2: nothing
    dw BreedResistLow3       ; sum 3: mod 100 < plus -> +1
    dw BreedResistLow4       ; sum 4: mod 30 < plus -> +1
    dw BreedResistLow5       ; sum 5: mod 10, then mod 30 (two chances)
    dw BreedResistLow6       ; sum 6: +1 always, then mod 20 -> +1
BreedResistNone:
    ret


BreedResistLow3:
    ld a, [$da77]
    ld b, a
    ld a, $64
    call BreedPlusRoll
    call c, ResistUpTo2
    ret


BreedResistLow4:
    ld a, [$da77]
    ld b, a
    ld a, $1e
    call BreedPlusRoll
    call c, ResistUpTo2
    ret


BreedResistLow5:
    ld a, [$da77]
    ld b, a
    ld a, $0a
    call BreedPlusRoll
    call c, ResistUpTo2
    ld a, [$da77]
    ld b, a
    ld a, $1e
    call BreedPlusRoll
    call c, ResistUpTo2
    ret


BreedResistLow6:
    call ResistUpTo2
    ld a, [$da77]
    ld b, a
    ld a, $14
    call BreedPlusRoll
    call c, ResistUpTo2
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

CalcBrd_4410:
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    add [hl]
    and $07
    rst $00
; [S130] BreedResistMidTable ($441B) — own resistance 2, by (p1 + p2) & 7.
; Was misassembled as code (29 44 x5, 2a 44, 37 44); byte-identical dw list.
; A success = ResistUpTo3 (+1, cap 3).
BreedResistMidTable:
    dw BreedResistMidNone    ; sum 0: nothing
    dw BreedResistMidNone    ; sum 1: nothing
    dw BreedResistMidNone    ; sum 2: nothing
    dw BreedResistMidNone    ; sum 3: nothing
    dw BreedResistMidNone    ; sum 4: nothing
    dw BreedResistMid5       ; sum 5: mod 200 < plus -> +1
    dw BreedResistMid6       ; sum 6: mod 40 < plus -> +1
BreedResistMidNone:
    ret


BreedResistMid5:
    ld a, [$da77]
    ld b, a
    ld a, $c8
    call BreedPlusRoll
    call c, ResistUpTo3
    ret


BreedResistMid6:
    ld a, [$da77]
    ld b, a
    ld a, $28
    call BreedPlusRoll
    call c, ResistUpTo3
    ret


; [S130] BreedPlusRoll — A = N, B = plus: GenerateRNG, HL = wRNG2:wRNG1, A =
; HL mod N (Div16x8To16 remainder); `cp b` -> carry = remainder < plus.
BreedPlusRoll:
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


; [S130] resistance -1 (floor 0): no reference found (no label from mgbdis,
; not in either jump table) — dead in vanilla.
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call LoadBrd_41b1
    ld a, [hl]
    or a
    ret z

    dec [hl]
    ret


; [S130] ResistUpTo3 — offspring resistance [$DA72] += 1 unless already 3.
ResistUpTo3:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call LoadBrd_41b1
    ld a, [hl]
    cp $03
    ret z

    inc [hl]
    ret


; [S130] ResistUpTo2 — offspring resistance [$DA72] += 1 unless already 2.
ResistUpTo2:
    ld a, [$da72]
    ld hl, $cb29
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    call LoadBrd_41b1
    ld a, [hl]
    cp $02
    ret z

    inc [hl]
    ret


; InheritSkillList — B skill ids at DE -> InheritOneSkill each (S113 label).
InheritSkillList:
jr_016_4496:
    ld a, [de]
    inc de
    push bc
    push de
    call InheritOneSkill
    pop de
    pop bc
    dec b
    jr nz, jr_016_4496

    ret


; InheritOneSkill — A = skill id ($FF = none): map through UnevolvedSkillMap
; ($FF = not inherited), then add it to the offspring's 25-byte skill list
; (+$31 = $CAF2) unless already present; first $FF hole wins (S113 label).
InheritOneSkill:
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
    call LoadBrd_41b1
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


; BreedGenderThreshold (S113) — 4 bytes by female ratio 0-3: P(female) =
; byte/256 (0 %, 10 %, 50 %, 84 %) — the same bytes as bank $14's recruit
; table at $14:$459E (MONSTER_DATA info byte $03).
BreedGenderThreshold:
    db $00, $1a, $80, $d6

; BreedClearRareFlag (S113) — clear the "rare breed" flag $D9E6 unless in a
; link session ($C86C); called by BreedResolveOffspring between the family
; search and the fallback. Nothing ever sets the flag (S113).
BreedClearRareFlag:

    ld a, [$c86c]
    or a
    ret nz

    xor a
    ld [$d9e6], a
    ret


; BreedRareMutation_Unreferenced (S113) — NOTHING CALLS THIS (ROM-wide search for
; call/jp/dw $44DA: none; PyBoy census: 0 executions). Designed as a
; post-recipe mutation: with a result, 3/256 → a random SEEN species 200-214
; (CountSeenInRange / NthSeenInRange over $CA94); with none, 14/256 → a random
; seen species 0-199; either way $D9E6++ (the bank $0D "rare breed" line).
BreedRareMutation_Unreferenced:
    ld a, [$da71]
    cp $ff
    jr z, jr_016_450f

    call GenerateRNG
    ld a, [wRNG1]
    cp $03
    ret nc

    ld b, $c8
    ld d, $d7
    call CountSeenInRange
    ld a, [wRNG2]
    ld b, a
    ld a, c
    or a
    ret z

    call Div8x8
    ld b, $c8
    ld d, $d7
    ld e, a
    call NthSeenInRange
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
    call CountSeenInRange
    ld a, [wRNG2]
    ld b, a
    ld a, c
    or a
    ret z

    call Div8x8
    ld b, $00
    ld d, $c8
    ld e, a
    call NthSeenInRange
    ld a, b
    ld [$da71], a
    cp $ff
    ret z

    ld hl, $d9e6
    inc [hl]
    ret


; CountSeenInRange — C = how many species in [B, D) have their seen bit ($CA94).
CountSeenInRange:
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


; NthSeenInRange — B = the E-th seen species in [B, D) ($FF if none).
NthSeenInRange:
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


; BreedResolveOffspring (entry 2) — offspring species from two parents.
; Precedence (S113, PyBoy census == editor2/core/breeding.py): special table
; (first match, with plus) → family table (two passes) → parent 1 species.
; Input: $DA6F = parent 1 species, $DA70 = parent 2 species
;        $DA75/$DA76 = parent party slot indices
; Output: $DA71 = result species, $DA77 = offspring plus value
BreedResolveOffspring:
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
    call BreedPlusAndSpecial        ; Step 1: compute plus, search special table ($4B30)
    ld a, [$da71]
    cp $ff
    ret nz                   ; if special table found a result, done

    call BreedFamilySearch        ; Step 2: search family table ($4974)
    call BreedClearRareFlag   ; Step 3: clear the (never-set) rare-breed flag $D9E6
    ld a, [$da71]
    cp $ff
    ret nz                   ; if family table found a result, done

    ld a, [$da6f]            ; Step 4: fallback — offspring = parent 1 species
    ld [$da71], a
    ret

; BreedResolvePreview (entry 3) — BreedResolveOffspring without the $44D0
; call; the shrine's "what would these two make" evaluator (bank $0A).
BreedResolvePreview:
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
    call BreedPlusAndSpecial
    ld a, [$da71]
    cp $ff
    ret nz

    call BreedFamilySearch
    ld a, [$da71]
    cp $ff
    ret nz

    ld a, [$da6f]
    ld [$da71], a
    ret


; BreedFamilySearch — the family table, two passes (S113: measured).
; Pass 1 keeps the mate as its SPECIES (only rows whose mate matcher is that
; species can match); if nothing, pass 2 turns the mate into its family code
; and scans again (only rows whose mate matcher is a family code can match).
; Within a pass: pedigree matcher == the pedigree species → that row wins at
; once; == its family code → remembered, scan continues (the LAST such row
; wins). The result is the ROW NUMBER (= the offspring species).
; First pass: parent1 specific + parent2 specific → exact matches only
; If no match: convert parent2 to family code, search again
BreedFamilySearch:
    ld a, [$da70]            ; parent 2
    cp $f0
    jr nc, jr_016_45ff       ; if already family-coded, skip first pass

    ld a, [$da6f]            ; save parent 1
    push af
    call BreedFamilyScan        ; first pass: parent2 still specific
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

; BreedFamilyScan — one pass over FamilyRecipeTable (S113 label).
; Converts parent 1 to family code, then scans all entries
BreedFamilyScan:
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
    ld hl, FamilyRecipeTable             ; family recipe table base
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
    cp $fa                   ; vanilla: matcher $FA = "any family" when parent 2 is family-coded (no vanilla row uses it)
    nop                      ; S104: was `jr z, jr_016_463c` — the wildcard is retired: $FA = SPIRIT (family 10's
    nop                      ;       code $F0+10) and is compared exactly below like every other family code

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


; BreedPlusAndSpecial (S113, measured) — offspring plus, then the special table.
;   plus = max(plus of slot [$DA75], plus of slot [$DA76]) + 1 (link session
;   $C86C: the pedigree's plus + 1) + the level bonus: level sum >= 100 → +4,
;   >= 76 → +3, >= 60 → +2, >= 40 → +1; capped at 99.
;   Then $DA73/$DA74 = the parents' family codes ($F0 + info byte 0; Spirit =
;   $FA) and the special scan: the FIRST row whose pedigree matcher is the
;   pedigree species or family code, whose mate matcher is the mate species
;   or family code, and whose min plus <= plus → result + plus_mod; the sum
;   is capped at 99 at the end.
; Computes offspring plus from parents' plus values and levels
; Then converts parent species to family codes ($DA73/$DA74)
; Finally searches the 825-entry special recipe table
BreedPlusAndSpecial:
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
    ; --- B2 (ROADMAP Phase 2B): SPECIAL-table scan relocated to bank $69 ---
    ; Same-size, in-place redirect (exactly 30 bytes = the original scan's
    ; length): ld hl,$6900 (3) + rst $10 (1) + 26-byte NOP pad. `rst $10`
    ; (H=$69, L=0) runs RelocatedSpecialScan in bank $69, a faithful port of
    ; the old in-bank scan + BreedSpecialEntryCheck. It sets $DA71/$DA77 identically,
    ; returns here, and falls through to the plus-clamp at jr_016_4710.
    ; Bank $16 is shift-sensitive (embedded pointers at $70A6+), so the
    ; vanilla SpecialRecipeTable + BreedSpecialEntryCheck below are left DEAD in place
    ; (no bytes inserted/removed; assembled output is byte-for-byte the same
    ; size as vanilla except inside this 30-byte window).
    ld hl, $6900             ; bank $69, jump-table entry 0
    rst $10                  ; -> RelocatedSpecialScan (bank $69)
    ds 26, $00               ; NOP pad: preserve 30-byte length (zero shift)

jr_016_4710:
    ld a, [$da77]            ; clamp plus to max 99
    cp $63
    ret c

    ld a, $63
    ld [$da77], a
    ret


; BreedSpecialEntryCheck — check one 5-byte special row (S113 label).
; Format: [parent1_match, parent2_match, min_plus, result_species, plus_mod]
; Matches parent species (specific) or family code ($DA73/$DA74)
; Plus threshold: offspring plus ($DA77) must be >= entry byte 2
BreedSpecialEntryCheck:
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


; =============================================================================
; [S130] BreedBirthFinalize — bank $16 entry 4 (`ld hl,$1604 / rst $10`;
; callers bank $04 ScriptCmd3A_ToBreedingScene, bank $0A label5c5b). Runs
; when the egg is born (ROADMAP P3.12 called it "skill/stat inheritance").
; Slot [$CAC0]: WLD +$60/+$61 := 0; master +$0C := the player's name ($CA42,
; 9th byte $CA4A); the learn queue is rebuilt in $C0D8 (25 x $FF first):
; own species' natural 3, then +$15's species natural 3 and +$16's (only
; when +$15 != $FF; +$15 = the father), then the OLD queue (BirthQueueRebuild),
; each through BirthQueueAdd (UnevolvedSkillMap, first 25 distinct); copied
; back to +$31; egg flag +$63 := 0. Measured S130 (400 births, 0 mismatches).
; =============================================================================
BreedBirthFinalize:
    ld hl, $cb21
    call LoadBrd_47e0
    xor a
    ld [hl+], a
    ld [hl], a
    ld hl, $cacd
    ld de, $ca42
    ld b, $08
    call SaveBrd_47e7
    ld hl, $cad5
    call LoadBrd_47e0
    ld a, [$ca4a]
    ld [hl], a
    ld hl, $c0d8
    ld bc, $0019
    ld a, $ff
    call FillNBytesWithRegA
    ld hl, $caca
    call LoadBrd_47e0
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call BirthQueueAddList
    ld hl, $cad6
    call LoadBrd_47e0
    ld a, [hl]
    cp $ff
    jr z, jr_016_47b9

    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call BirthQueueAddList
    ld hl, $cad7
    call LoadBrd_47e0
    ld a, [hl]
    ld [wTempSpeciesId], a
    ld hl, $0301
    rst $10
    ld de, $da39
    ld b, $03
    call BirthQueueAddList

jr_016_47b9:
    ld hl, $caf2
    call LoadBrd_47e0
    ld e, l
    ld d, h
    ld b, $19
    call BirthQueueRebuild
    ld hl, $caf2
    call LoadBrd_47e0
    ld de, $c0d8
    ld b, $19

jr_016_47d1:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_016_47d1

    ld hl, $cb24
    call LoadBrd_47e0
    ld [hl], $00
    ret


LoadBrd_47e0:
    ld a, [$cac0]
    call GetMonsterDataPtr
    ret


SaveBrd_47e7:
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


; [S130] BirthQueueAddList — B skill ids at DE -> BirthQueueAdd each.
BirthQueueAddList:
jr_016_47f8:
    ld a, [de]
    inc de
    push bc
    push de
    call BirthQueueAdd
    pop de
    pop bc
    dec b
    jr nz, jr_016_47f8

    ret


; [S130] BirthQueueRebuild — the old queue (B = 25 at DE = +$31). Per entry it
; rolls GenerateRNG, RNG16 mod 100 and compares with the plus +$62 — but the
; `jr jr_016_482b` below is UNCONDITIONAL (18 05), so the compare is never
; used: a DEAD "keep this skill by plus" roll that only steps the RNG 25
; times; every entry goes to BirthQueueAdd. The 5 bytes after the jr (the
; skip path) are unreachable.
BirthQueueRebuild:
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
    call LoadBrd_47e0
    pop bc
    ld a, [hl]
    cp b
    pop de
    pop bc
    jr jr_016_482b           ; [S130] unconditional: the roll above is dead

    inc de                   ; [S130] unreachable (the skip-this-entry path)
    dec b
    jr nz, jr_016_4805

    ret


jr_016_482b:
    ld a, [de]
    inc de
    push bc
    push de
    call BirthQueueAdd
    pop de
    pop bc
    dec b
    jr nz, jr_016_4805

    ret


; [S130] BirthQueueAdd — A = skill id ($FF = none) -> base =
; UnevolvedSkillMap[A] ($FF = never) -> into the 25-byte work list $C0D8
; unless present (first $FF hole). The $C0D8 twin of InheritOneSkill.
BirthQueueAdd:
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
    call FamilyRecipeResolve   ; FORK: id 221-239 -> the new species' display pair (S105 G3); else normal (byte-neutral 3+5)
    ds 5, $00
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
; @BUILD_PROJECT BEGIN gd_family_recipes
; (generated by editor2 `gd_family` from gamedata.breeding.family —
;  222 x [pedigree, mate]; slot = offspring species, $FF,$FF = none)
FamilyRecipeTable:  ; $4974 — indexed species*2 by label16_485c (no bounds
;  check; ids >= 221 go through FamilyRecipeResolve, S105 G3 — row 221 is never read). See BREEDING_SYSTEM.md.
    db $F3, $F1  ;   0 DrakSlime: [Bird] x [Dragon]  ; EDITED (project gamedata)
    db $F0, $F2  ;   1 SpotSlime: [Slime] x [Beast]
    db $F0, $F3  ;   2 WingSlime: [Slime] x [Bird]
    db $F0, $F4  ;   3 TreeSlime: [Slime] x [Plant]
    db $F0, $F5  ;   4 Snaily: [Slime] x [Bug]
    db $F0, $F6  ;   5 SlimeNite: [Slime] x [Devil]
    db $F0, $F7  ;   6 Babble: [Slime] x [Zombie]
    db $F0, $F8  ;   7 BoxSlime: [Slime] x [Material]
    db $FF, $FF  ;   8 Slime: (no recipe)
    db $F0, $5A  ;   9 Healer: [Slime] x MadPlant
    db $F0, $2E  ;  10 FangSlime: [Slime] x Almiraj
    db $F0, $C6  ;  11 RockSlime: [Slime] x BombCrag
    db $F0, $BD  ;  12 SlimeBorg: [Slime] x Roboster
    db $F0, $33  ;  13 Slabbit: [Slime] x Skullroo
    db $FF, $FF  ;  14 SpotKing: (no recipe)
    db $F0, $F9  ;  15 KingSlime: [Slime] x [Boss]
    db $F0, $B9  ;  16 Metaly: [Slime] x MetalDrak
    db $10, $10  ;  17 Metabble: Metaly x Metaly
    db $11, $11  ;  18 MetalKing: Metabble x Metabble
    db $12, $12  ;  19 GoldSlime: MetalKing x MetalKing
    db $F1, $F0  ;  20 DragonKid: [Dragon] x [Slime]
    db $F1, $F2  ;  21 Tortragon: [Dragon] x [Beast]
    db $F1, $F3  ;  22 Pteranod: [Dragon] x [Bird]
    db $F1, $F4  ;  23 Gasgon: [Dragon] x [Plant]
    db $F1, $F5  ;  24 FairyDrak: [Dragon] x [Bug]
    db $F1, $F6  ;  25 LizardMan: [Dragon] x [Devil]
    db $F1, $F7  ;  26 Poisongon: [Dragon] x [Zombie]
    db $F1, $F8  ;  27 Swordgon: [Dragon] x [Material]
    db $14, $14  ;  28 Dragon: DragonKid x DragonKid
    db $F1, $46  ;  29 MiniDrak: [Dragon] x Picky
    db $F1, $32  ;  30 MadDragon: [Dragon] x GulpBeast
    db $F1, $53  ;  31 Rayburn: [Dragon] x MadCondor
    db $F1, $B8  ;  32 Chamelgon: [Dragon] x Voodoll
    db $F1, $77  ;  33 LizardFly: [Dragon] x GoHopper
    db $F1, $5F  ;  34 Andreal: [Dragon] x Gulpple
    db $F1, $06  ;  35 KingCobra: [Dragon] x Babble
    db $F1, $7D  ;  36 Spikerous: [Dragon] x ArmyCrab
    db $F1, $F1  ;  37 GreatDrak: [Dragon] x [Dragon]  ; EDITED (project gamedata)
    db $F1, $4F  ;  38 Crestpent: [Dragon] x BigRoost
    db $26, $26  ;  39 WingSnake: Crestpent x Crestpent
    db $27, $27  ;  40 Coatol: WingSnake x WingSnake
    db $22, $8C  ;  41 Orochi: Andreal x MedusaEye
    db $F1, $8D  ;  42 BattleRex: [Dragon] x Lionex
    db $F1, $55  ;  43 SkyDragon: [Dragon] x Phoenix
    db $2B, $29  ;  44 Divinegon: SkyDragon x Orochi
    db $F2, $F0  ;  45 Tonguella: [Beast] x [Slime]
    db $F0, $F1  ;  46 Almiraj: [Slime] x [Dragon]  ; EDITED (project gamedata)
    db $F2, $F3  ;  47 CatFly: [Beast] x [Bird]
    db $F2, $F4  ;  48 PillowRat: [Beast] x [Plant]
    db $F2, $F5  ;  49 Saccer: [Beast] x [Bug]
    db $FF, $FF  ;  50 GulpBeast: (no recipe)
    db $F2, $F7  ;  51 Skullroo: [Beast] x [Zombie]
    db $F2, $F8  ;  52 WindBeast: [Beast] x [Material]
    db $FF, $FF  ;  53 Anteater: (no recipe)
    db $F2, $A4  ;  54 SuperTen: [Beast] x Mudron
    db $F2, $15  ;  55 IronTurt: [Beast] x Tortragon
    db $F2, $4A  ;  56 Mommonja: [Beast] x DuckKite
    db $F2, $62  ;  57 HammerMan: [Beast] x Stubsuck
    db $F2, $F6  ;  58 Grizzly: [Beast] x [Devil]
    db $F2, $8F  ;  59 Yeti: [Beast] x Orc
    db $F2, $BB  ;  60 MadGopher: [Beast] x SabreMan
    db $F2, $21  ;  61 FairyRat: [Beast] x LizardFly
    db $F2, $0A  ;  62 Unicorn: [Beast] x FangSlime
    db $F2, $00  ;  63 Goategon: [Beast] x DrakSlime
    db $F2, $4B  ;  64 WildApe: [Beast] x MadPecker
    db $40, $40  ;  65 Trumpeter: WildApe x WildApe
    db $41, $41  ;  66 KingLeo: Trumpeter x Trumpeter
    db $F2, $F9  ;  67 DarkHorn: [Beast] x [Boss]
    db $F2, $1C  ;  68 MadCat: [Beast] x Dragon
    db $F2, $87  ;  69 BigEye: [Beast] x EyeBall
    db $F3, $F0  ;  70 Picky: [Bird] x [Slime]
    db $F2, $F1  ;  71 Wyvern: [Beast] x [Dragon]  ; EDITED (project gamedata)
    db $F3, $F2  ;  72 BullBird: [Bird] x [Beast]
    db $F3, $F4  ;  73 Florajay: [Bird] x [Plant]
    db $F3, $F5  ;  74 DuckKite: [Bird] x [Bug]
    db $F3, $F6  ;  75 MadPecker: [Bird] x [Devil]
    db $F3, $F7  ;  76 MadRaven: [Bird] x [Zombie]
    db $F3, $F8  ;  77 MistyWing: [Bird] x [Material]
    db $FF, $FF  ;  78 Dracky: (no recipe)
    db $FF, $FF  ;  79 BigRoost: (no recipe)
    db $F3, $0B  ;  80 StubBird: [Bird] x RockSlime
    db $FF, $FF  ;  81 LandOwl: (no recipe)
    db $F3, $7C  ;  82 MadGoose: [Bird] x Droll
    db $F3, $B2  ;  83 MadCondor: [Bird] x CoilBird
    db $F3, $C1  ;  84 Blizzardy: [Bird] x IceMan
    db $F3, $BF  ;  85 Phoenix: [Bird] x Gismo
    db $F3, $F9  ;  86 ZapBird: [Bird] x [Boss]
    db $F3, $1F  ;  87 WhipBird: [Bird] x Rayburn
    db $F3, $64  ;  88 FunkyBird: [Bird] x DanceVegi
    db $54, $55  ;  89 RainHawk: Blizzardy x Phoenix
    db $F4, $F0  ;  90 MadPlant: [Plant] x [Slime]
    db $F4, $F1  ;  91 FireWeed: [Plant] x [Dragon]
    db $F4, $F2  ;  92 FloraMan: [Plant] x [Beast]
    db $F4, $F3  ;  93 WingTree: [Plant] x [Bird]
    db $F4, $F5  ;  94 CactiBall: [Plant] x [Bug]
    db $F4, $F6  ;  95 Gulpple: [Plant] x [Devil]
    db $F4, $F7  ;  96 Toadstool: [Plant] x [Zombie]
    db $F4, $F8  ;  97 AmberWeed: [Plant] x [Material]
    db $FF, $FF  ;  98 Stubsuck: (no recipe)
    db $F4, $70  ;  99 Oniono: [Plant] x Gophecada
    db $F4, $B3  ; 100 DanceVegi: [Plant] x Facer
    db $F4, $82  ; 101 TreeBoy: [Plant] x Pixy
    db $F4, $A5  ; 102 FaceTree: [Plant] x NiteWhip
    db $F4, $58  ; 103 HerbMan: [Plant] x FunkyBird
    db $F4, $30  ; 104 BeanMan: [Plant] x PillowRat
    db $F4, $86  ; 105 EvilSeed: [Plant] x DarkEye
    db $69, $69  ; 106 ManEater: EvilSeed x EvilSeed
    db $6A, $6A  ; 107 Snapper: ManEater x ManEater
    db $F4, $F9  ; 108 Rosevine: [Plant] x [Boss]
    db $FF, $FF  ; 109 Watabou: (no recipe)
    db $F5, $F0  ; 110 GiantSlug: [Bug] x [Slime]
    db $F5, $F1  ; 111 Catapila: [Bug] x [Dragon]
    db $F5, $F2  ; 112 Gophecada: [Bug] x [Beast]
    db $F5, $F3  ; 113 Butterfly: [Bug] x [Bird]
    db $F5, $F4  ; 114 WeedBug: [Bug] x [Plant]
    db $F5, $F6  ; 115 GiantWorm: [Bug] x [Devil]
    db $F5, $F7  ; 116 Lipsy: [Bug] x [Zombie]
    db $F5, $F8  ; 117 StagBug: [Bug] x [Material]
    db $FF, $FF  ; 118 ArmyAnt: (no recipe)
    db $FF, $FF  ; 119 GoHopper: (no recipe)
    db $F5, $5C  ; 120 TailEater: [Bug] x FloraMan
    db $F5, $37  ; 121 ArmorPede: [Bug] x IronTurt
    db $F5, $61  ; 122 Eyeder: [Bug] x AmberWeed
    db $F5, $31  ; 123 GiantMoth: [Bug] x Saccer
    db $F5, $9B  ; 124 Droll: [Bug] x Spooky
    db $F5, $A0  ; 125 ArmyCrab: [Bug] x DarkCrab
    db $F5, $3D  ; 126 MadHornet: [Bug] x FairyRat
    db $75, $75  ; 127 HornBeet: StagBug x StagBug
    db $7F, $7F  ; 128 Armorpion: HornBeet x HornBeet
    db $F5, $F9  ; 129 Digster: [Bug] x [Boss]
    db $F6, $F0  ; 130 Pixy: [Devil] x [Slime]
    db $F6, $F9  ; 131 ArcDemon: [Devil] x [Boss]
    db $FF, $FF  ; 132 AgDevil: (no recipe)
    db $F6, $F3  ; 133 Demonite: [Devil] x [Bird]
    db $F6, $F4  ; 134 DarkEye: [Devil] x [Plant]
    db $F6, $F5  ; 135 EyeBall: [Devil] x [Bug]
    db $F6, $F7  ; 136 SkulRider: [Devil] x [Zombie]
    db $F6, $F8  ; 137 EvilBeast: [Devil] x [Material]
    db $FF, $FF  ; 138 1EyeClown: (no recipe)
    db $F6, $F2  ; 139 Gremlin: [Devil] x [Beast]
    db $F6, $F1  ; 140 MedusaEye: [Devil] x [Dragon]
    db $F6, $19  ; 141 Lionex: [Devil] x LizardMan
    db $F6, $43  ; 142 GoatHorn: [Devil] x DarkHorn
    db $F6, $68  ; 143 Orc: [Devil] x BeanMan
    db $F6, $39  ; 144 Ogre: [Devil] x HammerMan
    db $85, $85  ; 145 GateGuard: Demonite x Demonite
    db $8A, $8A  ; 146 ChopClown: 1EyeClown x 1EyeClown
    db $F6, $1E  ; 147 Grendal: [Devil] x MadDragon
    db $93, $93  ; 148 Akubar: Grendal x Grendal
    db $F6, $B6  ; 149 MadKnight: [Devil] x RogueNite
    db $F6, $45  ; 150 Gigantes: [Devil] x BigEye
    db $FF, $FF  ; 151 Centasaur: (no recipe)
    db $F6, $79  ; 152 EvilArmor: [Devil] x ArmorPede
    db $94, $59  ; 153 Jamirus: Akubar x RainHawk
    db $97, $C7  ; 154 Durran: Centasaur x GoldGolem
    db $F7, $F0  ; 155 Spooky: [Zombie] x [Slime]
    db $F7, $1B  ; 156 Skullgon: [Zombie] x Swordgon
    db $F7, $F2  ; 157 Putrepup: [Zombie] x [Beast]
    db $F7, $F3  ; 158 RotRaven: [Zombie] x [Bird]
    db $F7, $F4  ; 159 Mummy: [Zombie] x [Plant]
    db $F7, $F5  ; 160 DarkCrab: [Zombie] x [Bug]
    db $F7, $F6  ; 161 DeadNite: [Zombie] x [Devil]
    db $F7, $F8  ; 162 Shadow: [Zombie] x [Material]
    db $FF, $FF  ; 163 Hork: (no recipe)
    db $F7, $6E  ; 164 Mudron: [Zombie] x GiantSlug
    db $F7, $4D  ; 165 NiteWhip: [Zombie] x MistyWing
    db $F7, $F1  ; 166 MadSpirit: [Zombie] x [Dragon]
    db $F7, $34  ; 167 WindMerge: [Zombie] x WindBeast
    db $F7, $72  ; 168 Reaper: [Zombie] x WeedBug
    db $A1, $A1  ; 169 DeadNoble: DeadNite x DeadNite
    db $F7, $F9  ; 170 WhiteKing: [Zombie] x [Boss]
    db $A3, $A3  ; 171 BoneSlave: Hork x Hork
    db $AB, $AB  ; 172 Skeletor: BoneSlave x BoneSlave
    db $AC, $AC  ; 173 Servant: Skeletor x Skeletor
    db $FF, $FF  ; 174 Copycat: (no recipe)
    db $F8, $F0  ; 175 JewelBag: [Material] x [Slime]
    db $F8, $F1  ; 176 EvilWand: [Material] x [Dragon]
    db $F8, $F2  ; 177 MadCandle: [Material] x [Beast]
    db $F8, $F3  ; 178 CoilBird: [Material] x [Bird]
    db $F8, $F4  ; 179 Facer: [Material] x [Plant]
    db $F8, $F5  ; 180 SpikyBoy: [Material] x [Bug]
    db $F8, $F6  ; 181 MadMirror: [Material] x [Devil]
    db $F8, $F7  ; 182 RogueNite: [Material] x [Zombie]
    db $FF, $FF  ; 183 Goopi: (no recipe)
    db $F8, $74  ; 184 Voodoll: [Material] x Lipsy
    db $F8, $22  ; 185 MetalDrak: [Material] x Andreal
    db $F8, $F9  ; 186 Balzak: [Material] x [Boss]
    db $F8, $73  ; 187 SabreMan: [Material] x GiantWorm
    db $F8, $5D  ; 188 CurseLamp: [Material] x WingTree
    db $F8, $88  ; 189 Roboster: [Material] x SkulRider
    db $F8, $04  ; 190 EvilPot: [Material] x Snaily
    db $B7, $5B  ; 191 Gismo: Goopi x FireWeed
    db $B9, $83  ; 192 LavaMan: MetalDrak x ArcDemon
    db $BD, $42  ; 193 IceMan: Roboster x KingLeo
    db $F8, $07  ; 194 Mimic: [Material] x BoxSlime
    db $B7, $B7  ; 195 MudDoll: Goopi x Goopi
    db $C3, $C3  ; 196 Golem: MudDoll x MudDoll
    db $C4, $C4  ; 197 StoneMan: Golem x Golem
    db $B4, $B4  ; 198 BombCrag: SpikyBoy x SpikyBoy
    db $C1, $C0  ; 199 GoldGolem: IceMan x LavaMan
    db $AD, $25  ; 200 DracoLord: Servant x GreatDrak
    db $C8, $2C  ; 201 DracoLord: DracoLord x Divinegon
    db $AA, $12  ; 202 Hargon: WhiteKing x MetalKing
    db $99, $6C  ; 203 Sidoh: Jamirus x Rosevine
    db $CA, $29  ; 204 Baramos: Hargon x Orochi
    db $C8, $CB  ; 205 Zoma: DracoLord x Sidoh
    db $9A, $2C  ; 206 Pizzaro: Durran x Divinegon
    db $CE, $42  ; 207 Esterk: Pizzaro x KingLeo
    db $CF, $13  ; 208 Mirudraas: Esterk x GoldSlime
    db $D0, $24  ; 209 Mirudraas: Mirudraas x Spikerous
    db $CC, $43  ; 210 Mudou: Baramos x DarkHorn
    db $CD, $D0  ; 211 DeathMore: Zoma x Mirudraas
    db $D3, $80  ; 212 DeathMore: DeathMore x Armorpion
    db $D4, $D2  ; 213 DeathMore: DeathMore x Mudou
    db $D5, $6D  ; 214 Darkdrium: DeathMore x Watabou
    db $FF, $FF  ; 215 TERRY?: (no recipe)
    db $FF, $FF  ; 216 Tatsu: (no recipe)
    db $FF, $FF  ; 217 Diago: (no recipe)
    db $FF, $FF  ; 218 Samsi: (no recipe)
    db $FF, $FF  ; 219 Bazoo: (no recipe)
    db $FF, $FF  ; 220 : (no recipe)
    db $00, $00  ; 221 : (terminator)
; @BUILD_PROJECT END gd_family_recipes
SpecialRecipeTable:  ; $4B30 — 825 entries x 5 bytes, $FF terminated
    db $00, $1b, $00, $0c
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
    db $89, $f7, $00, $96, $00, $8b, $f7, $00, $96, $00, $8c, $f7, $00, $96, $00, $83  ; entry 693 at $58B9 = vanilla again (P3.9b S105; was the S12 Anteater x BattleRex -> GoldSlime POC, runtime-dead since B2)
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
    db $00, $f4, $b5, $00, $69, $00, $f7, $1b, $00, $9c, $00, $f7, $1b, $00, $9c, $00  ; entry 803 at $5ADF = vanilla again (P3.9b S105; was the S12 mirror POC)
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
    ; --- gate row fork (S115, ROADMAP NG1 new gates) ----------------------
    ; Original 15 bytes: ld a,[wGateID] / add a x3 / ld hl,GateFloorDataTable
    ; / add l / ld l,a / ld a,$00 / adc h / ld h,a — an 8-bit gate*8, so a
    ; gate number >= 32 wrapped to gate (n & 31). Replaced IN PLACE (15 -> 15
    ; bytes): GateRowPtr returns HL -> the gate's 8-byte row (the vanilla
    ; table for 0-31, wGateRowBuf for a project new gate, the old wrap
    ; otherwise). A is reloaded by the next instruction.
    call GateRowPtr
    ds 12, $00                    ; nops (the rest of the original 15 bytes)
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

    ; --- gate-decision fork (S41 Pillar B; data-driven since S100) ---------
    ; Original 6 bytes here were the gate-0 exclusion:
    ;     ld a,[wGateID] / or a / jr z, jr_016_5bbf   (FA 35 C9 B7 28 xx)
    ; Replaced IN PLACE (6 bytes -> 6 bytes, no shift) with a call to a fork
    ; that keeps gate 0 on the standard maze and serves project-authored
    ; custom rooms (custom.gate_inserts[] -> bank $71 entry 4). Every other
    ; case RETs to the nops, then the vanilla special-room gating below —
    ; which tests wRNG1 bit 4 AND wCurrentFloor mod 3 == 2 (Div8x8 divides
    ; B = wCurrentFloor; S100).
    call GateDecisionFork
    nop
    nop
    nop

    ld a, [wRNG1]                 ; special-room gate (S100, PyBoy-measured):
    bit 4, a                      ;   wRNG1 bit 4 set (~50 %) AND
    jr z, jr_016_5bbf

    ld a, $03                     ;   Div8x8 divides B = wCurrentFloor (loaded
    call Div8x8                   ;   above) by 3 -> A = floor mod 3, so special
    cp $02                        ;   rooms appear only on floors 3, 6, 9 ...
    jr z, jr_016_5c1c             ;   (1-based) — NOT "RNG mod 3"

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


; BOSS FLOOR (S101 notes): the boss room is fixed per gate — no RNG. Byte 4 =
; the map id, bytes 5/6 = ABSOLUTE TILE coords b (pixels = 16*b + 8, so any
; cell of a 4x4-screen room). The room is shown with wInGateworld = 0 (the
; special-room contract); wBossMapType is also read by LoadNewBGMIdIntoA on
; the floor BEFORE the boss floor (RoomBGMTable[wBossMapType]).
jr_016_5be1:
    ; gate row fork (S115, 15 -> 15 bytes; see jr_016_5b72): HL -> row + 4
    call GateRowPtr
    inc hl
    inc hl
    inc hl
    inc hl
    push hl                       ; S140 (ROADMAP ARC CAP3a): enter the region of
    ld hl, $710b                  ;   this gate's boss room — bank $71 entry 11
    rst $10                       ;   BossRegionEnter (GateBossRegionTable; in the
    pop hl                        ;   8 nop bytes the S115 fork left; D / E are
    nop                           ;   dead here)
    nop
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
SpecialRoomTable:               ; S120: wFloorType2 (rolled from FloorTypeSelectionTable2) -> the special room
    dw SpecialRoom0_Treasure, SpecialRoom1_OneRareChest, SpecialRoom2_ForestMaze
    dw SpecialRoom3_Priest, SpecialRoom4_ItemShop, SpecialRoom5_Coliseum
    dw SpecialRoom6_Maze, SpecialRoom7_Conveyor

SpecialRoom0_Treasure:                 ; pick 0: treasure room; the 8 chests filled from FloorLayoutData[wFloorType3] (SetBrd_6db0)
    call SetBrd_6db0

LoadBrd_5c45:
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


SpecialRoom1_OneRareChest:                 ; pick 1: treasure room; chests $D9CF-$D9D6 empty but one (index 0-3) = an item of the 16 at $6E04
    ld hl, $d9cf
    ld bc, $0008
    ld a, $ff
    call FillNBytesWithRegA
    call CallBrd_6ddb
    call LoadBrd_5c45
    ret


SpecialRoom2_ForestMaze:                 ; pick 2: Forest maze $53
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


SpecialRoom3_Priest:                 ; pick 3: the priest $51
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


SpecialRoom4_ItemShop:                 ; pick 4: the gate item shop $50
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


SpecialRoom5_Coliseum:                 ; pick 5: Coliseum $52 — three battle teams rolled into $D9D1-$D9DA first
    xor a
    ld [$d9cf], a
    ld [$d9d0], a
    call SetBrd_5e38
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
    call SetBrd_5e38
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
    call SetBrd_5e38
    ld hl, $d7ca
    call SaveBrd_5dc6
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


SaveBrd_5dc6:
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
    call SetBrd_5e2e
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
    call SetBrd_5e2e
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
    call SetBrd_5e2e
    pop hl
    ld [hl+], a
    ld a, $01
    ld [hl+], a
    ret


SetBrd_5e2e:
    ld hl, $1401
    rst $10
    ld a, [$da18]
    add $10
    ret


SetBrd_5e38:
    ld hl, $0000
    ld c, $00
    ld a, [$ca8e]
    call CmpBrd_5e91
    ld a, [$ca8f]
    call CmpBrd_5e91
    ld a, [$ca90]
    call CmpBrd_5e91
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

    ld hl, AudioReadE5Bit7
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

CmpBrd_5e91:
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
    call SaveBrd_5ec9
    ld [wTempEnemyId1], a
    call SaveBrd_5ec9
    ld [$da05], a
    call SaveBrd_5ec9
    ld [$da07], a
    xor a
    ld [$da04], a
    ld [$da06], a
    ld [$da08], a
    ret


SaveBrd_5ec9:
    push hl
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, l
    call Div8x8
    pop hl
    add h
    ret


SpecialRoom6_Maze:                 ; pick 6: Maze 1 / 2 / 3 ($57-$59, wRNG1 mod 3)
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


SpecialRoom7_Conveyor:                 ; pick 7: Conveyor maze 1 / 2 / 3 ($54-$56, wRNG1 mod 3)
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


; Entry 6 — far-called by bank $0B Entry 0 at EVERY room load (post-battle
; reloads included, gate or not): re-seeds the encounter counter FIRST, then
; (outside gates) resets the floor-content bytes, or (gate floors) loads the
; map-overview tiles. So custom rooms are seeded by the engine too — measured
; S114 on the user's save (the S11 "never seeded when wInGateworld = 0" claim was
; wrong; DOC_AUDIT S114).
EncounterSeedOnRoomLoad:
label16_5fe4:  ; original label
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
    ld a, [$c8ea]
    bit 7, a
    jr z, label16_605b

    xor a
    ld [$c8ec], a
    ret

; MazeShapeModes (S122): the floor's shape mode = this[wRNG1 mod 5] -> $C93F:
; 0 carve (3/5), 1 carve with the plain variant 12 of every piece, 2 a
; ready-made pattern (MazePatterns, drawn from MazeScreenTableB / GateAttrTable_B).
MazeShapeModes:
    db $00, $00, $00, $01, $02

MazeBuildFloor:
label16_605b:  ; original label (docs cite it)
    call GenerateRNG
    ld a, [wRNG1]
    ld b, a
    ld a, $05
    call Div8x8
    ld hl, MazeShapeModes
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
    add LOW(MazePatterns)
    ld l, a
    ld a, h
    adc HIGH(MazePatterns)
    ld h, a
    ld de, $c940
    ld b, $10

jr_016_60b0:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_016_60b0

    jp MazePlacements


jr_016_60b9:
    ld hl, MazeCellOrder
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
    call MazePickPiece
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
    call MazeCellConstraints
    ld a, b
    or a
    ld a, $ff
    jr z, jr_016_6102

    call MazePickPiece

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

    ld hl, MazeCellOrder
    ld b, $10

jr_016_611a:
    push hl
    ld a, [hl]
    cp $ff
    jr z, jr_016_6140

    ld c, a
    push bc
    call MazeCellConstraints
    ld a, b
    or a
    ld a, $0f
    jr z, jr_016_6132

    ld a, b
    xor $0f
    ld c, a
    call MazePickPiece

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

; ---------------------------------------------------------------------------
; MazePlacements (was Jump_016_616c; S122, PyBoy-proved — every field of 4,000
; forced floors == editor2/core/maze.py). After the grid: (1) the down-stairs
; ($C960 screen, $C962/$C963 tile offset for bank $0B's stamp, $C964-$C967
; absolute pixels) — MazePickStairsSpot, kept only if MazeStairsPassable;
; (2) the wandering NPC ($C926 screen, $C927-$C92A pixels, $C92B kind /
; $C92C sub-kind — bank $0B GatePtrTable_42c8) — MazePickNPCSpot on another
; screen, then kept / dropped by $CAB4, $C92D and MazeNPCChance[wFloorType3];
; (3) the player's arrival (wWarpSpawn, $C0A0-$C0A4) — MazePickArrivalSpot,
; not the stairs spot nor the NPC's screen; (4) the floor items (MazePlaceItem
; x the count from FloorTypeSelectionTable3 bytes 9-11 of the contents row,
; halved when fewer than 6 cells are used) into the list at $D793. Each of
; (1)-(3) gets 64 tries ($C0A9); running out regenerates the WHOLE floor from
; MazeBuildFloor with the RNG as it stands.
; ---------------------------------------------------------------------------
MazePlacements:
    ld a, $40
    ld [$c0a9], a

jr_016_6171:
    ld a, [$c0a9]
    dec a
    ld [$c0a9], a
    jp z, MazeBuildFloor

    call MazePickStairsSpot
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
    call MazeStairsPassable
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
    ld hl, ScreenOriginTable
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
    jp z, MazeBuildFloor

    call MazePickNPCSpot
    ld a, [$c960]
    ld b, a
    ld a, [wScreenIndex]
    cp b
    jr z, jr_016_620a

    ld a, [wScreenIndex]
    ld [$c926], a
    add a
    add a
    ld hl, ScreenOriginTable
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
    ld hl, MazeNPCChance
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
    jp z, MazeBuildFloor

    call MazePickArrivalSpot
    ld hl, $c960
    ld a, [wScreenIndex]
    cp [hl]
    jr nz, jr_016_62f1

    call MazePickArrivalSpot

jr_016_62f1:
    ld a, [wScreenIndex]
    ld [$c0af], a
    call MazeAtStairs
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
    ld hl, ScreenOriginTable
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
    ld hl, FloorTypeSelectionTable3 + 9 ; bytes 9-11 of the contents row: item count base, range, blocking %
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
    call MazePlaceItem
    pop bc
    dec b
    jr nz, jr_016_63a2

jr_016_63ac:
    ld [hl], $ff
    ret


; ---------------------------------------------------------------------------
; MazePickItemSpot (was CallBrd_63af; S122). A random non-empty screen
; (wScreenIndex: wRNG1 + 1, + 1 … mod 16, skipping $Fx cells), its layout
; decoded to $C300 (bank $0B entry 8 = the gate step reader), then random
; metatiles x = (wRNG1 mod 8 + 1)*16 + 8, y = (wRNG1 mod 6 + 1)*16 + 8 into
; $FFA5-$FFA8 until TileAtPixel's tile (the metatile's BOTTOM-RIGHT 8x8) is
; class $0C / $0D (tile ids $30-$37). No try limit. MazePickNPCSpot /
; MazePickArrivalSpot / MazePickStairsSpot are the same with other ranges,
; classes and a 64-try limit per screen ($FFD5) before the next screen.
; ---------------------------------------------------------------------------
MazePickItemSpot:
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
    call TileAtPixel
    ldh a, [$aa]
    srl a
    srl a
    cp $0c
    ret z

    cp $0d
    ret z

    jr jr_016_63e1

; ---------------------------------------------------------------------------
; MazePlaceItem (was SaveBrd_6432; S122, PyBoy-proved). HL = the next slot of
; the item list at $D793 (4 B: kind, sub-kind, X metatile, Y metatile —
; absolute, X = screen col*10 + x, Y = screen row*8 + y). Kind = SelectFloorType
; over the contents row (FloorTypeSelectionTable3[wFloorType3]); + $10 when
; (wRNG2:wRNG1) mod 100 < row byte 11 (the blocking variant, which must pass
; MazeItemPassable). 15 tries ($C0A9 = $10, decremented first): a spot from
; MazePickItemSpot (re-picked once each if on the stairs screen, the arrival
; screen or a screen already holding an item), refused when it is the stairs
; spot, the arrival spot, the same SCREEN + ROW (Y) as an earlier item
; (MazeItemRowTaken — X is not compared), the NPC's screen or the 4th item of a
; screen ($C100[screen] counts). Sub-kind = MazeItemSubKind[kind & $0F], or —
; when that is 1 — SelectFloorType over the 48-byte FloorLayoutData row of
; wFloorType3. Out of tries = no item (HL unchanged).
; ---------------------------------------------------------------------------
MazePlaceItem:
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
    call MazePickItemSpot
    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c960]
    cp b
    jr nz, jr_016_6488

    call MazePickItemSpot

jr_016_6488:
    ld a, [wScreenIndex]
    ld b, a
    ld a, [$c0af]
    cp b
    jr nz, jr_016_6495

    call MazePickItemSpot

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

    call MazePickItemSpot

jr_016_64a8:
    ldh a, [$a5]
    ld [$c0aa], a
    ldh a, [$a6]
    ld [$c0ab], a
    ldh a, [$a7]
    ld [$c0ac], a
    ldh a, [$a8]
    ld [$c0ad], a
    call MazeItemPassable
    jr z, jr_016_646d

    ld a, [$c0aa]
    ldh [$a5], a
    ld a, [$c0ab]
    ldh [$a6], a
    ld a, [$c0ac]
    ldh [$a7], a
    ld a, [$c0ad]
    ldh [$a8], a
    call MazeAtStairs
    jr z, jr_016_646d

    call MazeAtArrival
    jr z, jr_016_646d

    call MazeItemRowTaken
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
    ld hl, ScreenOriginTable
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
    ld hl, MazeItemSubKind
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
    add LOW(FloorLayoutData)
    ld l, a
    ld a, h
    adc HIGH(FloorLayoutData)
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


MazePickNPCSpot:
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
    call TileAtPixel
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


MazePickArrivalSpot:
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
    call TileAtPixel
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


MazePickStairsSpot:
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
    call TileAtPixel
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


; ---------------------------------------------------------------------------
; MazeCellConstraints (was SetBrd_6744; S122, PyBoy-proved — tools/census_maze.py)
; A = a grid cell 0-15. Returns B = openings the cell MUST have, C = openings
; it must NOT have (bits: 8 up, 4 down, 2 left, 1 right — MazePieceTable).
; Per side: off the 4x4 grid -> C; neighbour empty ($FF) -> free; neighbour
; placed and opening toward this cell -> B, else -> C. Clobbers BC/DE/HL.
; ---------------------------------------------------------------------------
MazeCellConstraints:
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
    ld hl, MazePieceTable
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
    ld hl, MazePieceTable
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
    ld hl, MazePieceTable
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
    ld hl, MazePieceTable
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


; ---------------------------------------------------------------------------
; MazePickPiece (was SetBrd_6800; S122, PyBoy-proved). B = required openings,
; C = forbidden ones (MazeCellConstraints). Lists every MazePieceTable row with
; all of B and none of C at $C500 as [piece, weight class] pairs ($FF $FF end),
; counts the rows per class 0-4 at $C0A0+, gives each row the share
; 20*class / count-of-its-class (class 0 = 0), turns the shares into a running
; 8-bit sum, rolls (wRNG2:wRNG1) mod sum and returns A = the first piece whose
; sum >= the roll; $0F (the closed piece) when the list is empty — or when a
; running sum happens to equal $FF, which the scan reads as the list end.
; ---------------------------------------------------------------------------
MazePickPiece:
    ld de, $c500
    ld hl, MazePieceTable

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


; MazeAtStairs (was SetBrd_68c6; S122): Z = wScreenIndex / $FFA5-$FFA8 are the
; stairs spot ($C960 / $C0A5-$C0A8). MazeAtArrival: the same for the arrival
; ($C0A0 / $C0A1-$C0A4).
MazeAtStairs:
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


MazeAtArrival:
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


; MazeItemRowTaken (was SetBrd_690e; S122): Z = an item already in the $D793
; list sits on wScreenIndex in the same ROW (MazeItemRowMatch decodes its X/Y
; metatile back to screen + pixel Y; X is never compared).
MazeItemRowTaken:
    ld hl, $d793

jr_016_6911:
    ld a, [hl]
    cp $ff
    jr nz, jr_016_6918

    or a
    ret


jr_016_6918:
    push hl
    call MazeItemRowMatch
    pop hl
    ret z

    inc hl
    inc hl
    inc hl
    inc hl
    jr jr_016_6911

MazeItemRowMatch:
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


MazeItemPassable:
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
    ld a, b
    ld [$c0b8], a
    jp MazePassableTest


; ---------------------------------------------------------------------------
; MazeStairsPassable (was LoadBrd_6afb; S122). The 3x3 metatiles around the
; stairs spot ($C0A5-$C0A8) -> $C0B0-$C0B8 (0 = walkable class $0C-$0E, 1 =
; blocked; NW N NE / W centre E / SW S SE) via MazeSpotBlocked, then
; MazePassableTest. MazeItemPassable (was LoadBrd_6955) is the same around
; $C0AA-$C0AD, skipped (passable) for item kinds below $10.
; ---------------------------------------------------------------------------
MazeStairsPassable:
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
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
    call MazeSpotBlocked
    ld a, b
    ld [$c0b8], a

; MazePassableTest (was Jump_016_6c96; S122): NZ = an object at the centre
; leaves its walkable neighbours connected, Z = it would cut a passage (e.g. W
; blocked and any of NE/E/SE blocked; a blocked corner with an open side
; between it and another blocked cell …). editor2/core/maze.py _passable.
MazePassableTest:
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


; MazeSpotBlocked (was CallBrd_6d99; S122): B = 0 when TileAtPixel's tile at
; $FFA5-$FFA8 is class $0C / $0D / $0E (ids $30-$3B), else 1.
MazeSpotBlocked:
    call TileAtPixel
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


SetBrd_6db0:
    ld hl, $d9cf
    ld b, $08

jr_016_6db5:
    push bc
    push hl
    call LoadBrd_6dc1
    pop hl
    pop bc
    ld [hl+], a
    dec b
    jr nz, jr_016_6db5

    ret


LoadBrd_6dc1:
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
    add LOW(FloorLayoutData)
    ld l, a
    ld a, h
    adc HIGH(FloorLayoutData)
    ld h, a
    call SelectFloorType
    ret


CallBrd_6ddb:
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
; After PRNG mod 101, the result selects the encounter COUNTER before
; the next random encounter. Format per entry:
;   byte 0: PRN threshold (if PRNG result <= this, select entry)
;   byte 1: $00 (padding)
;   bytes 2-3: counter (little-endian 16-bit) — counter UNITS, not steps:
;   steps = counter / the per-step drain (base * modifier / 64; S114). The
;   "-> n steps" row comments below are counter units (mean about 3,547).
; Last entry uses $FF threshold as catch-all.
; ---------------------------------------------------------------
RandomEncounterCounterTable:
    db $02, $00, $4c, $04 ;  3/101 chance → 1,100 (counter)
    db $04, $00, $b0, $04 ;  2/101 chance → 1,200 (counter)
    db $06, $00, $14, $05 ;  2/101 chance → 1,300 (counter)
    db $08, $00, $78, $05 ;  2/101 chance → 1,400 (counter)
    db $0a, $00, $dc, $05 ;  2/101 chance → 1,500 (counter)
    db $0c, $00, $40, $06 ;  2/101 chance → 1,600 (counter)
    db $0e, $00, $a4, $06 ;  2/101 chance → 1,700 (counter)
    db $10, $00, $08, $07 ;  2/101 chance → 1,800 (counter)
    db $12, $00, $6c, $07 ;  2/101 chance → 1,900 (counter)
    db $14, $00, $d0, $07 ;  2/101 chance → 2,000 (counter)
    db $16, $00, $34, $08 ;  2/101 chance → 2,100 (counter)
    db $18, $00, $98, $08 ;  2/101 chance → 2,200 (counter)
    db $1a, $00, $fc, $08 ;  2/101 chance → 2,300 (counter)
    db $1c, $00, $60, $09 ;  2/101 chance → 2,400 (counter)
    db $1e, $00, $c4, $09 ;  2/101 chance → 2,500 (counter)
    db $20, $00, $28, $0a ;  2/101 chance → 2,600 (counter)
    db $22, $00, $8c, $0a ;  2/101 chance → 2,700 (counter)
    db $24, $00, $f0, $0a ;  2/101 chance → 2,800 (counter)
    db $26, $00, $54, $0b ;  2/101 chance → 2,900 (counter)
    db $28, $00, $b8, $0b ;  2/101 chance → 3,000 (counter)
    db $2a, $00, $1c, $0c ;  2/101 chance → 3,100 (counter)
    db $2c, $00, $80, $0c ;  2/101 chance → 3,200 (counter)
    db $2e, $00, $e4, $0c ;  2/101 chance → 3,300 (counter)
    db $30, $00, $48, $0d ;  2/101 chance → 3,400 (counter)
    db $32, $00, $ac, $0d ;  2/101 chance → 3,500 (counter)
    db $34, $00, $10, $0e ;  2/101 chance → 3,600 (counter)
    db $36, $00, $74, $0e ;  2/101 chance → 3,700 (counter)
    db $38, $00, $d8, $0e ;  2/101 chance → 3,800 (counter)
    db $3a, $00, $3c, $0f ;  2/101 chance → 3,900 (counter)
    db $3c, $00, $a0, $0f ;  2/101 chance → 4,000 (counter)
    db $3e, $00, $04, $10 ;  2/101 chance → 4,100 (counter)
    db $40, $00, $68, $10 ;  2/101 chance → 4,200 (counter)
    db $42, $00, $cc, $10 ;  2/101 chance → 4,300 (counter)
    db $44, $00, $30, $11 ;  2/101 chance → 4,400 (counter)
    db $46, $00, $94, $11 ;  2/101 chance → 4,500 (counter)
    db $48, $00, $f8, $11 ;  2/101 chance → 4,600 (counter)
    db $4a, $00, $5c, $12 ;  2/101 chance → 4,700 (counter)
    db $4c, $00, $c0, $12 ;  2/101 chance → 4,800 (counter)
    db $4e, $00, $24, $13 ;  2/101 chance → 4,900 (counter)
    db $50, $00, $88, $13 ;  2/101 chance → 5,000 (counter)
    db $52, $00, $ec, $13 ;  2/101 chance → 5,100 (counter)
    db $54, $00, $50, $14 ;  2/101 chance → 5,200 (counter)
    db $56, $00, $b4, $14 ;  2/101 chance → 5,300 (counter)
    db $58, $00, $18, $15 ;  2/101 chance → 5,400 (counter)
    db $5a, $00, $7c, $15 ;  2/101 chance → 5,500 (counter)
    db $5c, $00, $e0, $15 ;  2/101 chance → 5,600 (counter)
    db $5e, $00, $44, $16 ;  2/101 chance → 5,700 (counter)
    db $60, $00, $a8, $16 ;  2/101 chance → 5,800 (counter)
    db $62, $00, $0c, $17 ;  2/101 chance → 5,900 (counter)
    db $ff, $00, $70, $17 ;  catch-all   → 6,000 (counter)


; Entry 8 — the encounter step, run once per step in an encounter room (gate
; maze floors via the bank $0B gate exit handler; whitelisted maps / custom rooms
; with encounters via bank $0B Jump_00b_4674 / CustomRoomEncCheck): base rate
; (outside gates $64, $50 on maps $54-$56; on gate floors EncounterRateData by
; floor type and the tile row class), then bank $01 entry $0D (the list +
; its rate code -> wC8A9), drain = base * modifier / 64; underflow = a battle
; (bank $01 entry $0B). Measured S114: 100 per step at code 3, 200 at code 7.
EncounterStep:
label16_6f05:  ; original label
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
    ld hl, EncounterRateData
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
    jr z, CheckRandomEncounterThreshold

    inc hl
    inc hl
    cp $0d
    jr z, CheckRandomEncounterThreshold

    inc hl
    inc hl
    cp $0e
    jr z, CheckRandomEncounterThreshold

    ret


CheckRandomEncounterThreshold:
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
; The step's BASE rate on gate maze floors, indexed wMapID * 8 (= the floor
; TYPE there): word 0 / 1 / 2 by the class of the tile row the player stands
; on ($0C / $0D / $0E — other rows: no encounter check). (S114 correction: not
; "per gate-floor threshold".)
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
; Indexed by wC8A9 = the encounter LIST's rate code (+0), loaded by bank $01
; entry $0D at every step (S114).
; Multiplied with encounter counter to determine encounter rate.
; ---------------------------------------------------------------
EncounterRateModifierTable:
    db $10, $15, $20, $40, $50, $60, $70, $80

LoadFloorDataPointer:
    ld de, MazeScreenTable
    ld a, [$c93f]
    cp $02
    jr nz, jr_016_7040

    ld de, MazeScreenTableB

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
; MazePieceTable (was "FloorTypeSortData" — S122, PyBoy-proved) — 16 × 4 B +
; $FF: [openings, piece, weight class, 0]. A maze piece = which sides of a
; screen are open: 8 up, 4 down, 2 left, 1 right; rows are in piece order
; (MazeCellConstraints reads row [piece] byte 0). Piece $0F opens nowhere =
; an empty screen (cell $Fx). Weight class 0-4 -> MazePickPiece shares.
; The "type / idx / weight" column labels below read the old names.
; ---------------------------------------------------------------
MazePieceTable:
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
; MazeCellOrder (was "FloorTypeOrderTable" — S122): the order in which the
; carve visits the 16 grid cells (cell 5 first). The first 1 + [$C93D] cells
; get pieces, then every cell is re-fitted in this order.
; ---------------------------------------------------------------
MazeCellOrder:
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
; @BUILD_PROJECT BEGIN gate_floor_table
; (generated by editor2 `gates16` from custom.gates[] — vanilla rows until edited)
GateFloorDataTable:
    db $00, $00, $00, $05, $30, $07, $02, $01  ; Gate of Beginning (last floor: 5)
    db $01, $01, $01, $05, $31, $01, $06, $01  ; Gate of Villager (last floor: 5)
    db $01, $01, $02, $06, $32, $05, $01, $01  ; Gate of Talisman (last floor: 6)
    db $02, $01, $02, $05, $33, $04, $06, $01  ; Gate of Memories (last floor: 5)
    db $02, $02, $03, $06, $34, $00, $07, $01  ; Gate of Bewilder (last floor: 6)
    db $03, $02, $03, $09, $35, $01, $06, $01  ; Bazaar Gate (last floor: 9)
    db $03, $02, $04, $08, $36, $05, $01, $02  ; Gate of Peace (last floor: 8)
    db $03, $03, $04, $09, $37, $05, $07, $02  ; Gate of Bravery (last floor: 9)
    db $04, $03, $05, $0C, $38, $08, $03, $02  ; Well Gate (last floor: 12)
    db $04, $04, $05, $0B, $39, $02, $01, $02  ; Gate of Strength (last floor: 11)
    db $04, $04, $05, $0B, $3C, $02, $06, $02  ; Gate of Anger (last floor: 11)
    db $04, $04, $06, $0C, $10, $08, $05, $02  ; Farm Gate (last floor: 12)
    db $05, $06, $06, $0E, $3B, $04, $01, $02  ; Gate of Joy (last floor: 14)
    db $05, $06, $06, $0F, $3A, $01, $07, $02  ; Gate of Wisdom (last floor: 15)
    db $05, $06, $07, $10, $3D, $04, $07, $02  ; Arena - Left Gate (last floor: 16)
    db $06, $07, $07, $12, $3E, $04, $01, $03  ; Gate of Happiness (last floor: 18)
    db $07, $07, $08, $14, $3F, $06, $03, $03  ; Gate of Temptation (last floor: 20)
    db $07, $05, $08, $13, $40, $04, $06, $03  ; Medal Gate (last floor: 19)
    db $08, $08, $09, $17, $42, $04, $06, $03  ; Gate of Labyrinth (last floor: 23)
    db $08, $09, $09, $19, $43, $05, $05, $03  ; Gate of Judgement (last floor: 25)
    db $08, $05, $09, $19, $44, $00, $03, $03  ; Library Gate (last floor: 25)
    db $09, $0A, $0A, $1D, $45, $04, $07, $03  ; Gate of Reflection (last floor: 29)
    db $0A, $0B, $0B, $1E, $46, $05, $06, $03  ; Gate of Ambition (last floor: 30)
    db $0A, $0B, $0B, $1D, $47, $05, $06, $03  ; Gate of Demolition (last floor: 29)
    db $0A, $0B, $0B, $1B, $48, $04, $07, $03  ; Gate of Mastermind (last floor: 27)
    db $0B, $0C, $0C, $1E, $49, $04, $07, $03  ; Gate of Control (last floor: 30)
    db $0B, $0C, $0C, $1E, $4A, $09, $07, $03  ; Gate of Extinction (last floor: 30)
    db $0B, $0D, $0D, $1E, $4B, $04, $07, $03  ; Gate of Sleep (last floor: 30)
    db $0C, $0D, $0D, $1E, $4C, $05, $05, $03  ; Bazaar Edge Gate (last floor: 30)
    db $0D, $0E, $0E, $1B, $4D, $05, $07, $03  ; Arena - Right Gate (last floor: 27)
    db $0E, $0E, $0E, $1E, $4E, $08, $0C, $03  ; Old Man's Gate (last floor: 30)
    db $0F, $0F, $0F, $63, $4F, $05, $06, $03  ; Unused Gate (last floor: 99)
; @BUILD_PROJECT END gate_floor_table

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
; FloorTypeSelectionTable3 — 16 rows × 16 bytes (S122: the 17th "row" is
; MazeItemSubKind) — the CONTENTS row of a gate (wFloorType3):
; bytes 0-8 = cumulative % of item kinds 0-8 (SelectFloorType), bytes
; 9 / 10 / 11 = item count base / random range / % chance of the blocking
; (+$10) variant (MazePlacements, MazePlaceItem).
; Used by MazePlaceItem with index from GateFloorDataTable byte 2.
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
; MazeItemSubKind (S122; was listed as a 17th "type 16" row): indexed by an
; item kind & $0F — 1 = MazePlaceItem rolls a sub-kind from the 48-byte
; FloorLayoutData row of wFloorType3; else the byte itself is the sub-kind.
MazeItemSubKind:
    db $01, $01, $01, $01, $01, $01, $01, $00, $ff, $01, $01, $01, $01, $01, $01, $01

; ---------------------------------------------------------------
; FloorLayoutData — 16 rows × 48 bytes at $7436 (S122: 768 B; MazePatterns
; and MazeNPCChance follow): per contents row (wFloorType3) the
; cumulative % of item sub-kinds — SelectFloorType from MazePlaceItem and
; the treasure rooms' chests (SetBrd_6db0).
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
; MazePatterns (was "FloorTilePatterns" — S122): 21 ready-made 4x4 grids for
; shape mode 2 (MazeBuildFloor copies [wRNG1 mod 21] to $C940); their cells
; draw from MazeScreenTableB. ($7736 — after FloorLayoutData's 16 rows.)
MazePatterns:
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
; MazeNPCChance (S122): by wFloorType3 — a wandering NPC stays on the floor when
; wRNG1 < this (out of 256; the S122 census: its kind $C92B = wRNG1 & 3, sub-kind
; $C92C = wRNG1 mod 5 — bank $0B GatePtrTable_42c8). $CAB4 0/1 and a $C92D of
; 4-7 take other paths (MazePlacements).
MazeNPCChance:
    db $00, $0d, $0d, $0d, $0d, $0d, $1a, $1a, $1a, $1a, $1a, $26, $26, $26, $26, $26 ; $7886

; ---------------------------------------------------------------
; MazeScreenTable — 512 bytes at $7896
; MazeScreenTable (was "FloorDataPtrTable1" — S122, PyBoy pixel-proved):
; 256 × [layout id, layout bank], indexed by a grid cell byte
; (piece*16 + variant). The pair is an ordinary screen layout stream —
; the [step id, tileset bank] of a normal room's step entry — so
; LoadFloorDataPointer (entry 9) is bank $0B ReadStepBlock's gate path.
; Shape modes 0 / 1. Variants 0-11 rolled, 12 = mode 1; 13-15 unused.
; Shared by every floor type (the type only picks the sheet + palettes).
; ---------------------------------------------------------------
MazeScreenTable:
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
; MazeScreenTableB — at $7A96
; MazeScreenTableB (was "FloorDataPtrTable2" — S122): the same for shape
; mode 2 (the MazePatterns cells).
; ---------------------------------------------------------------
MazeScreenTableB:
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

; =============================================================================
; FamilyRecipeResolve — bound-check for FamilyRecipeTable (222 entries, id 0-221).
; A new species (ids 221-239; S105 G3 — was 224 only, gate id>=222) overshoots
; or collides with FamilyRecipeTable, so the reader is forked here: it returns a
; pointer into NewRecipePairs[id-221], the 2-byte encyclopedia display pair the
; compiler derives from the FIRST special breeding entry producing the species
; ($FF,$FF = no recipe -> the "bred from" line stays blank, like the vanilla
; wild-only ids). HL enters as id*2. The encyclopedia hint (SetItem_67c0, bank
; $12) renders these two bytes as monster sprites and bails on family codes
; ($F0+), so they are SPECIES ids, not family codes. Without this fork a new id
; reads SpecialRecipeTable and shows bogus breeding parents.
; =============================================================================
FamilyRecipeResolve:
    ld a, h
    or a
    jr z, .normal                 ; h==0 -> id<128 -> in-range
    ld a, l
    cp $ba                        ; h==1: l>=$ba means id*2>=$1ba i.e. id>=221
    jr nc, .new_species
.normal:
    ld a, l
    add LOW(FamilyRecipeTable)
    ld l, a
    ld a, h
    adc HIGH(FamilyRecipeTable)
    ld h, a
    ret
.new_species:                     ; HL = NewRecipePairs + (id-221)*2
    ld a, l
    add LOW(NewRecipePairs - $1BA)
    ld l, a
    ld a, h
    adc HIGH(NewRecipePairs - $1BA)
    ld h, a
    ret
NewRecipePairs:                   ; 19 x 2 B, ids 221-239 (region ns_recipe_pair;
                                  ; no species = zeros, the original bytes here)
; @BUILD_PROJECT BEGIN ns_recipe_pair
    db $00, $00   ; [221] (none)
    db $00, $00   ; [222] (none)
    db $00, $00   ; [223] (none)
    db $04, $2A   ; [224] Gorbunok: encyclopedia parents (first special entry)
    db $00, $00   ; [225] (none)
    db $00, $00   ; [226] (none)
    db $00, $00   ; [227] (none)
    db $00, $00   ; [228] (none)
    db $00, $00   ; [229] (none)
    db $00, $00   ; [230] (none)
    db $00, $00   ; [231] (none)
    db $00, $00   ; [232] (none)
    db $00, $00   ; [233] (none)
    db $00, $00   ; [234] (none)
    db $00, $00   ; [235] (none)
    db $00, $00   ; [236] (none)
    db $00, $00   ; [237] (none)
    db $00, $00   ; [238] (none)
    db $00, $00   ; [239] (none)
; @BUILD_PROJECT END ns_recipe_pair

; =============================================================================
; GATE ROOM INSERTION (S100, ROADMAP P3.7b part 1; was the S41 Pillar B POC)
; =============================================================================
; GateDecisionFork is CALLed from entry 5's non-boss floor branch, replacing
; the vanilla gate-0 exclusion in place (6 bytes -> call + 3 nops, S41). The
; call pushed a return address pointing at the nops, then the vanilla
; special-room gating:
;     ld a,[wRNG1] / bit 4,a / jr z,std        ; ~50%
;     ld a,$03 / call Div8x8 / cp $02 / jr z,special
; Div8x8 divides B, and B = wCurrentFloor (loaded just before the boss test)
; — so vanilla special rooms (treasure/priest/forest/maze) can only appear
; when wCurrentFloor mod 3 == 2 (floors 3, 6, 9, ... counting the first
; floor as 1), NOT on "RNG mod 3" as GATE_GENERATION §3 once said (S100,
; PyBoy-measured). Everything here therefore PRESERVES B.
;
;   anchor return (wAnchorArm==3) -> standard maze (S73), consumes the arm
;   bank $71 entry 4 CustomGateInsert hit -> the custom room it wrote
;               (wMapID, wInGateworld=0, spawn) — unwind to entry-5's caller
;   gate 0  -> standard maze (the vanilla gate-0 exclusion)
;   else    -> RET into the vanilla special-room gating, byte-for-byte vanilla
;
; The `pop hl` on the paths that emulate the original `jr z` discards the
; call's return address so their final RET unwinds to entry-5's CALLER
; (KEY_LESSONS S41). HL is dead here (reloaded on every downstream path).
; A gate with no applicable insertion rule draws no RNG in entry 4, so its
; vanilla rolls are unchanged.
GateDecisionFork:
    ld a, [wAnchorArm]          ; [ANCHOR S73] arm==3 = anchor return in flight
    cp 3                        ;   (set by the bank $73 commit hook): force the
    jr z, .anchorStd            ;   STANDARD maze path for ANY gate — a
                                ;   regenerated anchor floor is never a special
                                ;   (or custom-inserted) room, by user spec.
    push bc                     ; B = wCurrentFloor, live for the vanilla Div8x8
    ld hl, $7104                ; bank $71 entry 4: CustomGateInsert
    rst $10                     ;   -> E = 1 inserted (room + spawn written), 0 not
    pop bc
    ld a, e
    or a
    jr nz, .custom
    ld a, [wGateID]
    or a
    jr z, .gate0
    ret                         ; gates 1-31: continue to the vanilla gating
.anchorStd:
    xor a
    ld [wAnchorArm], a          ; consume arm (one floor only)
    pop hl                      ; drop call return addr -> RET unwinds to caller
    jp jr_016_5bbf              ; standard maze path
.gate0:
    pop hl                      ; drop call return addr -> RET unwinds to caller
    jp jr_016_5bbf              ; standard maze (vanilla gate-0 behaviour)
.custom:
    pop hl                      ; drop call return addr: the room is set up
    ret                         ;   (the vanilla special handlers end the same way)

; -----------------------------------------------------------------------------
; GateRowPtr (S115, ROADMAP NG1 — new gates): HL := the 8-byte
; GateFloorDataTable-format row of wGateID ([ft1, ft2, ft3, floors, boss map,
; boss tile x, boss tile y, depth tier] — GATE_GENERATION §1).
;   gates 0-31  -> GateFloorDataTable + gate*8 (vanilla)
;   gate >= 32  -> bank $76 entry 1 NewGateRowCopy: a project NEW gate
;                  (custom.gates[] with copy_of, compiler-owned NewGateRows)
;                  is copied to wGateRowBuf and E = 1 -> HL = wGateRowBuf;
;                  an undefined number gives E = 0 -> the vanilla wrap
;                  (gate & 31), exactly what the old 8-bit gate*8 read.
; Called by the two same-size forks in entry 5 (jr_016_5b72 / jr_016_5be1).
; Clobbers A; keeps BC and DE (rst $10 hands the callee's DE / HL back and
; destroys A — KEY_LESSONS v3: E is read, then DE restored).
; -----------------------------------------------------------------------------
GateRowPtr:
    ld a, [wGateID]
    cp 32
    jr c, .vanilla
    push de
    ld hl, $7601                ; bank $76 entry 1: NewGateRowCopy
    rst $10                     ;   -> E = 1 copied to wGateRowBuf, 0 = undefined
    ld a, e
    pop de
    or a
    jr z, .wrap
    ld hl, wGateRowBuf
    ret
.wrap:
    ld a, [wGateID]
.vanilla:
    and $1F                     ; (a no-op for 0-31; the old wrap for the rest)
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl                  ; gate * 8
    push de
    ld de, GateFloorDataTable
    add hl, de
    pop de
    ret

    ds $8000 - @, $00             ; pad remainder of bank with $00 (byte-exact)
