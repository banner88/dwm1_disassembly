; =============================================================================
; BANK $6D — FAMILY SYSTEMS (S104; hand-authored, patches/bank_06d.asm)
; =============================================================================
; Everything the game looks up BY FAMILY through a 10-entry vanilla table
; (families 0-9) is answered here instead, so family 10 = SPIRIT is a real
; family (ROADMAP P3.10a; BREEDING_SYSTEM "Spirit — the 11th family").
; Vanilla families return exactly the vanilla values (the vanilla tables are
; left in place, dead; see each fork). Families >= 11 do not exist; any such
; value is treated as Spirit so a stray byte can never index past a table.
;
; The five callers are same-size rewrites (banks $01, $04, $09 admit no
; inserts — Iron Rule 2 — and bank $0A has no room at the site):
;   entry 0  bank $01 GetActiveMonsterStatus family-icon DMA (was
;            `ld hl,$cacb / call ClampFamIdx / ... FollowerFamilyGfxTable`)
;   entry 1  bank $0A party/farm list family-icon DMA (was the UNCLAMPED
;            twin table $0A:$46B5 — family 10 read a garbage gfx id there)
;   entry 2  bank $04 MonsterSlotDialogue (script opcode $2D) text group
;            (was FamilyTextPtrTable $04:$60F4, 10 entries)
;   entry 3  bank $09 naming-screen default name id (mode 3 id =
;            family<<4 | gender*8 | RNG&7 — family 10 ran off the 160-entry
;            pool into the next table)
;   entry 4  NOT code: gfx-stream index 4. DecompressTileLayout ($00) reads
;            gfx id $6D04 as [$6D:$4001 + 4*2] -> SpiritIconStream, so the rst
;            table doubles as this bank's gfx pointer table.
; rst $10 contract (bank $00): A/F/BC clobbered, DE and HL come back as the
; routine leaves them. The callers push/pop BC around the call.
; =============================================================================

SECTION "ROM Bank $06D", ROMX[$4000], BANK[$6D]

    db $6D                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw FamilyIconGfxActive              ; entry 0  (HL=$6D00)
    dw FamilyIconGfxFromE               ; entry 1  (HL=$6D01)
    dw FamilyTextGroupFromE             ; entry 2  (HL=$6D02)
    dw FamilyDefaultNameId              ; entry 3  (HL=$6D03)
    dw SpiritIconStream                 ; gfx index 4 (gfx id $6D04)

FAMILY_SPIRIT EQU 10                    ; family byte of Spirit (breeding code $FA)
SPIRIT_ICON_GFX EQU $6D04               ; gfx id of SpiritIconStream
SPIRIT_NAME_ID EQU $A0                  ; mode-3 ids $A0-$A7 = the Spirit name pool (bank $41)

; -----------------------------------------------------------------------------
; Entry 0 — FamilyIconGfxActive: DE = family-icon gfx id of the ACTIVE monster
; (struct byte $cacb = family, via ReadActiveMonsterByte like the vanilla
; site). Falls into entry 1.
; -----------------------------------------------------------------------------
FamilyIconGfxActive:
    ld hl, $cacb
    call ReadActiveMonsterByte          ; A = family byte of the active monster
    ld e, a
    ; fall through

; -----------------------------------------------------------------------------
; Entry 1 — FamilyIconGfxFromE: E = family -> DE = gfx id of its 16-byte icon
; tile. Families 0-9: $2E03 + family (= both vanilla 10-entry tables
; $01:$4BAD and $0A:$46B5, which are exactly that sequence). Spirit: the
; stream below (same art as font glyph $1A, $4F:$41B0).
; -----------------------------------------------------------------------------
FamilyIconGfxFromE:
    ld a, e
    cp FAMILY_SPIRIT
    jr nc, .spirit
    add $03
    ld e, a
    ld d, $2e
    ret
.spirit
    ld de, SPIRIT_ICON_GFX
    ret

; -----------------------------------------------------------------------------
; Entry 2 — FamilyTextGroupFromE: E = family -> DE = its farm-dialogue text
; group (8 dw text ids per group, bank $04; indexed by the caller with the
; slot's dialogue index). Families 0-9 = the vanilla FamilyTextPtrTable.
; -----------------------------------------------------------------------------
FamilyTextGroupFromE:
    ld a, e
    cp FAMILY_SPIRIT
    jr c, .ok
    ld a, FAMILY_SPIRIT
.ok
    add a
    ld e, a
    ld d, $00
    ld hl, FamilyTextPtrTable11
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ret

; @BUILD_PROJECT BEGIN gd_family_voices
FamilyTextPtrTable11:
    dw FamilyTextGroup_A                ; 0 Slime     (vanilla)
    dw FamilyTextGroup_B                ; 1 Dragon    (vanilla)
    dw FamilyTextGroup_C                ; 2 Beast     (vanilla)
    dw FamilyTextGroup_B                ; 3 Bird      (vanilla)
    dw FamilyTextGroup_A                ; 4 Plant     (vanilla)
    dw FamilyTextGroup_C                ; 5 Bug       (vanilla)
    dw FamilyTextGroup_C                ; 6 Devil     (vanilla)
    dw FamilyTextGroup_A                ; 7 Zombie    (vanilla)
    dw FamilyTextGroup_B                ; 8 Material  (vanilla)
    dw FamilyTextGroup_D                ; 9 ???/Boss  (vanilla)
    dw FamilyTextGroup_D                ; 10 Spirit   (S104 default: the ??? group)
; @BUILD_PROJECT END gd_family_voices

; -----------------------------------------------------------------------------
; Entry 3 — FamilyDefaultNameId: E = the mode-3 text id of the default name
; offered on the naming screen. Reads what the vanilla code read: $DA33 (the
; species' info family, loaded by the caller's `ld hl,$0301 / rst $10`),
; wRNG1 (freshly rolled by the caller) and $C8F6 bit 0 (selects the second
; half of the family's 16-name pool). Families 0-9: the vanilla formula.
; Spirit: $A0 + RNG&7 (8 names; bit 0 of $C8F6 ignored).
; -----------------------------------------------------------------------------
FamilyDefaultNameId:
    ld a, [wRNG1]
    and $07
    ld e, a
    ld a, [$da33]
    cp FAMILY_SPIRIT
    jr nc, .spirit
    swap a
    or e
    ld e, a
    ld a, [$c8f6]
    and $01
    add a
    add a
    add a
    add e
    ld e, a
    ret
.spirit
    ld a, e
    add SPIRIT_NAME_ID
    ld e, a
    ret

; -----------------------------------------------------------------------------
; SpiritIconStream — gfx id $6D04, the HUD / list copy of the Spirit icon.
; Stream format (DecompressTileLayout / WaitDMATransfer, bank $00): dw length
; ($0010), db run marker (a byte value absent from the data, so no runs),
; then the 16 tile bytes. Same art as font glyph $1A (bank $4F $41B0).
; tools/build_family_icon.py --selftest checks both copies against
; extracted/family_icons.json "spirit".
; -----------------------------------------------------------------------------
SpiritIconStream:
    dw $0010
    db $00                              ; run marker (absent from the tile bytes)
    db $FF, $10, $EF, $28, $C7, $44, $AB, $AA, $83, $82, $C7, $44, $F7, $36, $FF, $0F
