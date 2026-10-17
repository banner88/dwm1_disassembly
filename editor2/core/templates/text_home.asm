; =============================================================================
; S150 (ROADMAP P3.6 / Phase F T-author) — EDITED GAME TEXT: the lookup.
; Pasted into the text HOME bank only (the first text bank, editor2/core/
; gametext.py), with {T} = that bank's suffix. Owning docs: TEXT_SYSTEM
; "Edited game text (S150)", PROJECT_COMPILER §2.58.
;
; Every text the game shows or copies is found by ROM0 SaveBankAndSwitch: DE =
; the current bank's mode list, [$C822] = the mode, [$C823] = the id; level 1
; reads the mode's per-id TABLE, level 2 the text's address at table + 2 * id.
; Its level-1 read (ROM0 TextLevel1Hook, $00F0) far-calls bank $60 entry 14
; (TextOverride), which forwards here when the build has edited texts.
;
; In:  DE = the per-id table about to be indexed, [$C823] = the id, [$C824] =
;      the bank that table is in (SaveBankAndSwitch stored [$4000] there),
;      [wTextOvrMode] = 1 when RunTextHandler copies the text into its buffer
;      [$C837] (ROM0 SaveBankAndSwitchCopy set it), else 0.
; Out: an EDITED text (a row of this table holds the id):
;        DE = wTextOvrPtr - 2 * id, so SaveBankAndSwitch's own level-2 read
;        `[DE + 2 * id]` fetches the word in wTextOvrPtr — WRAM, read whatever
;        ROM bank is mapped;
;        show: wTextOvrPtr = the edited text, [$C824] = its bank — the text
;              engine reads every byte from bank [$C824] (ReadNextTextByte,
;              SaveBankForTextDisplay);
;        copy: the text is copied to [$C837] from its own bank (that text
;              bank's entry 1) and wTextOvrPtr = [$C837]: RunTextHandler's loop
;              then copies the buffer onto itself up to the $F0 written here.
;      not edited: DE unchanged. Always: wTextOvrMode = 0, BC / HL clobbered
;      (SaveBankAndSwitch reloads HL; rst $10 hands DE back).
;
; Data (generated below the blocks):
;   TextOvrBanks{T}: 32 bytes — bit (bank & 7) of byte (bank >> 3) set = some
;                    table of that bank has an edited text (the quick "no").
;   TextOvrDir{T}:   per edited table [db bank, dw table, dw list, db count],
;                    ended by a bank $00 byte.
;   a list:          count x [db id, db text bank, dw address] (count 0 = 256).
; =============================================================================
TextOvrFind{T}:
    push de                         ; the table (a miss hands it back)
    ld a, [wTextOvrMode]
    ld c, a                         ; C = 1 copy / 0 show
    xor a
    ld [wTextOvrMode], a
    ld a, [$c824]
    ld b, a                         ; B = the table's bank
    rrca
    rrca
    rrca
    and $1F                         ; the bitmap byte
    ld hl, TextOvrBanks{T}
    add l
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld e, [hl]
    ld a, b
    and $07                         ; its bit
.shift:
    jr z, .tested
    srl e
    dec a
    jr .shift
.tested:
    bit 0, e
    jr z, .miss
    pop de
    push de
    ld hl, TextOvrDir{T}
.row:
    ld a, [hl+]
    and a
    jr z, .miss                     ; bank $00 ends the rows
    cp b
    jr nz, .skip5
    ld a, [hl+]
    cp e
    jr nz, .skip4
    ld a, [hl+]
    cp d
    jr nz, .skip3
    ld a, [hl+]                     ; this table: its list
    ld e, a
    ld a, [hl+]
    ld d, a
    ld b, [hl]                      ; B = the rows in it
    ld h, d
    ld l, e
    ld a, [$c823]
    ld e, a                         ; E = the id
.item:
    ld a, [hl+]
    cp e
    jr z, .hit
    inc hl
    inc hl
    inc hl
    dec b
    jr nz, .item
    jr .miss
.skip5:
    inc hl
.skip4:
    inc hl
.skip3:
    inc hl
    inc hl
    inc hl
    jr .row
.hit:
    ld a, [hl+]
    ld b, a                         ; B = the edited text's bank
    ld a, [hl+]
    ld e, a
    ld d, [hl]                      ; DE = its address
    pop hl                          ; (the saved table)
    ld a, c
    and a
    jr nz, .copy
    ld a, b
    ld [$c824], a                   ; show: the engine reads it from its bank
    jr .point
.copy:
    ld a, [$4000]
    cp b
    jr nz, .far
    call TextOvrCopy{T}             ; it is in this bank
    jr .copied
.far:
    ld h, b
    ld l, $01
    rst $10                         ; its bank's entry 1 = TextOvrCopy there (DE = the text)
.copied:
    ld a, [$c837]
    ld e, a
    ld a, [$c838]
    ld d, a                         ; the buffer: RunTextHandler copies it onto itself
.point:
    ld a, e
    ld [wTextOvrPtr], a
    ld a, d
    ld [wTextOvrPtr + 1], a
    ld a, [$c823]
    ld l, a
    ld h, $00
    add hl, hl                      ; 2 * id
    ld a, LOW(wTextOvrPtr)
    sub l
    ld e, a
    ld a, HIGH(wTextOvrPtr)
    sbc h
    ld d, a                         ; DE = wTextOvrPtr - 2 * id
    ret
.miss:
    pop de
    ret
