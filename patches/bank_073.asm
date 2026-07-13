; =============================================================================
; BANK $73 — COLD FARM SYSTEMS (CF2: pending farm exp + chokepoint drain)
; =============================================================================
; S57. Part of ROADMAP Arc COLD FARM (spec there; boundary RE in MONSTER_DATA
; "Party/farm boundary semantics", S56).
;
; WHAT THIS BANK DOES
;   Vanilla pays every farm/storage monster total/16 exp AFTER EVERY BATTLE
;   (exp walker $50:CallBtl_61e2) and levels them silently in the post-battle
;   all-20 scan ($50:jr_050_6318 -> $1302 + $510d, no message). CF2 re-binds
;   per-battle exp to the party only:
;     * patches/bank_050.asm CF2FarmShareDivert zeroes the per-monster farm
;       share (HRAM $DB-$DD := 0) and accumulates total/16 into
;       wPendingFarmExp ($D9C8-$D9CA, 24-bit LE, clamped $98967F). With the
;       share zeroed, the vanilla walker + level scan become farm-inert with
;       ZERO further changes (farm exp never moves post-battle).
;     * THIS bank's entry 0 (CF2WarpCommitDrain) is called from the map-change
;       commit point in bank $0B RoomEntry0_TilesetLoader — the single funnel
;       every committed transition passes (boss return / WarpWing / death /
;       doorways all reload rooms through it). It performs the two displaced
;       instructions (wWarpFlag -> wInGateworld), and when the DESTINATION is
;       non-gate (wWarpFlag = 0) and pending exp is nonzero, it pays each
;       eligible farm monster the full pending amount and levels it using the
;       IDENTICAL silent vanilla pair ($1302 gains + $510d apply) that the
;       post-battle farm scan uses — then zeroes the accumulator.
;
; WHY wPendingFarmExp IS PERSISTENT ($D9C8, inside the $C8EA-$D9E9 save image)
;   In-gate save rooms exist (FAQ: "the only places we can record our save
;   states when we're beyond the Travelers' Gate"), so a transient accumulator
;   would silently lose a run's farm exp on save+reload. $D9C8-$D9CA are the
;   top 3 bytes of the S8-verified clean event-flag block (flags $0168-$017F,
;   retired from the allocator pool — see EVENT_FLAGS.md): zero engine literal
;   refs, zero script refs, boot-cleared (ClearAllWRAM), new-game-zeroed and
;   save-restored via the save image. Pre-CF2 saves hold $00 there -> pending
;   loads as 0 (clean migration).
;
; ELIGIBILITY (mirrors the vanilla walker's farm branch, evaluated at drain):
;   in-use flag +$00 == $01 (farm), egg +$63 == 0, level +$4B != 99,
;   level < cap +$4C. Exp add mirrors the walker's clamp; the level loop
;   mirrors CmpBtl_6383's threshold compare ($1300 -> HRAM $D5-$D7).
;
; SEMANTIC DELTAS vs vanilla (documented, user to veto in test):
;   * Farm monsters gain exp/levels at the first non-gate transition after
;     battles, not immediately ("grew while you were away"). Invisible in-gate
;     (farm UI is town-only); both paths are silent (no level-up message for
;     farm in vanilla either).
;   * A monster recruited to storage MID-run receives the FULL run's pending
;     at the drain (vanilla pays from its join onward). Slightly generous.
;   * Eligibility (level cap / 99) is evaluated at drain time, not per battle.
;   * The drain also fires on entry to in-gate special rooms (they commit with
;     wWarpFlag=0) — an EARLIER payout than the town chokepoint, which is
;     semantically safe (vanilla paid farm exp mid-gate after every battle)
;     and invisible to the player.
;
; Calling context: reached via `ld hl,$7300 / rst $10` from bank $0B Entry 0.
; rst $10 nests safely (vanilla precedent: bank $50 state machine is itself
; rst-dispatched and nests $1300/$1302/$510d). A/BC are dead at the call site;
; DE is not relied on by the code following it (verified: next uses are fresh
; loads). [$CAC0] is saved/restored around the drain.
; =============================================================================

SECTION "ROM Bank $073", ROMX[$4000], BANK[$73]

    db $73                          ; bank number (entry-table header)
    dw CF2WarpCommitDrain           ; entry 0  ($7300 -> $4001)

; -----------------------------------------------------------------------------
; Entry 0 — map-change commit hook: displaced store + conditional drain.
; -----------------------------------------------------------------------------
CF2WarpCommitDrain:
    ; displaced work from bank $0B RoomEntry0_TilesetLoader ($4020-$4025)
    ld a, [wWarpFlag]
    ld [wInGateworld], a
    or a
    ret nz                          ; destination is gate-mode -> keep accruing

    ; pending == 0 -> nothing to drain
    ld a, [wPendingFarmExp]
    ld hl, wPendingFarmExp+1
    or [hl]
    inc hl
    or [hl]
    ret z

    ; drain: pay + level every eligible farm monster, then zero pending
    ld a, [$cac0]                   ; preserve current slot selection
    push af
    ld b, $00                       ; b = slot counter (0-19)

.slot_loop:
    push bc

    ; farm only: in-use flag +$00 ($CAC1) must be $01
    ld a, b
    ld [$cac0], a
    ld hl, $cac1
    call GetMonsterDataPtr
    ld a, [hl]
    cp $01
    jp nz, .next

    ; skip eggs: +$63 ($CB24) != 0
    ld a, [$cac0]
    ld hl, $cb24
    call GetMonsterDataPtr
    ld a, [hl]
    or a
    jp nz, .next

    ; skip level 99: +$4B ($CB0C)
    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp $63
    jp z, .next

    ; skip level >= cap: +$4C ($CB0D)  (walker parity: cap gates exp GAIN)
    ld c, a                         ; c = level
    ld a, [$cac0]
    ld hl, $cb0d
    call GetMonsterDataPtr          ; preserves BC
    ld a, c
    cp [hl]
    jp nc, .next

    ; exp (+$4D, $CB0E) += pending, clamp $98967F — mirrors the walker's add
    ld a, [$cac0]
    ld hl, $cb0e
    call GetMonsterDataPtr
    ld a, [wPendingFarmExp]
    add [hl]
    ld [hl+], a
    ld e, a
    ld a, [wPendingFarmExp+1]
    adc [hl]
    ld [hl+], a
    ld d, a
    ld a, [wPendingFarmExp+2]
    adc [hl]
    ld [hl], a
    ld c, a
    ld a, e
    sub $7f
    ld a, d
    sbc $96
    ld a, c
    sbc $98
    jr c, .levels
    ld de, $967f
    ld c, $98
    ld [hl], c
    dec hl
    ld [hl], d
    dec hl
    ld [hl], e

.levels:
    ; level to match exp — the vanilla silent pair per level, exactly as the
    ; post-battle all-20 scan does it ($50:jr_050_6337: $1302 then $510d).
.lvl_loop:
    ld a, [$cac0]
    ld hl, $cb0c
    call GetMonsterDataPtr
    ld a, [hl]
    cp $63
    jr z, .next                     ; hit 99 mid-drain -> stop

    ld hl, $1300                    ; bank $13 entry 0: next-level threshold -> HRAM $D5-$D7
    rst $10
    ld a, [$cac0]
    ld hl, $cb0e
    call GetMonsterDataPtr
    ldh a, [$d5]                    ; 24-bit exp - threshold (CmpBtl_6383 parity)
    ld b, a
    ld a, [hl+]
    sub b
    ldh a, [$d6]
    ld b, a
    ld a, [hl+]
    sbc b
    ldh a, [$d7]
    ld b, a
    ld a, [hl+]
    sbc b
    jr c, .next                     ; exp < threshold -> done with this monster

    ld hl, $1302                    ; gains -> $C8CA-$C8CF (+ $C8D0 past-cap flag)
    rst $10
    ld hl, $510d                    ; apply: level+1 + stat adds (silent)
    rst $10
    jr .lvl_loop

.next:
    pop bc
    inc b
    ld a, b
    cp $14
    jp nz, .slot_loop

    ; all 20 slots done — zero the accumulator, restore slot selection
    xor a
    ld [wPendingFarmExp], a
    ld [wPendingFarmExp+1], a
    ld [wPendingFarmExp+2], a
    pop af
    ld [$cac0], a
    ret
