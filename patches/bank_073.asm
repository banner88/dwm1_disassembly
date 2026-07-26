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
    dw CF3AdvanceDE                 ; entry 2  — walker slot advance w/ boundary hop (S60)
    dw CF3RebaseDE                  ; entry 3  — GMDP slow path: rebase computed ptr (S60)
    dw CF3Checksum                  ; entry 4  — 3-segment save checksum + migration (S60)
    dw CF3CopyToSRAM                ; entry 5  — CopySRAMBlock body, farm-window write-skip (S60)
    dw CF3CopyFromSRAM              ; entry 6  — CopyFromSRAM body, farm-window read-skip (S60)
    dw CF3NewGameClear              ; entry 7  — new-game WRAM image zero + SRAM farm-flag zero (S60)
    dw CF3TradeRecv                 ; entry 8  — trade receive: staging $15 -> farm slot 19 SRAM (S60)
    dw CF3SRAMBankedCopy            ; entry 9  — E3 (S69): general banked copy primitive (di-bracketed RAMB)
    dw CF3PoolSwapRecord            ; entry 10 — FX1 (S71): swap array slot D <-> bank-2 pool slot E (149 B)
    dw CF3PoolZeroInit              ; entry 11 — FX1 (S71): zero the 40-slot bank-2 pool + write "P1" magic
    dw CF3PoolCounts                ; entry 12 — FX1 (S71): pool census -> E = awake-eligible (non-egg), D = eggs

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

    ; FX1 v2 (S71): exp scale REMOVED by user veto — each eligible farm
    ; monster receives the FULL pending (vanilla total/16-per-battle rate,
    ; identical per-monster growth to vanilla; aggregate scales with farm
    ; size). The v1 build halved the payout here (effective total/32).
    ; drain: pay + level every eligible farm monster, then zero pending
    ld a, [$cac0]                   ; preserve current slot selection
    push af
    ld b, $00                       ; b = slot counter (0-39, FX1)

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
    ld a, [wPendingFarmExp]         ; FX1 v2: full pending (vanilla rate)
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
    cp $28                          ; FX1: 40 slots (0-2 party, 3-39 farm)
    jp nz, .slot_loop

    ; all 40 slots done — zero the accumulator, restore slot selection
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
    ; -------------------------------------------------------------------------
    ; S60v2 ROSTER MIRROR — the cross-space atomicity fix.
    ; Sort and compaction move records between WRAM party slots (lazy, saved
    ; at save time) and SRAM farm slots (eager, live). Committing only the
    ; SRAM half meant a reload-without-save DUPLICATED one record and LOST
    ; the other (S60 field bug: party member swapped to slot 0-2 vanished on
    ; reload, its farm counterpart doubled). Fix: after every canonicalize,
    ; bulk-mirror the WRAM roster region — list, library bits, monster vars,
    ; party records $CA8D-$CC7F — into its image home $A1C7-$A3B9. Together
    ; with the v2 checksum exclusion of $A1C7-$AD9E this makes the ENTIRE
    ; roster uniformly eager: reload restores the last canonical roster; no
    ; record can be lost or doubled. World state (gold/items/flags/position)
    ; stays lazy exactly as vanilla. ~$1F3 byte copies, negligible.
    ; (Runs after the displaced ScanPartySlotTable so the mirrored list is
    ; the sanitized one. BC/A are free here — rst $10 clobbered them anyway.)
    ; -------------------------------------------------------------------------
    ld a, $0a
    ld [$0100], a
    ld hl, $ca8d
    ld de, $a1c7
    ld bc, $01f3
.mir:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .mir
    ret


; =============================================================================
; S60 — CF3 FULL MOVE: farm slots 3-19 are SRAM-RESIDENT.
;
; ADDRESS MAP (the one fact everything below derives from):
;   Farm slot s (3..19) lives at its SAVE-IMAGE address:
;     SRAM = $A1FB + s*$95  (slot 3 = $A3BA .. slot 19 = $AD0A-$AD9E end)
;   which is exactly (WRAM address - $28C6). Party slots 0-2 ($CAC1-$CC7F)
;   and staging pseudo-slots $14/$15 ($D665-$D78E) STAY in WRAM. WRAM
;   $CC80-$D664 is freed (the custom NPC/exit buffers at $D379-$D477 now sit
;   in genuinely free space — the phantom-spawn hazard class is retired).
;   MIGRATION IS FREE: vanilla's own save block copy already put every
;   pre-CF3 save's farm records at these SRAM addresses.
;
; PERSISTENCE MODEL (S60v2): the monster ROSTER — party list, library bits,
; monster vars, party records, farm records (image $A1C7-$AD9E) — is EAGER:
; farm writes land in live SRAM immediately, and the canonicalizer tail
; mirrors the WRAM roster region into the image after every sort/compaction.
; The checksum excludes the whole roster region accordingly. World state
; (gold, items, flags, position) stays LAZY (persisted at save) as vanilla.
; Consequence: reload restores the last canonical roster, not the last save
; — roster changes (breed, catch, deposit) are not undone by reloading, but
; can never be half-committed, duplicated, or lost (the S60v1 field bug).
;
; ACCESS COVERAGE (redirect points; RE in MONSTER_DATA "CF3 as built"):
;   * pointer producers: ROM0 GMDP/GetCurrentMonsterPtr/GetActiveMonsterPtr
;     share one 5-byte tail window -> CF3MulRebase (ROM0) -> entry 3 here for
;     the farm (cold) case. bank $59's two local producers route through the
;     exported CF3RebaseHL gate.
;   * stride walkers (49 sites): 8-byte `add $95` advance windows -> entry 2.
;   * save system: SRAMWriteBlock/CopySRAMBlock/CopyFromSRAM husks -> entries
;     4/5/6 (single choke points for checksum compute+verify+wipe-recompute
;     and for every image block copy incl. SavePartyToSRAM).
;   * SRAM stays enabled: ReadSRAMByte/WriteSRAMByte helpers no longer
;     disable (1-byte operand edits); every entry here (re-)enables.
;
; rst $10 contract reminders: callee gets A/HL/flags CLOBBERED both ways.
; DE is preserved by the dispatcher; BC is NOT — RST_20's `ld bc,$4001`
; table index destroys it BEFORE the callee runs (S60 validation catch).
; Hence: dance sites push/pop BC, the copy husks pass the true BC via the
; stack (callees read it at the constant dispatcher-frame depth sp+4), and
; producers rely on their own entry push bc / exit pop bc. RAMB is set per
; bank by RST_10 but the 8KB cart ignores it (vanilla proof: saves fire from
; bank $50 with RAMB=2).
; =============================================================================

