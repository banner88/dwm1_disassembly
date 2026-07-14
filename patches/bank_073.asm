; =============================================================================
; BANK $73 — COLD FARM SYSTEMS
;   entry 0 (S57): CF2 pending-farm-exp drain at the map-change commit
;   entry 1 (S58): CF3 step 1 — party-first sort (canonicalizer tail hook)
; =============================================================================
; Part of ROADMAP Arc COLD FARM (spec there; boundary RE in MONSTER_DATA
; "Party/farm boundary semantics", S56; sort as-built in MONSTER_DATA
; "CF3 step 1 as built").
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
    dw CF3PartyFirstSort            ; entry 1  ($7301 -> $4003)

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


; -----------------------------------------------------------------------------
; Entry 1 — CF3 step 1: PARTY-FIRST SORT (S58).
; Hooked from the canonicalizer tail: patches/bank_001.asm ReadPartySlotInfo's
; final `ld hl,$0106` is retargeted to $7301 (same-size operand edit at
; $01:$4809-$480A). This runs AFTER every vanilla canonicalize step (list
; cleaned/compacted/remapped, array compacted, $CA8D recounted) and BEFORE the
; displaced vanilla tail (entry $0106 = ScanPartySlotTable, the +$29/+$31
; ID-list sanitizer — NOT follower art; see DOC_AUDIT S58), which this entry
; nest-calls at the end. rst $10 nests stack-safely (RST_10 pushes the caller
; bank; depth 3 here: caller -> $0105 -> $7301 -> $0106).
;
; INVARIANT ESTABLISHED: after every canonicalize, party member at list
; position i occupies array slot i (slots 0-2, list order preserved), so the
; party list reads 0,1,2/$FF and farm records occupy slots party_count..N-1
; contiguously. This is the precondition for CF3's farm->SRAM move ("slots
; 3-19 == farm"). Vanilla does NOT hold this (party can sit at any index).
;
; ENTRY STATE (vanilla canonicalizer guarantees): occupied slots contiguous
; from 0; party list compacted (non-$FF first), entries unique, each < the
; occupied count. Selection sort over <=3 list positions; per swap, the
; displaced record's slot index is exchanged in every WRAM cell that stores
; raw slot indices across a canonicalize:
;   * later party-list entries (a party member sitting at slot i moves to t)
;   * battle-position cache $DA15-$DA17 (stale-safe: set at battle setup;
;     vanilla compaction is a no-op at the mid-battle join canonicalize, the
;     sort is not — exchange keeps the cache truthful)
; [$CAC0] and $CA40 are deliberately NOT remapped: both are live selection
; registers written fresh by each flow (vanilla contract: slot indices are
; only stable between canonicalize calls; $CA40 doubles as the farm
; drop/pick candidate — see the v2 note at the removed fixup site below).
; $DA14 needs no fixup (give-parameter, consumed before the canonicalize).
; The $C0D8 old->new map: no straight-line consumer after return (20-line
; scan below every `ld hl,$0105` site, zero hits). CAVEAT (S58 v2): that
; scan cannot see menu STATE MACHINES resuming next frame; vanilla already
; clobbers $C0D8 with the map on every canonicalize, so any such reader is
; a pre-existing vanilla hazard, not a sort-specific one — but the sort makes
; leftover map values stale-by-one-permutation where vanilla's were self-
; consistent. Watch item for the farm/menu tests.
;
; Registers: all free (rst-dispatched; canonicalizer does only `ret` after).
; GetMonsterDataPtr (ROM0) preserves BC/DE.
; -----------------------------------------------------------------------------
CF3PartyFirstSort:
    ld c, $00                       ; c = i (list position / target slot)

.pass:
    ld a, c
    cp $03
    jp z, .tail

    ; t = party list[i]
    ld a, $8e
    add c
    ld l, a
    ld h, $ca                       ; HL = $CA8E + i
    ld a, [hl]
    cp $ff
    jp z, .tail                     ; list is compacted -> first $FF ends it
    cp c
    jp z, .next                     ; already in place
    ld b, a                         ; b = t (t > i: entries unique, 0..i-1 fixed)

    ; party-list fixup: any entry == i -> t (a party member displaced from
    ; slot i). Scanning all 3 is safe pre-write: position i holds t (!= i),
    ; positions < i hold identity values < i.
    ld hl, $ca8e
    ld d, $03
.fixl:
    ld a, [hl]
    cp c
    jr nz, .fixl_n
    ld [hl], b
.fixl_n:
    inc hl
    dec d
    jr nz, .fixl

    ; list[i] := i
    ld a, $8e
    add c
    ld l, a
    ld h, $ca
    ld [hl], c

    ; battle-position cache $DA15-$DA17: exchange i <-> t
    ld hl, $da15
    ld d, $03
.fixc:
    ld a, [hl]
    cp c
    jr nz, .fixc_t
    ld [hl], b
    jr .fixc_n
.fixc_t:
    cp b
    jr nz, .fixc_n
    ld [hl], c
.fixc_n:
    inc hl
    dec d
    jr nz, .fixc

    ; NOTE (S58 v2): the v1 build also exchange-fixed $CA40 here, on the S56
    ; doc's description of it as the breeding-offspring slot persist. WRONG
    ; CALL: $CA40 is ALSO the farm drop/pick flow's live candidate register
    ; (written per selection at $0A:~$5CC4 together with $CAC0/$C908; consumed
    ; by the working-set filler SetFldA_6ad5 and the direct-pick list append
    ; $0A:~$6A9F). Rewriting it behind the UI's back is the same class of
    ; error as remapping $CAC0 would be — vanilla contract: selection
    ; registers are written fresh by each flow; indices are unstable across
    ; canonicalize. Removed. Breeding residual risk (a canonicalize between
    ; the offspring insert and the bank $04 hatch finalizer's $CA40 read)
    ; judged low — no $0105 call sits in that window — flagged as a watch
    ; item in MONSTER_DATA "CF3 step 1 as built"; verify in breeding test.

    ; swap the two 149-byte records: HL = slot i, DE = slot t
    ld a, c
    ld hl, $cac1
    call GetMonsterDataPtr          ; preserves BC/DE
    push hl
    ld a, b
    ld hl, $cac1
    call GetMonsterDataPtr
    ld d, h
    ld e, l
    pop hl
    push bc
    ld b, $95                       ; vanilla SaveRegsAndSetupDE swap idiom
.swap:
    ld c, [hl]
    ld a, [de]
    ld [hl+], a
    ld a, c
    ld [de], a
    inc de
    dec b
    jr nz, .swap
    pop bc

.next:
    inc c
    jp .pass

.tail:
    ld hl, $0106                    ; displaced vanilla tail: ScanPartySlotTable
    rst $10
    ret
