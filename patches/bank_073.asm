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
    ; up-hop test: $AD9F <= DE <= $AE33
    ld a, d
    cp $ad
    jr z, .ulow
    cp $ae
    ret nz
    ld a, e
    cp $34
    ret nc
    jr .up
.ulow:
    ld a, e
    cp $9f
    ret c
.up:
    ld a, e
    add $c6
    ld e, a
    ld a, d
    adc $28
    ld d, a                         ; DE += $28C6 -> staging WRAM
    ret

; -----------------------------------------------------------------------------
; Entry 3 — CF3RebaseDE: GMDP slow path (pointer's high byte >= $CC).
; In/out: DE = computed monster pointer (base + slot*$95, base $CAC1..$CB55).
; If DE in [$CC80,$D664] (farm slots 3-19) -> DE -= $28C6 + enable SRAM.
; Party ($CAC1-$CC7F, fast-pathed in ROM0), staging ($D665+), and any
; non-array base a caller might feed GMDP pass through untouched.
; -----------------------------------------------------------------------------
CF3RebaseDE:
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
    jr c, .reb                      ; $CD00-$D5FF: in window
    ret nz                          ; $D700+: out (staging $D7xx included)
    ld a, e
    cp $65
    ret nc                          ; $D665+: staging — leave
.reb:
    ld a, e
    sub $c6
    ld e, a
    ld a, d
    sbc $28
    ld d, a                         ; DE -= $28C6 -> farm SRAM
    ld a, $0a
    ld [$0100], a                   ; pointer will be dereferenced by the caller
    ret

; -----------------------------------------------------------------------------
; Entry 4 — CF3Checksum: replaces SRAMWriteBlock's interior.
; All three vanilla call sites pass HL=$A002/BC=$1FFE (constant), so the
; ranges are hardcoded. Returns DE = $4638 seed + byte-sum over
; [$A002..$A1C6] + [$AD9F..$BFFF] — the vanilla sum MINUS the entire roster
; image (list + library bits + party records + farm, $A1C7-$AD9E), which is
; uniformly EAGER under S60v2 (live farm + canonicalize-time party mirror)
; and must not be able to invalidate the save. Migration self-heal converts
; pre-CF3 (vanilla-sum) and S60v1 (two-segment) saves in place at the boot
; verify; details at .heal. At save time the extra passes are redundant but
; harmless (SaveTimestamp overwrites $A000/$A001 anyway). Leaves SRAM
; enabled (CF3 policy).
; -----------------------------------------------------------------------------
CF3Checksum:
    ld a, $0a
    ld [$0100], a
    ; --- v2 formula: exclude the WHOLE roster image $A1C7-$AD9E ---
    ; (party list + library bits + monster vars + party records + farm).
    ; S60v2: the roster is uniformly EAGER — the canonicalizer tail mirrors
    ; WRAM roster state into the image, so the checksum must not cover it,
    ; exactly as it must not cover the live farm.
    ld de, $4638
    ld hl, $a002
    ld bc, $01c5                    ; $A002..$A1C6 (world state before the list)
    call .sum
    ld hl, $ad9f
    ld bc, $1261                    ; $AD9F..$BFFF (image tail + sleep pool + buffers)
    call .sum
    ld a, [$a000]
    cp e
    jr nz, .heal
    ld a, [$a001]
    cp d
    ret z                           ; stored matches v2
.heal:
    ; MIGRATION SELF-HEAL — accept and convert two legacy stored formats:
    ;   (1) vanilla full sum over $A002 x $1FFE   (pre-CF3 saves)
    ;   (2) S60v1 two-segment sum ($A002 x $3B8 + $AD9F x $1261)
    ;       (saves written by the recalled first S60 build)
    ; Either match rewrites stored := v2 and returns v2 (verify passes,
    ; save converts in place). No match: return v2 untouched -> the vanilla
    ; corrupt-save wipe path fires as designed.
    push de                         ; save v2 sum
    ld de, $4638
    ld hl, $a002
    ld bc, $1ffe                    ; vanilla full range
    call .sum
    call .cmpstored
    jr z, .mig
    ld de, $4638
    ld hl, $a002
    ld bc, $03b8                    ; S60v1 head segment
    call .sum
    ld hl, $ad9f
    ld bc, $1261
    call .sum
    call .cmpstored
    jr z, .mig
    pop de
    ret                             ; genuine mismatch -> vanilla wipe path
.mig:
    pop de
    ld a, e
    ld [$a000], a
    ld a, d
    ld [$a001], a
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
    ret                             ; SRAM stays enabled (CF3 policy)

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
    ret

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
    ret

; -----------------------------------------------------------------------------
; Entry 8 — CF3TradeRecv: hooked over both trade-receive copy loops
; (bank $18 jr_018_45b8 / ~$4CA8 region): staging pseudo-slot $15 ($D6FA,
; the received monster in transit) -> farm slot 19 at its SRAM home ($AD0A).
; The canonicalizer immediately after compacts it into place, exactly as
; vanilla did with the WRAM slot 19.
; -----------------------------------------------------------------------------
CF3TradeRecv:
    ld a, $0a
    ld [$0100], a
    ld hl, $ad0a                    ; slot 19 @ SRAM ($A1FB + 19*$95)
    ld de, $d6fa                    ; staging slot $15 (WRAM)
    ld b, $95
.loop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, .loop
    ret