; -----------------------------------------------------------------------------
; Entry 2 — CF3AdvanceDE: DE += $95 with WRAM<->SRAM boundary hops.
; In/out: DE = slot-field pointer being walked. A/HL/flags free.
; Down-hop (slot 2 -> 3): DE lands in [$CC80,$CD14] (field offset f in
;   [0,$94]) -> DE -= $28C6 and enable SRAM (the walker dereferences next).
; Up-hop (slot 19 -> staging $14): DE lands in [$AD9F,$AE33] -> DE += $28C6.
;   No vanilla walk goes past slot 19 (all bounds are $14), so this only
;   fires on the discarded post-loop advance — kept so a stray 22-slot walk
;   degrades to vanilla behaviour instead of dereferencing SRAM garbage.
; -----------------------------------------------------------------------------
CF3AdvanceDE:
    ld a, e
    add $95
    ld e, a
    ld a, d
    adc $00
    ld d, a
    ; down-hop test: $CC80 <= DE <= $CD14
    ld a, d
    cp $cc
    jr z, .dlow
    cp $cd
    jr nz, .uptest
    ld a, e
    cp $15
    jr c, .down                     ; $CD00-$CD14 -> hop
    jr .uptest
.dlow:
    ld a, e
    cp $80
    jr c, .uptest                   ; $CC00-$CC7F unreachable by a valid walk; guard
.down:
    ld a, e
    sub $c6
    ld e, a
    ld a, d
    sbc $28
    ld d, a                         ; DE -= $28C6 -> farm SRAM
    ld a, $0a
    ld [$0100], a                   ; enable SRAM for the walker's derefs
    ret
.uptest:
    ; FX1 (S71) mid-hop: slot 19 -> 20. A stride advance off slot 19's end
    ; ($AD0A+$95 = $AD9F, field f in [0,$94] -> [$AD9F,$AE33]) now continues
    ; into the EXTENDED farm ($B124 + f): DE += $0385. (Pre-FX1 this window
    ; up-hopped +$28C6 to staging — that defensive degrade moves to the new
    ; end of the array, below.)
    ld a, d
    cp $ad
    jr z, .mlow
    cp $ae
    jr nz, .uptest2
    ld a, e
    cp $34
    jr nc, .uptest2
    jr .mid
.mlow:
    ld a, e
    cp $9f
    jr c, .uptest2
.mid:
    ld a, e
    add $85
    ld e, a
    ld a, d
    adc $03
    ld d, a                         ; DE += $0385 -> extended farm SRAM
    ld a, $0a
    ld [$0100], a                   ; walker derefs continue in SRAM
    ret
.uptest2:
    ; up-hop test (FX1: moved to the 40-slot end): $BCC8 <= DE <= $BD5C
    ; (slot 39 end $BCC7 + 1, field f in [0,$94]). DE += $199D -> staging
    ; $D665 + f — same defensive degrade as S60: no bounded walk goes past
    ; slot 39, so this only fires on the discarded post-loop advance.
    ld a, d
    cp $bc
    jr z, .ulow
    cp $bd
    ret nz
    ld a, e
    cp $5d
    ret nc
    jr .up
.ulow:
    ld a, e
    cp $c8
    ret c
.up:
    ld a, e
    add $9d
    ld e, a
    ld a, d
    adc $19
    ld d, a                         ; DE += $199D -> staging WRAM
    ret

; -----------------------------------------------------------------------------
; Entry 3 — CF3RebaseDE: GMDP slow path (pointer's high byte >= $CC).
; In/out: DE = computed monster pointer (base + slot*$95, base $CAC1..$CB55).
; If DE in [$CC80,$D664] (farm slots 3-19) -> DE -= $28C6 + enable SRAM.
; Party ($CAC1-$CC7F, fast-pathed in ROM0), staging ($D665+), and any
; non-array base a caller might feed GMDP pass through untouched.
; -----------------------------------------------------------------------------
CF3RebaseDE:
    ; FX1 (S71): the computed (vanilla-WRAM-model) address space now decodes
    ; THREE array regions. GMDP computes base+slot*$95 with slot masked $7F;
    ; per-slot computed spans (record base .. +$94, field bases shift within):
    ;   slots  3-19: [$CC80,$D664] -> real = computed - $28C6 (farm, SRAM b0)
    ;   slots 20-39: [$D665,$E208] -> real = computed - $2541 (EXTENDED farm,
    ;                SRAM b0 $B124-$BCC7 — the evicted sleep pool's home)
    ;   slots 40/41: [$E209,$E332] -> real = computed - $0BA4 (staging WRAM
    ;                $D665/$D6FA — the pseudo-slot INDICES moved 20/21 ->
    ;                40/41 in FX1; their ADDRESSES are unchanged, so every
    ;                address-based staging path — breeding field+$0BA4 math,
    ;                trade copy loops — is untouched)
    ; Anything else passes through (party fast-pathed in ROM0; non-array
    ; bases; slots >= 42 = garbage-in-garbage-out, vanilla parity).
    ld a, d
    cp $cc
    jr nz, .hi
    ld a, e
    cp $80
    ret c                           ; $CC00-$CC7F: party slot 2 tail — leave
    jr .reb
.hi:
    ld a, d
    cp $d6
    jr c, .reb                      ; $CD00-$D5FF: in farm window
    jr nz, .hi2
    ld a, e
    cp $65
    jr c, .reb                      ; $D600-$D664: farm window tail
    jr .reb2                        ; $D665-$D6FF: extended farm head
.hi2:
    cp $e2
    jr c, .reb2                     ; $D700-$E1FF: extended farm window
    jr nz, .out                     ; $E300+ handled below
    ld a, e
    cp $09
    jr c, .reb2                     ; $E200-$E208: extended farm tail
    jr .stg                         ; $E209-$E2FF: staging window head
.out:
    ld a, d
    cp $e3
    ret nz                          ; $E400+: out
    ld a, e
    cp $33
    ret nc                          ; $E333+: out
.stg:
    ld a, e
    sub $a4
    ld e, a
    ld a, d
    sbc $0b
    ld d, a                         ; DE -= $0BA4 -> staging WRAM ($D665+)
    ret
.reb2:
    ld a, e
    sub $41
    ld e, a
    ld a, d
    sbc $25
    ld d, a                         ; DE -= $2541 -> extended farm SRAM
    jr .en
.reb:
    ld a, e
    sub $c6
    ld e, a
    ld a, d
    sbc $28
    ld d, a                         ; DE -= $28C6 -> farm SRAM
.en:
    ld a, $0a
    ld [$0100], a                   ; pointer will be dereferenced by the caller
    ret

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
; Entry 4 — CF3Checksum: replaces SRAMWriteBlock's interior. All three
; vanilla call sites pass HL=$A002/BC=$1FFE (constant). Returns DE = the
; v3 sum; verify path compares stored, save path's caller stores DE.
; Leaves SRAM enabled (CF3 policy).
; -----------------------------------------------------------------------------
CF3Checksum:
    ld a, $0a
    ld [$0100], a
    ; --- FX1 (S71) ONE-TIME REFORMAT ("F2" gate, $BFC8-$BFC9 of the reserved
    ; tail). ORDER IS LOAD-BEARING (S71 PyBoy catch: writing F2 before the
    ; legacy-sum heal broke every pre-FX1 save — the magic bytes sit INSIDE
    ; all legacy checksum ranges AND inside v3's tail segment):
    ;   F2 present -> compute v3, verify/heal, done (post-conversion path).
    ;   F2 absent  -> [1] migrate any sleeping pool bank0 $B124 -> bank2
    ;                 ("P1" magic) when the sleep flag image $A17B bit7 is
    ;                 set, then ZERO $B124-$BCC7 (now farm slots 20-39 read
    ;                 UNGATED - garbage here is the S54 phantom class);
    ;                 [2] compute the three LEGACY sums over the F2-less
    ;                 bytes and match against the stored checksum (the pool
    ;                 contribution the zeroing removed is re-added from its
    ;                 bank-2 image by .sum2);
    ;                 [3] write F2; [4] compute v3 (F2 bytes now included);
    ;                 [5] legacy match -> store v3 (converted in place);
    ;                 no match -> return v3 unstored (a genuinely corrupt
    ;                 save wipes exactly as vanilla).
    ; The bank $40 4-bank wipe / corrupt-save wipe clear F2 -> next verify
    ; re-runs (bit7 then clear; region re-zeroed; harmless).
    ld a, [$bfc8]
    cp $46                          ; 'F'
    jr nz, .reformat
    ld a, [$bfc9]
    cp $32                          ; '2'
    jp z, .v3direct
.reformat:
    ld a, [$a17b]
    bit 7, a
    jr z, .refzero                  ; pool never initialized -> just zero
    ; migrate 20 pool records bank0 $B124+ -> bank2 $A010+ (per-byte RAMB
    ; toggle; pin-safe: ISR graph is SRAM/RAMB-free — S69 audit)
    ld hl, $b124
    ld de, $a010
    ld bc, $0ba4                    ; 20 x $95
.refmig:
    ld a, [hl+]
    push af
    ld a, $02
    ld [$4100], a                   ; RAMB := 2
    pop af
    ld [de], a
    xor a
    ld [$4100], a                   ; pin re-asserted per byte
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .refmig
    ld a, $02
    ld [$4100], a
    ld a, $50                       ; 'P'
    ld [$a000], a
    ld a, $31                       ; '1'
    ld [$a001], a
    xor a
    ld [$4100], a
.refzero:
    ld hl, $b124
    ld bc, $0ba4
.refz:
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .refz
    ; --- legacy-format match, computed BEFORE F2 exists ---
    ; formats: (1) vanilla full $A002 x $1FFE; (2) S60v1 $A002 x $3B8 +
    ; $AD9F x $1261; (3) S60v2 $A002 x $1C5 + $AD9F x $1261. Each + .sum2
    ; (bank-2 pool image) to restore the zeroed pool bytes' contribution.
    ld de, $4638
    ld hl, $a002
    ld bc, $1ffe
    call .sum
    call .sum2
    call .cmpstored
    jr z, .convert
    ld de, $4638
    ld hl, $a002
    ld bc, $03b8
    call .sum
    ld hl, $ad9f
    ld bc, $1261
    call .sum
    call .sum2
    call .cmpstored
    jr z, .convert
    ld de, $4638
    ld hl, $a002
    ld bc, $01c5
    call .sum
    ld hl, $ad9f
    ld bc, $1261
    call .sum
    call .sum2
    call .cmpstored
    jr z, .convert
    ; no legacy match: stamp F2 anyway (the reformat DID run; leaving it
    ; unstamped would re-zero forever) and return v3 unstored -> the
    ; corrupt-save wipe path fires as designed.
    call .stampf2
    jr .v3sum
.convert:
    call .stampf2
    call .v3sum_sub                 ; DE := v3 over the now-F2-stamped bytes
    ld a, e
    ld [$a000], a
    ld a, d
    ld [$a001], a
    ret
.v3direct:
    call .v3sum_sub
    ld a, [$a000]
    cp e
    ret nz                          ; mismatch -> caller wipes (vanilla path)
    ld a, [$a001]
    cp d
    ret
.v3sum:
    call .v3sum_sub
    ret
.stampf2:
    ld a, $46
    ld [$bfc8], a
    ld a, $32
    ld [$bfc9], a
    ret
.v3sum_sub:
    ; v3 formula (FX1): exclude the roster image $A1C7-$AD9E AND the
    ; extended farm $B124-$BCC7 (both uniformly EAGER live stores):
    ;   $A002 x $1C5 + $AD9F x $385 + $BCC8 x $338
    ld de, $4638
    ld hl, $a002
    ld bc, $01c5
    call .sum
    ld hl, $ad9f
    ld bc, $0385
    call .sum
    ld hl, $bcc8
    ld bc, $0338
    call .sum
    ret
.cmpstored:                         ; Z set iff stored checksum == DE
    ld a, [$a000]
    cp e
    ret nz
    ld a, [$a001]
    cp d
    ret
.sum:
    ld a, [hl+]
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    dec bc
    ld a, b
    or c
    jr nz, .sum
    ret
.sum2:
    ; add bank2 pool image ($A010 x $BA4) to DE if "P1" magic present (i.e.
    ; a pool was migrated); no-op when the pool was never initialized (the
    ; old $B124 bytes were zero, contributing nothing to legacy sums).
    ld a, $02
    ld [$4100], a
    ld a, [$a000]
    cp $50
    jr nz, .s2out
    ld a, [$a001]
    cp $31
    jr nz, .s2out
    ld hl, $a010
    ld bc, $0ba4
.s2l:
    ld a, [hl+]
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    dec bc
    ld a, b
    or c
    jr nz, .s2l
.s2out:
    xor a
    ld [$4100], a
    ret

; -----------------------------------------------------------------------------
; Entry 5 — CF3CopyToSRAM: CopySRAMBlock body (WRAM/HRAM -> SRAM), source HL
; via the wCF3CopyMbx mailbox (rst $10 eats HL), DE=dest, BC=len.
; Writes into the farm window [$A3BA,$AD9E] are SKIPPED (pointers/count still
; advance, so the rest of the block lands at vanilla offsets). This one rule
; masks both SaveGameState's $C8EA->$A024 image copy and SavePartyToSRAM's
; $CAC1->$A1FB block with zero operand changes — the farm's SRAM home is the
; live store and must never be overwritten from WRAM.
; -----------------------------------------------------------------------------
CF3CopyToSRAM:
    ld a, $0a
    ld [$0100], a
    ld hl, sp+6                 ; recover the TRUE length: rst $10's dispatcher
    ld c, [hl]                  ; clobbers BC (ld bc,$4001 table index), so the
    inc hl                      ; husk pushes BC before its rst. Constant frame:
    ld b, [hl]                  ; [+0]=dispatch-ret [+2]=bank-af [+4]=husk-ret
                                ; (rst $10's own push!) [+6]=BC
    ld a, [wCF3CopyMbxLo]
    ld l, a
    ld a, [wCF3CopyMbxHi]
    ld h, a
.loop:
    ld a, d
    cp $a3
    jr c, .store
    jr z, .dlo
    cp $ad
    jr c, .skip                     ; $A400-$ACFF: in window
    jr nz, .store                   ; $AE00+: out
    ld a, e
    cp $9f
    jr c, .skip                     ; $AD00-$AD9E: in window
    jr .store
.dlo:
    ld a, e
    cp $ba
    jr c, .store                    ; $A300-$A3B9: out
.skip:
    ld a, [hl+]                     ; consume source, no write
    jr .adv
.store:
    ld a, [hl+]
    ld [de], a
.adv:
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ; S69v2: main-save detector (only SaveGameState's $C8EA->$A024 copy ends
    ; at DE=$B124 — same invariant entry 6 relies on; see its header) ->
    ; commit the roster snapshot to bank 1. All other entry-5 callers
    ; ($A003->$A024 header, SavePartyToSRAM ends $A3BA, $BCC8/$BEC8 blocks)
    ; fall through the nz rets unchanged. SRAM stays enabled (CF3 policy).
    ld a, d
    cp $b1
    ret nz
    ld a, e
    cp $24
    ret nz
    jp CF3SnapCommit

; -----------------------------------------------------------------------------
; Entry 6 — CF3CopyFromSRAM: CopyFromSRAM body (SRAM -> WRAM/HRAM), dest HL
; via mailbox, DE=src, BC=len. Reads FROM the farm window are skipped (dest
; still advances): the farm's WRAM shadow is dead space post-CF3, and the
; skip keeps restores from spraying 2.5KB of records over the freed range
; (where the custom room buffers now live).
; S65: after the MAIN IMAGE copy (the only invocation whose source ends at
; $A024+$1100 = $B124 — callers are exactly the 4 block copies in
; SRAMAccess_21B2, ends $A024/$B124/$BEC8/$BFC8; any future caller must not
; collide with $B124) the CF3-freed window $CC80-$D664 is ZEROED: its SRAM
; image is the live farm (skipped above), so without this a restore would
; carry boot-time or previous-session values into gameplay. Combined with
; ClearAllWRAM (power-on) and CF3NewGameClear (new game, zeroes $C8EA-$D9E9)
; this guarantees: GAMEPLAY ALWAYS STARTS WITH THE WINDOW ZEROED, immunizing
; the relocated buffers/step counters against any data-as-code boot
; scribbler and making save+reload step state deterministic (step 0).
; Registers are free at the tail: the caller reloads HL/DE/BC per copy.
; -----------------------------------------------------------------------------
CF3CopyFromSRAM:
    ld a, $0a
    ld [$0100], a
    ld hl, sp+6                 ; recover the TRUE length: rst $10's dispatcher
    ld c, [hl]                  ; clobbers BC (ld bc,$4001 table index), so the
    inc hl                      ; husk pushes BC before its rst. Constant frame:
    ld b, [hl]                  ; [+0]=dispatch-ret [+2]=bank-af [+4]=husk-ret
                                ; (rst $10's own push!) [+6]=BC
    ld a, [wCF3CopyMbxLo]
    ld l, a
    ld a, [wCF3CopyMbxHi]
    ld h, a
.loop:
    ld a, d
    cp $a3
    jr c, .store
    jr z, .dlo
    cp $ad
    jr c, .skip
    jr nz, .store
    ld a, e
    cp $9f
    jr c, .skip
    jr .store
.dlo:
    ld a, e
    cp $ba
    jr c, .store
.skip:
    inc hl                          ; advance dest, no read/write
    jr .adv
.store:
    ld a, [de]
    ld [hl+], a
.adv:
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
    ; S65: main-image copy detector (src end $B124 — see header)
    ld a, d
    cp $b1
    ret nz
    ld a, e
    cp $24
    ret nz
    ld hl, wCustomNPCBuffer         ; $CC80 — window start
.wclr:
    xor a
    ld [hl+], a
    ld a, h
    cp $d6
    jr nz, .wclr
    ld a, l
    cp $65
    jr nz, .wclr                    ; stops at HL=$D665: $CC80-$D664 zeroed
    ; S69v2: bank-1 roster snapshot — restore over the eager image if the
    ; magic is present, else SEED it (one-time migration of pre-v3 saves).
    jp CF3SnapRestore

; -----------------------------------------------------------------------------
; Entry 7 — CF3NewGameClear: hooked over the New Game handler's
; `ld hl,$C8EA / ld bc,$1100 / xor a / call FillNBytesWithRegA` (bank $15,
; ~$460x). Replicates the displaced WRAM image zero-fill, then zeroes the 17
; farm in-use flags in SRAM so a new game never inherits the previous save's
; farm. (Fresh/corrupt carts are already covered: LoadMap_60df's checksum
; wipe zeroes all of SRAM $A002+, farm included.) Flags-only is sufficient —
; every reader keys on +$00, and inserts rebuild the full record.
; -----------------------------------------------------------------------------
CF3NewGameClear:
    ld hl, $c8ea
    ld bc, $1100
.wclr:
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .wclr
    ld a, $0a
    ld [$0100], a
    ld hl, $a3ba                    ; farm slot 3 in-use flag
    ld b, $11                       ; 17 slots
.fclr:
    xor a
    ld [hl], a
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, .fclr
    ; FX1 (S71): extended farm slots 20-39 ($B124 + n*$95) — same flags-only
    ; rule (every reader keys on +$00; inserts rebuild the record).
    ld hl, $b124
    ld b, $14                       ; 20 slots
.fclr2:
    xor a
    ld [hl], a
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, .fclr2
    ret

; -----------------------------------------------------------------------------
; Entry 8 — CF3TradeRecv: hooked over both trade-receive copy loops
; (bank $18 jr_018_45b8 / ~$4CA8 region): staging pseudo-slot $15 ($D6FA,
; the received monster in transit) -> farm slot 19 at its SRAM home ($AD0A).
; The canonicalizer immediately after compacts it into place, exactly as
; vanilla did with the WRAM slot 19.
; -----------------------------------------------------------------------------
CF3TradeRecv:
    ; FX1 (S71): the vanilla hardcoded slot-19 insert is only safe while the
    ; farm can never hold >16 monsters around a trade. At 37 farm slots the
    ; target is FIRST-EMPTY over slots 3-39 (trade-away has always freed at
    ; least one slot, so a hit is guaranteed; the pre-FX1 hardcoded slot 19
    ; remains the impossible-case fallback). The canonicalizer immediately
    ; after compacts it into place, exactly as vanilla did with slot 19.
    ld a, $0a
    ld [$0100], a
    ld hl, $a3ba                    ; slot 3 in-use flag @ SRAM
    ld b, $11                       ; slots 3-19
.scan1:
    ld a, [hl]
    or a
    jr z, .found
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, .scan1
    ld hl, $b124                    ; slots 20-39 (extended farm)
    ld b, $14
.scan2:
    ld a, [hl]
    or a
    jr z, .found
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, .scan2
    ld hl, $ad0a                    ; fallback: slot 19 (unreachable by design)
.found:
    ld de, $d6fa                    ; staging slot $29 record (WRAM $D6FA)
    ld b, $95
.loop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, .loop
    ret

; -----------------------------------------------------------------------------
; Entry 9 — CF3SRAMBankedCopy (E3, S69): copy between WRAM/HRAM and a chosen
; SRAM bank under the RAMB-pin discipline. This is the ONLY sanctioned way to
; touch SRAM banks 1-3 in the 32 KB build (everything else in the engine runs
; with RAMB pinned to 0 — the ROM0 quadrant-convention writers were retargeted
; to the MBC5-ignored $6100; see ARCHITECTURE "SRAM banking as built S69").
;
; Params (mailbox, patches/wram.asm $DE8B-$DE91; transient, caller-written
; immediately before the call):
;   wSRAMXferBank  target RAMB 0-3 (bank of the SRAM side)
;   wSRAMXferSrc   source address       (either side may be $A000-$BFFF)
;   wSRAMXferDst   destination address
;   wSRAMXferLen   byte count ($0000 = no-op)
;
; DISCIPLINE (the load-bearing part — copy this pattern for any future banked
; access): RAMB != 0 exists ONLY inside a di window, restored to 0 before ei,
; per byte. The vblank audio ISR no longer writes RAMB (pin retarget), but an
; ISR between ei/di still expects the invariant RAMB==0 — which this loop
; maintains at every interruptible point. Per-byte bracketing is deliberate:
; worst-case audio latency is one byte-copy (~10 M-cycles), and the exemplar
; stays trivially verifiable. A chunked variant is a future optimization for
; the first hot consumer (none exists yet).
;
; CONTRACT: call with interrupts ENABLED (every normal gameplay context; the
; final ei assumes it). SRAM<->SRAM cross-bank copies are NOT supported (both
; dereferences happen under the same RAMB). SRAM is (re-)enabled on entry and
; left enabled (CF3 policy). rst $10 contract as usual: A/HL/flags clobbered,
; BC clobbered by the dispatcher; DE preserved here (push/pop).
; -----------------------------------------------------------------------------
CF3SRAMBankedCopy:
    push de
    ld a, $0a
    ld [$0100], a                   ; ensure SRAM enabled (CF3 policy)
    ld a, [wSRAMXferSrc]
    ld l, a
    ld a, [wSRAMXferSrc+1]
    ld h, a                         ; HL = src
    ld a, [wSRAMXferDst]
    ld e, a
    ld a, [wSRAMXferDst+1]
    ld d, a                         ; DE = dst
    ld a, [wSRAMXferLen]
    ld c, a
    ld a, [wSRAMXferLen+1]
    ld b, a                         ; BC = remaining
.next:
    ld a, b
    or c
    jr z, .done
    di
    ld a, [wSRAMXferBank]
    ld [$4100], a                   ; RAMB := target — di window ONLY
    ld a, [hl+]
    ld [de], a
    inc de
    xor a
    ld [$4100], a                   ; restore the pin invariant BEFORE ei
    ei
    dec bc
    jr .next
.done:
    pop de
    ret

; -----------------------------------------------------------------------------
; S69v2 — THE ROSTER SNAPSHOT (persistence semantics v3). Root cause it fixes,
; confirmed from the user's .sav: the v2 EAGER roster (canonicalizer tail
; mirrors WRAM $CA8D-$CC7F -> $A1C7-$A3B9; farm writes live) makes UNSAVED
; battle deaths and catches survive a reset — vanilla players expect a reset
; without saving to rewind everything to the last save. v3 restores vanilla
; semantics using the E3 32 KB expansion: SRAM BANK 1 holds a magic-gated
; snapshot of the roster block, written ONLY on explicit save (entry 5's
; main-copy detector) and restored OVER the eager image on load (entry 6's
; tail). Bank 0's roster region remains the LIVE store (GMDP addressing home
; for farm slots 3-19, crash-consistent between saves) — it just no longer
; survives a reload.
;
; SNAPSHOT REGION: $A1BF-$AD9E (3040 = 95 chunks x 32 B, no partial chunk).
; This is the roster block $A1C7-$AD9E plus 8 leading bytes $A1BF-$A1C6
; (image of WRAM $CA85-$CA8C): those live BELOW the canonicalizer mirror
; range, so bank 0 only ever holds their last-explicit-save values — the
; restore overwrite is a proven no-op, bought for exact 32-byte chunking.
;
; MAGIC: bank 1 $A000-$A001 = $52,$33 ("R3"). Deliberately mirrors where
; bank 0 keeps its checksum — different banks, no collision. The bank $40
; 4-bank wipe (if its $CBC6 gate ever fires) clears the magic -> next load
; re-seeds. The corrupt-save wipe (bank 0 only) leaves stale magic, but the
; save-present flag $A002 is then 0, so the load funnel never runs entry 6
; and the stale snapshot is overwritten by the next explicit save.
;
; INTERRUPT SAFETY (why NO di/ei — audited S69): under the RAMB pin no ISR
; writes RAMB (all 19 convention writers retargeted), and no ISR touches
; SRAM (vblank audio: zero SRAM literals in banks $41/$74; LCDC: scanline
; display code; timer: reti; serial: inactive during save/load contexts and
; pin-safe regardless). So a RAMB=1 window here is interrupt-transparent
; without brackets — which also makes these hooks IME-agnostic (the load
; funnel can run at boot with interrupts off; an unconditional ei would be
; a boot hazard). Contrast entry 9, the conservative any-context primitive,
; which keeps per-byte di/ei and remains the rule for future code.
;
; TIMELINE CONSISTENCY (adjudicated before building): pool $B124 stays
; vanilla-eager (vanilla wrote it at sleep-commit directly; the sleep-state
; flag lives in the main image and rewinds, gating stale pool copies
; exactly as vanilla did). wPendingFarmExp ($D9C8, main image) rewinds
; together with the farm records its drain feeds — one timeline. Trade-recv
; (entry 8) writes live farm; unsaved trades rewind like vanilla's WRAM
; farm did.
; -----------------------------------------------------------------------------

; CF3SnapXfer: move a 32-byte-chunked snapshot region between banks, staged
; through the 32-byte bounce buffer wSnapBounce ($DE92 — SRAM is not dual-
; port; the two banks cannot see each other directly).
; entry: B = source RAMB, C = dest RAMB, HL = region start, D = chunk count.
; (FX1/S71: parameterized — v3 hardcoded $A1BF/95.) clobbers A/D/E/HL.
; RAMB=0 on exit (re-asserted after EVERY chunk so RAMB!=0 windows stay
; ~200 cycles).
; FX1 regions: $A1BF x 95 chunks (roster, as v3) and $B124 x 94 chunks
; ($B124-$BCE3: extended farm $B124-$BCC7 + 28 bytes of the LAZY tile-buffer
; image $BCC8-$BCE3 bought for exact chunking — lazy bytes only change at
; explicit save, so bank 0 already holds their last-save values and the
; restore overwrite is a proven no-op, same argument as v3's 8 leading
; bytes).
CF3SnapXfer:
.chunk:
    push de
    ld a, b
    ld [$4100], a                   ; RAMB := source bank
    push hl
    ld de, wSnapBounce              ; $DE92; +32 = $DEB2, no page cross
.rd:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, e
    cp $b2
    jr nz, .rd
    ld a, c
    ld [$4100], a                   ; RAMB := dest bank
    pop hl
    ld de, wSnapBounce
.wr:
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, e
    cp $b2
    jr nz, .wr
    xor a
    ld [$4100], a                   ; pin re-asserted every chunk
    pop de
    dec d
    jr nz, .chunk
    ret

; CF3SnapCommit: bank 0 live roster + extended farm -> bank 1 snapshot
; (both regions), then write magic "R4". Reached from entry 5's main-save
; detector and from the seed paths below. SRAM already enabled by the
; calling entry.
CF3SnapCommit:
    ld b, 0
    ld c, 1
    ld hl, $a1bf
    ld d, 95
    call CF3SnapXfer
    ld b, 0
    ld c, 1
    ld hl, $b124
    ld d, 94
    call CF3SnapXfer
.magic:
    ld a, 1
    ld [$4100], a
    ld hl, $a000
    ld a, $52
    ld [hl+], a
    ld [hl], $34                    ; magic "R4" in bank 1 (FX1/S71; v3 = "R3")
    xor a
    ld [$4100], a
    ret

; CF3SnapRestore: entry 6 tail (runs after the main-image restore + window
; clear, exactly once per load). Magic present -> restore bank 1 -> bank 0,
; then re-copy the roster's WRAM span $CA8D-$CC7F from the rewound bank 0
; image $A1C7-$A3B9 (the main restore had filled it with EAGER values; this
; overwrite is the actual rewind the player sees). Ends flush at $CC80 —
; the just-zeroed window is untouched. Magic absent -> one-time migration:
; seed the snapshot from the live roster (current state becomes the saved
; state) via CF3SnapCommit.
CF3SnapRestore:
    ; FX1 (S71) magic ladder: "R4" -> restore BOTH regions; "R3" (a v3-era
    ; bank 1) -> restore the roster region only, then SEED the extended
    ; region from the live bytes (which the F2 reformat just zeroed or
    ; migrated — current state becomes the saved state, one-time) and
    ; upgrade the magic; anything else -> seed both (pre-v3 migration).
    ld a, 1
    ld [$4100], a
    ld hl, $a000
    ld a, [hl+]
    cp $52
    jr nz, .seed
    ld a, [hl]
    cp $34
    jr z, .r4
    cp $33
    jr nz, .seed
    ; --- "R3": restore roster, seed extended, upgrade magic ---
    xor a
    ld [$4100], a
    ld b, 1
    ld c, 0
    ld hl, $a1bf
    ld d, 95
    call CF3SnapXfer
    ld b, 0
    ld c, 1
    ld hl, $b124
    ld d, 94
    call CF3SnapXfer                ; seed extended live -> bank 1
    call CF3SnapCommit.magic        ; stamp "R4"
    jr .wramcopy
.r4:
    xor a
    ld [$4100], a
    ld b, 1
    ld c, 0
    ld hl, $a1bf
    ld d, 95
    call CF3SnapXfer
    ld b, 1
    ld c, 0
    ld hl, $b124
    ld d, 94
    call CF3SnapXfer
.wramcopy:
    ld hl, $a1c7                    ; rewound bank-0 roster -> WRAM
    ld de, $ca8d
    ld bc, $01f3
.rw:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .rw
    ret
.seed:
    xor a
    ld [$4100], a
    jp CF3SnapCommit

; =============================================================================
; FX1 (S71) — THE BANK-2 SLEEP POOL (the eviction that funded the expansion).
;
; The vanilla pool ($B124-$BCC7, 20 x $95, bank 0) is exactly the space the
; extended farm slots 20-39 now occupy. The pool moves to SRAM BANK 2:
;   bank2 $A000-$A001 = magic "P1" ($50,$31)
;   bank2 $A010 + c*$95, c = 0..39 (40 slots — a FULL non-party mirror, so
;   the whole-swap sleep exchange works at any party size; user decision S71
;   "whole-swap: if 37 active, 37 can sleep")
; Access is confined to these three entries + the checksum's .sum2 and the
; F2 reformat migration (entry 4). All use the same discipline as the
; snapshot hooks: short RAMB!=0 windows, no di/ei needed (ISR graph is
; SRAM-free and RAMB-free under the pin — S69 audit), pin re-asserted
; before return.
; =============================================================================

; Entry 10 — CF3PoolSwapRecord: exchange the 149-byte record of ARRAY slot D
; with BANK-2 POOL slot E. Array side resolved like the rebase map: slots
; 0-2 WRAM $CAC1+, 3-19 SRAM b0 $A1FB+s*$95, 20-39 SRAM b0 $B124+(s-20)*$95.
; (Party slots are never passed — the exchange loop skips flag $02 — but the
; resolver handles them anyway.) Per byte: read array (RAMB=0/WRAM), swap
; with pool byte under RAMB=2, write back under RAMB=0. DE preserved
; (dispatcher contract); BC dead (dispatcher clobbers).
CF3PoolSwapRecord:
    push de
    ld a, $0a
    ld [$0100], a
    ; HL := array slot D record base (Mul8x8To16: HL = A*C, clobbers BC,
    ; preserves A/DE)
    ld a, d
    cp $03
    jr c, .party
    cp $14
    jr c, .oldfarm
    sub $14                         ; slots 20-39: $B124 + (s-20)*$95
    ld c, $95
    call Mul8x8To16
    ld bc, $b124
    jr .base
.party:
    ld c, $95                       ; slots 0-2: WRAM $CAC1 + s*$95
    call Mul8x8To16
    ld bc, $cac1
    jr .base
.oldfarm:
    ld c, $95                       ; slots 3-19: SRAM b0 $A1FB + s*$95
    call Mul8x8To16
    ld bc, $a1fb
.base:
    add hl, bc                      ; HL = array record base
    ; DE' := bank-2 pool slot E record base = $A010 + e*$95
    push hl
    ld a, e
    ld c, $95
    call Mul8x8To16
    ld bc, $a010
    add hl, bc
    ld d, h
    ld e, l
    pop hl                          ; HL = array ptr, DE = pool ptr (bank 2)
    ld bc, $0095
.swap:
    ld a, [hl]
    push af                         ; t1 = array byte
    ld a, $02
    ld [$4100], a                   ; RAMB := 2
    ld a, [de]
    ld [wPoolBounce], a             ; t2 (WRAM scratch — bank-independent)
    pop af
    ld [de], a                      ; pool := t1
    xor a
    ld [$4100], a                   ; RAMB := 0 (pin re-asserted per byte)
    ld a, [wPoolBounce]
    ld [hl+], a                     ; array := t2
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .swap
    pop de
    ret

; Entry 11 — CF3PoolZeroInit: zero all 40 bank-2 pool records ($A010 x
; $1744) and write the "P1" magic. Called from the sleep first-time init
; (bank $12 SetItem_5fde replacement) — the vanilla equivalent zeroed
; bank-0 $B124 x $BA4.
CF3PoolZeroInit:
    push de
    ld a, $0a
    ld [$0100], a
    ld a, $02
    ld [$4100], a
    ld hl, $a010
    ld bc, $1744                    ; 40 x $95
.z:
    xor a
    ld [hl+], a
    dec bc
    ld a, b
    or c
    jr nz, .z
    ld a, $50                       ; 'P'
    ld [$a000], a
    ld a, $31                       ; '1'
    ld [$a001], a
    xor a
    ld [$4100], a
    pop de
    ret

; Entry 12 — CF3PoolCounts: census of the bank-2 pool -> E = occupied
; non-egg count, D = occupied egg count (E+D = total sleeping). Replaces
; the four bank $07 in-place pool scans and the bank $12 pool probes.
; Magic absent (pool never initialized) -> 0/0.
CF3PoolCounts:
    ld a, $0a
    ld [$0100], a
    ld a, $02
    ld [$4100], a
    ld de, $0000
    ld a, [$a000]
    cp $50
    jr nz, .out
    ld a, [$a001]
    cp $31
    jr nz, .out
    ld hl, $a010
    ld b, 40
.slot:
    ld a, [hl]
    or a
    jr z, .adv
    push hl
    ld a, l
    add $63                         ; +$63 egg flag
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [hl]
    pop hl
    or a
    jr nz, .egg
    inc e
    jr .adv
.egg:
    inc d
.adv:
    ld a, l
    add $95
    ld l, a
    ld a, h
    adc $00
    ld h, a
    dec b
    jr nz, .slot
.out:
    xor a
    ld [$4100], a
    ret
