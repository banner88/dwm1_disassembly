; =============================================================================
; BANK $72 — CUSTOM-SKILL SYSTEM (S2d, de-aliased)
; =============================================================================
; The custom-skill REGISTRY + battle handlers. Custom skill ids ($DE-$FF) flow
; through the engine with their REAL value (no Blaze aliasing); a small set of
; byte-neutral forks teach each id-keyed subsystem about them:
;   - record   (bank $54 Fork54_RecordIndex)  -> targeting/MP/magnitude/status/AI
;   - dispatch (bank $52 $6CD5 -> FarSkillFork here -> CustomDispatch52 -> entry 1)
;   - name     (bank $41 SkillNamePtrTable repoint)
; Handlers run from THIS bank (reached via the $52 trampoline's `rst $10`), and
; use only ROM0 routines + RAM, so no bankswitch is needed inside a handler.
;
; Entry 0 = FarSkillFork  : dispatch hook return-HL provider (replaces $52:$6CD5).
; Entry 1 = CustomBattleExec: selects + runs the per-id battle handler.
;
; Registered skills:
;   $E0  MagicBurn  - spends HALF current MP; deals that exact amount to ALL foes
;                     (raw, no defense). Record (bank $54) gives target_mode $12.
;   $E1  Tame       - recruit (meter +10, FeedMeat tier) + ATK/4 damage, 1 foe.
;   $E2  TameMore   - Tame tier 2: meter +100 (PorkChop tier).      [Stage2]
;   $E3  TameMost   - Tame tier 3: meter +400 (Sirloin tier).       [Stage2]
; =============================================================================

SECTION "ROM Bank $072", ROMX[$4000], BANK[$72]

    db $72                              ; bank number (entry-table header)
    dw FarSkillFork                     ; entry 0  ($7200 -> $4001)
    dw CustomBattleExec                 ; entry 1  ($7201 -> $4003)
    dw AnchorField14Tail                ; entry 2  ($7202 -> $4005) [ANCHOR S73]
    dw QuakeSweep72                     ; entry 3  ($7203 -> $4007) [QUAKE] sweep-advance fork
    dw QuakeAnimHold72                  ; entry 4  ($7204 -> $4009) [QUAKE v3] $6c4d anim-gate fork: shakes live in the cast-anim slot (d9ee==3) and hold it until the train completes
    ; entry 5 reserved for future

; -----------------------------------------------------------------------------
; FarSkillFork (entry 0) — replaces the dispatch's `ld hl,$4011/add hl,bc/add hl,bc`
; at $52:$6CD5. Returns HL = &handler-pointer; the dispatch's `call RST_08` derefs
; and jp's it (bank $52 mapped). bc is not relied upon afterwards.
;   id <  $DE  -> HL = $4011 + id*2     (vanilla SkillFunctionTable)
;   id >= $DE  -> HL = $7FED            (CustomSkillPtr in $52 -> CustomDispatch52)
; The $db8a==0 / $db86 path is the legacy alias hook; with de-aliasing $db86 is
; always 0, so a genuine Blaze cast (id 0) correctly falls to the vanilla path.
; -----------------------------------------------------------------------------
FarSkillFork:
    ld a, [$db8a]                       ; working skill id
    or a
    jr nz, .haveid
    ld a, [$db86]                       ; legacy alias fallback (now always 0)
.haveid:
    cp $DE
    jr c, .vanilla
    cp $E9
    jr z, .mourn                        ; [MOURN S75] defense-calc dispatch path
    ld hl, $7FED                        ; CustomSkillPtr (bank $52)
    ret
.mourn:
    ld hl, MournDispatchPtr             ; [MOURN S75] -> MournDispatch52 (CalcDefenseWrapper path)
    ret                                 ; (cross-bank label; assembles in one pass via game.asm)
.vanilla:
    ld c, a
    ld b, $00
    ld hl, $4011
    add hl, bc
    add hl, bc
    ret

; -----------------------------------------------------------------------------
; CustomBattleExec (entry 1) — far-called from $52:CustomDispatch52. Reads the
; real id and tail-jumps to its handler (handler `ret` returns through the rst).
; -----------------------------------------------------------------------------
CustomBattleExec:
    ld a, [$db8a]
    cp $E0
    jp z, SkillMagicBurn
    cp $E1
    jp z, SkillTame
    cp $E2
    jp z, SkillTame                     ; [Stage2] TameMore -> same handler, tiered meter
    cp $E3
    jp z, SkillTame                     ; [Stage2] TameMost -> same handler, tiered meter
    cp $E5
    jr c, .notquake
    cp $E9
    jp c, SkillQuake                    ; [QUAKE] $E5 Tremor / $E6 Quake / $E7 QuakeMore / $E8 QuakeMost
    cp $E9
    jp z, SkillMourn                     ; [MOURN] $E9 Mourn: ATK×(dead_allies+1) with defense
.notquake:
    ; $E4 Anchor is FIELD-ONLY: in battle it falls through to this ret and,
    ; with its record's anim9=$02 (announce/animate gates clear — the MagicBurn
    ; finding inverted), the cast is a silent no-op. [S73 v1; a "can't use in
    ; battle" message is v2 polish.]
    ; (future custom battle skills dispatch here)
    ret

; -----------------------------------------------------------------------------
; SkillMagicBurn ($E0) — the per-skill CUSTOM override, far-called from
; CustomDispatch52 AFTER it has run LoadBattle_653e (context + base damage) and
; SetHLBattle_54e7 (descriptor). So the message/target context is already exactly
; MegaMagic's; here we only replace the damage value and charge the real cost:
;   spent = currentMP >> 1                  (floor; = damage dealt to each foe)
;   $db56/57 <- spent                        (OVERRIDES LoadBattle_653e's value)
;   wBattleMP[attacker] -= spent             (record+4=0, so the engine deducts none)
; Damage is RAW (we set the final $db56; the applier uses it directly). ROM0 + RAM only.
; -----------------------------------------------------------------------------
SkillMagicBurn:
    ld a, [$db88]                       ; wBattleAttackerIdx
    call GetCombatantMP                 ; HL = attacker current MP (value, not ptr)
    srl h
    rr l                                ; HL = MP >> 1  (= MP spent = damage)
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a                       ; OVERRIDE the damage LoadBattle_653e computed
    ; deduct the spent amount from wBattleMP[attacker]
    push hl                             ; save spent (-> DE)
    ld a, [$db88]
    add a                               ; idx*2
    ld e, a
    ld d, $00
    ld hl, $dbc3                        ; wBattleMP base
    add hl, de                          ; &wBattleMP[attacker]
    pop de                             ; DE = spent
    ld a, [hl]
    sub e
    ld [hl+], a
    ld a, [hl]
    sbc d
    ld [hl], a
    ret

; -----------------------------------------------------------------------------
; SkillTame ($E1/$E2/$E3) [S2e/Stage2] — the custom override for the Tame tier
; chain (Tame/TameMore/TameMost share this handler). Far-called from
; CustomDispatch52 AFTER LoadBattle_653e (context+base dmg) + SetHLBattle_54e7
; (descriptor), so target/message context is already set (record = single-foe).
; Two effects:
;   (1) damage = ATK/4  -> $db56/57   (OVERRIDES the record's 0 power; anti-abuse cap)
;   (2) taming meter $db83/$db84 += TameMeterTable[id-$E1] (10/100/400 = the
;       FeedMeat/PorkChop/Sirloin meat tiers), clamped to $0640 (1600)
;       -- byte-identical to feeding the equivalent meat, so post-battle
;          JoinDecision ($54:$55f1, HW-confirmed) rolls recruitment as if fed.
; ROM0 + RAM only; no bankswitch. wBattleAttackerIdx=$db88; ATK array base=$dbe3.
; -----------------------------------------------------------------------------
SkillTame:
    ; (0) [S2e] arm the heart->message delay (frames) so the heart plays before the hit text
    ld a, $28                           ; [S2e] 40 frames: heart plays, then sound+blink, then text
    ld [wTameDelay], a
    ; (1) damage = ATK/2
    ld a, [$db88]                       ; attacker idx
    add a                               ; idx*2
    ld e, a
    ld d, $00
    ld hl, $dbe3                        ; wBattleATK base
    add hl, de                          ; &ATK[attacker]
    ld a, [hl+]                         ; A = ATK low
    ld h, [hl]                          ; H = ATK high
    ld l, a                             ; HL = ATK (u16 LE)
    srl h
    rr l                                ; HL = ATK >> 1
    srl h
    rr l                                ; HL = ATK >> 2  [S2e] = ATK/4 (weaker than a normal hit)
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a                       ; OVERRIDE damage = ATK/4
    ; (2) taming meter += per-tier amount, clamp $0640
    ld a, [$db83]
    ld l, a
    ld a, [$db84]
    ld h, a                             ; HL = meter
    ld a, [$db8a]                       ; [Stage2] tier from the skill id
    sub $E1                             ;   0=Tame / 1=TameMore / 2=TameMost
    add a                               ;   *2 (u16 table)
    ld e, a
    ld d, $00
    push hl
    ld hl, TameMeterTable
    add hl, de
    ld a, [hl+]
    ld c, a
    ld b, [hl]                          ; BC = tier increment (10/100/400)
    pop hl
    add hl, bc
    ld a, h
    cp $06
    jr c, .store                        ; high < 6 -> under cap
    jr nz, .clamp                       ; high > 6 -> over cap
    ld a, l
    cp $40
    jr c, .store                        ; ==6 and low < $40 -> under cap
.clamp:
    ld hl, $0640                        ; cap = 1600
.store:
    ld a, l
    ld [$db83], a
    ld a, h
    ld [$db84], a
    ret

; [Stage2] Per-tier taming-meter increments, indexed (skill_id - $E1) * 2.
; Values = the vanilla per-meat meter boosts (meat record power_enemy words):
; FeedMeat +10 / PorkChop +100 / Sirloin +400; cap $0640 (1600) unchanged.
TameMeterTable:
    dw 10                               ; $E1 Tame     (FeedMeat tier)
    dw 100                              ; $E2 TameMore (PorkChop tier)
    dw 400                              ; $E3 TameMost (Sirloin tier)

; =============================================================================
; [QUAKE] SkillQuake ($E5-$E8 Tremor/Quake/QuakeMore/QuakeMost) — the Earthquake
; tier chain. Far-called from CustomDispatch52 ONCE PER SWEEP TARGET (the
; all-target loop at $52:$7184 re-runs the whole effect pipeline per alive
; target — PyBoy-measured this session). Per run:
;   (0) one-shot at sweep start (wQuakePhase==0): phase:=1, play the GreatTree
;       rumble (SFX $68 — the EvtDemo scene-3 sound, PyBoy-measured) and arm
;       the ROM0 VBlank SCY wobble ($c8b1 := frames; dormant vanilla driver at
;       $00:$056e, applied AFTER ApplyScrollRegisters, self-terminating).
;   (1) damage = record power roll, side-selected like the vanilla reader the
;       $535F entry would do (attacker bit2 -> +11/party or +15/enemy pair),
;       via the FORKED bank $54 generic reader (entry 0; custom ids resolve
;       through CustomRecordPtrTable): damage = min + (wRNG1 mod (range+1)).
;   (2) if the TARGET is on the ATTACKER's side (an ally caught in the wave),
;       damage /= 3  (integer, subtract-loop).
;   (3) $db56/57 := damage (overrides LoadBattle_653e's context value).
; Flying targets never reach this handler (QuakeSweep72 + the first-target
; fork skip them). ROM0 + RAM only; BC/DE free per CustomBattleExec contract.
; =============================================================================
SkillQuake:
    ; (0) sweep-start one-shot
    ld a, [wQuakePhase]
    or a
    jr nz, .damage
    ld a, $01
    ld [wQuakePhase], a
    ; capture the TRUE caster: $db88 is unreliable (the per-target redirect
    ; $53:CallBtlC_5e38 rewrites it — measured S74). Derive it from the ACTION
    ; QUEUE instead: the slot whose queued action id == our skill id. (If two
    ; monsters queued the same tier this frame the first match wins — v1 note.)
    ld hl, $dcec                        ; action queue: (id, target) x 8, stride 2
    ld a, [$db8a]
    ld c, a                             ; C = our id
    ld b, $00                           ; B = slot counter
.findcaster:
    ld a, [hl]
    cp c
    jr z, .foundcaster
    inc hl
    inc hl
    inc b
    ld a, b
    cp $08
    jr c, .findcaster
    ld b, $00                           ; not found (shouldn't happen): slot 0
.foundcaster:
    ld a, b
    ld [wQuakeCaster], a
    ; presentation note [v3]: the rumble + tier-scaled shake bursts now play
    ; INSIDE the cast-animation slot (d9ee==3), armed and sequenced by
    ; QuakeAnimHold72 (entry 4) BEFORE this handler ever runs — the vanilla
    ; ordering (anim -> announce -> per-target blink/damage) then holds by
    ; construction. Hard-clear the train state here as staleness hardening.
    xor a
    ld [wQuakeArmed], a
.damage:
    ; (1) power roll from QuakePowerTable (bank-local: min/range bytes per tier;
    ;     both sides use the same numbers). The record's power words stay 0 —
    ;     nonzero record powers loop the presentation phase (S74 stall finding)
    ;     — and reading the table here also avoids nested rst $10 record reads.
    ld a, [$db8a]
    sub $E5
    add a                               ; (id - $E5) * 2
    ld e, a
    ld d, $00
    ld hl, QuakePowerTable
    add hl, de
    ld a, [hl+]
    ld e, a                             ; E = min (fits in a byte for all tiers? no —
                                        ;   QuakeMost min 240 fits; all mins <= 240)
    ld a, [hl]                          ; A = range
    push af
    ld l, e
    ld h, $00                           ; HL = min
    pop af
    ; roll r = wRNG1 mod (range+1); range <= 255 here
    inc a
    ld b, a                             ; B = range+1 (modulus)
    ld a, [wRNG1]
.mod:
    cp b
    jr c, .rolled
    sub b
    jr .mod
.rolled:
    ; HL += r
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ; (2) ally? -> damage/3. Keyed on the SWEEP PHASE, not target-side compares:
    ; phase 1 = the committed victim side (full damage), phase >= 2 = the
    ; crossover onto the caster's OWN side (1/3). This is immune to the
    ; first-dispatch $db89 staleness (target is set AFTER the phase-0 dispatch
    ; — measured S74) and to the $db88 mid-sweep contamination.
    ld a, [wQuakePhase]
    cp $02
    jr c, .store                        ; phase 0/1: victim side -> full damage
    ; integer divide HL by 3 (subtract loop; HL <= ~300 here)
    ld bc, $0000                        ; BC = quotient
.div3:
    ld a, l
    sub $03
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    jr c, .divdone
    inc bc
    jr .div3
.divdone:
    ld l, c
    ld h, b
.store:
    ; [v3] FLYING target: keep the beat (the fly line renders instead of the
    ; damage text — LoadB4c_MaybeFlew) but land nothing. $db89 is the current
    ; target at every dispatch (sweep E-contract + first-target scan).
    push hl
    ld a, [$db89]
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    pop hl
    jr z, .keep
    ld hl, $0000
.keep:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret

; [QUAKE] Per-tier damage rolls, indexed (skill_id - $E5) * 2: min, range.
; damage = min + (RNG mod (range+1)); allies then take 1/3. EDITOR-OWNED
; tuning (v1 placeholders): 40-60 / 90-120 / 150-190 / 240-270; top tier =
; 1.5x WhiteAir (160-180). Keep CustomMPCostTable (bank $07) + record +4
; (bank $54) in sync when rebalancing costs.
QuakePowerTable:
    db 40, 20                           ; $E5 Tremor    40-60
    db 90, 30                           ; $E6 Quake     90-120
    db 150, 40                          ; $E7 QuakeMore 150-190
    db 240, 30                          ; $E8 QuakeMost 240-270

; =============================================================================
; [QUAKE] QuakeSweep72 (entry 3) — far target of the $52:$719C sweep-advance
; window. Reproduces the vanilla step exactly for stock ids; adds the Quake
; behaviors for ids $E5-$E8. Called via rst $10 (A/BC clobbered on the way
; back), so the contract is register-poor by design:
;   out: D = 1 -> finish the sweep (jp Jump_052_7085)
;        D = 0 -> continue; E = next_target - 1 (the window's `inc a` restores)
; Vanilla semantics reproduced: ceiling = (cur & 4) ? $07 : $03; finish when
; cur == ceiling; else next = cur+1 (the caller's CheckMonsterSlot dead-skip
; loop then re-enters this fork for each dead/empty slot, so alive-checking
; stays the caller's job).
; Quake additions (id in $E5-$E8):
;   - while advancing, ALSO skip the caster and any flying combatant
;     ($db8b[k] bit4 — the LegSweep bit, both sides);
;   - at the FIRST side's ceiling (wQuakePhase < 2): CROSS OVER to the
;     caster's own side instead of finishing — set wQuakePhase=2, arm the
;     "seismic wave" message (wQuakeAllyMsg=1; rendered + held by the widened
;     TameGateHook in bank $53, wTameDelay=45), and aim the sweep at the own
;     side's base-1 so the advance scan finds the first valid ally;
;   - at the SECOND side's ceiling (wQuakePhase == 2): clear state, finish.
; =============================================================================
QuakeSweep72:
    ld a, [$db89]                       ; wBattleTargetIdx (current)
    ld e, a
    and $04
    jr z, .ceilParty
    ld d, $07
    jr .haveCeil
.ceilParty:
    ld d, $03
.haveCeil:
    ; is this a Quake cast?
    ld a, [$db8a]
    cp $E5
    jr c, .vanilla
    cp $E9
    jr c, .quake
.vanilla:
    ld a, e
    cp d
    jr z, .vfinish
    ; continue: E = cur (window's inc a -> cur+1)
    ld d, $00
    ret
.vfinish:
    ld d, $01
    ret

.quake:
    ld a, e
    cp d
    jr z, .atCeiling
.qadvance:
    inc e                               ; candidate = next slot
    ld a, e
    cp d
    jr z, .qcheckLast                   ; candidate == ceiling: still a real slot,
                                        ;   check it (slot 3/7 can hold a monster)
    jr nc, .atCeiling                   ; past ceiling (defensive)
.qcheckLast:
    ; skip the TRUE caster (NOT $db88 — target-contaminated mid-sweep).
    ; [v3] FLYING combatants are NOT skipped any more: they get a real
    ; per-target beat (0 damage + the "flew above it!" line) so the player
    ; sees why nothing landed — including the all-allies-flying case.
    ld a, [wQuakeCaster]
    cp e
    jr z, .qskip
    ; candidate accepted: return E = candidate-1, D=0 (window incs back)
    dec e
    ld d, $00
    ret
.qskip:
    ld a, e
    cp d
    jr c, .qadvance                     ; more slots on this side
    ; skipped through the ceiling slot -> side exhausted
.atCeiling:
    ld a, [wQuakePhase]
    cp $02
    jr nc, .qfinish                     ; own-side pass done -> finish
    ; ---- CROSSOVER: enemies done, sweep the caster's own side ----
    ld a, $02
    ld [wQuakePhase], a
    ld a, $01
    ld [wQuakeAllyMsg], a               ; TameGateHook renders the seismic msg
    ld a, $2d                           ; ~45-frame hold so the message is readable
    ld [wTameDelay], a
    ld a, [wQuakeCaster]                ; TRUE caster's side base (0 or 4)
    and $04
    ld e, a
    dec e                               ; E = base-1
    ld a, e
    add $04
    ld d, a                             ; D(temp) = own-side ceiling = base+3
    jr .qadvance                        ; scan for the first valid ally
.qfinish:
    xor a
    ld [wQuakePhase], a
    ld [wQuakeAllyMsg], a
    ld [wQuakeArmed], a
    ld d, $01
    ret

; -----------------------------------------------------------------------------
; QuakeAnimHold72 (entry 4) — far-called from the byte-neutral window at the
; $da82 animation gate ($52:$6c4d) in place of `ld a,[$da82] / or a /
; jr nz,<dispatch> / ld hl,$5f05 / rst $10`. Contract: E = the $da82 value the
; caller should act on (A/flags don't survive the rst $10 bank-restore).
; For every non-quake id it reproduces vanilla EXACTLY (read $da82; if zero,
; run the $5F animation driver via nested rst and re-read) — this keeps the
; d9ee action-setup machine ticking (starving the driver wedges it; measured).
; For the Earthquake tiers, ONLY in the cast-animation sub-state (d9ee==3,
; the slot the borrowed wind used to occupy): on entry, arm the rumble + the
; tier-count burst train (1..4); every frame, tick the train and keep
; reporting E=0 ("animation still running") until the real (quiet, $0D) anim
; has finished AND the last burst + stopper have played; then report done.
; The shake IS the cast animation, so the vanilla ordering — anim -> announce
; -> per-target blink/damage text — holds with zero pipeline surgery. The
; step-2 window and ROM0 remain fully vanilla.
; -----------------------------------------------------------------------------
QuakeAnimHold72:
    ld a, [$db8a]
    cp $E9
    jp z, .mourn                        ; [MOURN S75] double-slash replay (block at end)
    sub $E5
    cp $04
    jr nc, .vanilla
    ld a, [$d9ed]
    dec a
    jr nz, .vanilla                     ; the REAL anim slot lives under step 1
                                        ; only — d9ee also cycles 1,2,3 while
                                        ; d9ed==0 (idle), and arming there
                                        ; plays the train outside the action
                                        ; (measured v3 first run)
    ld a, [$d9ee]
    cp $03
    jr nz, .vanilla                     ; setup states still get vanilla service
    ld a, [wQuakeArmed]
    or a
    jr nz, .tick
    ld a, $01                           ; entering the anim slot: arm the train
    ld [wQuakeArmed], a
    ld a, $68                           ; GreatTree rumble (loops until stopper)
    ld [$c8b8], a
    ld a, [$db8a]
    sub $E5
    inc a                               ; 1..4 bursts by tier
    ld [wQuakeBursts], a
    xor a
    ld [wQuakePause], a
.tick:
    call QuakeShakeSeq
    ; vanilla gate duties (the quiet anim finishes near-instantly)
    ld a, [$da82]
    or a
    jr nz, .animreal
    ld hl, $5f05
    rst $10
    ld a, [$da82]
.animreal:
    or a
    jr z, .hold                         ; real anim not signalled yet
    ld a, [wQuakePause]
    cp $ff                              ; train terminal (stopper queued)?
    jr nz, .hold
    ld e, $01                           ; release the anim slot. STICKY: the
    ret                                 ; sub-machine can take several frames
                                        ; to leave d9ee==3, and clearing
                                        ; wQuakeArmed here re-armed the whole
                                        ; train each of those frames (measured
                                        ; v5: six Tremor bursts). wQuakeArmed
                                        ; is cleared by the handler's phase-0
                                        ; init and by .qfinish instead.
.hold:
    ld e, $00
    ret
.vanilla:
    ld a, [$da82]
    or a
    jr nz, .out
    ld hl, $5f05
    rst $10
    ld a, [$da82]
.out:
    ld e, a
    ret

; --- [MOURN S75v2] banner-then-double-slash for $E9 Mourn (jp'd from head) ---
; User feedback: the boost banner must come BEFORE the attack animation.
; The dead-ally condition is therefore evaluated HERE (MournCountDead, shared
; with the damage handler), the banner renders on slot entry, holds ~45
; frames, and only then do the two EvilSlash plays run. wMournSlashes is the
; state machine:  0 = idle (first entry: count dead; >0 -> render banner +
; wTameDelay=45 + state $FE; else -> state 2)  /  $FE = banner hold (tick
; wTameDelay; at 0 -> state 2; the slash driver is NOT ticked during the
; hold — the anim setup just waits in d9ee==3; measured safe, no starve)  /
; 2..1 = slash plays ($da82 done -> dec; re-arm via $5f06 entry-6 re-init)
; /  $FF = STICKY TERMINAL (the S74 trap: the sub-machine lingers in
; d9ee==3 ~2 frames after E=1, and 0-as-done re-armed the train every lap =
; infinite slashing, 26-frame period, measured). The handler's staleness
; clear resets $FF for the next cast; an abnormally aborted action leaves
; $FF -> the next cast skips banner+animation once and self-heals.
; Banner routing: wMournBoosted=1 is set just before the $FD render so
; LoadB4c_Fork routes it to the boost string; LoadB4c_MournBoost clears the
; flag, so the LATER announce $FD (flag 0) still renders "used Mourn!".
.mourn:
    ld a, [$d9ed]
    dec a
    jr nz, .vanilla
    ld a, [$d9ee]
    cp $03
    jr nz, .vanilla
    ld a, [wMournSlashes]
    cp $ff
    jr z, .mournTerminal                ; sticky done: hold E=1 till state exit
    cp $fe
    jr z, .mournBannerHold
    or a
    jr nz, .mournTick
    ; ---- first entry: banner phase decision ----
    call MournCountDead                 ; B = dead allies (0-2)
    ld a, b
    or a
    jr z, .mournArmSlashes              ; none dead: no banner, straight to slashes
    ld a, $01
    ld [wMournBoosted], a               ; route the $FD render to the boost string
    xor a
    ld [$c822], a                       ; mode 0
    ld a, $fd
    ld [$c823], a
    ld hl, $4c00                        ; battle-message renderer (forked);
    rst $10                             ;   LoadB4c_MournBoost clears the flag
    ld a, $2d                           ; ~45-frame readable hold BEFORE the slashes
    ld [wTameDelay], a
    ld a, $fe
    ld [wMournSlashes], a               ; state: banner hold
    jr .mournHold
.mournBannerHold:
    ld a, [wTameDelay]
    or a
    jr z, .mournArmSlashes              ; hold elapsed -> start the slashes
    dec a
    ld [wTameDelay], a
    jr .mournHold
.mournArmSlashes:
    ld a, $02                           ; arm 2 slash plays
    ld [wMournSlashes], a
.mournTick:
    ; tick the vanilla animation driver
    ld a, [$da82]
    or a
    jr nz, .mournSlashDone
    ld hl, $5f05                        ; entry 5: animation + d9ee tick
    rst $10
    ld a, [$da82]
    or a
    jr z, .mournHold                    ; not done yet
.mournSlashDone:
    ld a, [wMournSlashes]
    dec a
    ld [wMournSlashes], a
    or a
    jr z, .mournFin                     ; last slash done -> terminal
    ; re-arm: reset done-flag + re-init the animation via entry 6
    xor a
    ld [$da82], a
    ld hl, $5f06                        ; entry 6: visual dispatch (re-setup)
    rst $10
    jr .mournHold
.mournFin:
    ld a, $ff
    ld [wMournSlashes], a               ; terminal marker (sticky)
.mournTerminal:
    ld e, $01
    ret
.mournHold:
    ld e, $00
    ret

; -----------------------------------------------------------------------------
; QuakeShakeSeq — the burst sequencer, called once per frame by QuakeAnimHold72
; while the train is armed. Bursts of $10 frames of SCY wobble ($c8b1,
; decremented by the vanilla ROM0 wobble), $0C-frame gaps (wQuakePause),
; wQuakeBursts remaining; after the last burst queue SFX $00 (replaces the
; looping $68 = the rumble stopper) and park at wQuakePause=$FF (terminal).
; -----------------------------------------------------------------------------
QuakeShakeSeq:
    ld a, [$c8b1]
    or a
    ret nz                              ; a burst is on screen
    ld a, [wQuakePause]
    or a
    jr z, .idle
    cp $ff
    ret z                               ; terminal
    dec a
    ld [wQuakePause], a
    ret nz
    ld a, $10                           ; gap expired -> next burst
    ld [$c8b1], a
    ret
.idle:
    ld a, [wQuakeBursts]
    or a
    jr z, .stopper
    dec a
    ld [wQuakeBursts], a
    ld a, $0c
    ld [wQuakePause], a
    ret
.stopper:
    xor a
    ld [$c8b8], a
    ld a, $ff
    ld [wQuakePause], a
    ret

; =============================================================================
; [MOURN S75] SkillMourn ($E9) — "Mourn" custom skill handler. Far-called from
; CustomBattleExec AFTER CalcDefenseWrapper (via MournDispatch52 in bank $52)
; has already written ATK-vs-DEF damage to $db56/57. This handler:
;   (1) Counts dead allies (MournCountDead — shared with the anim fork).
;   (2) Multiplies $db56/57 by (dead_count + 1): 0 dead = 1× (normal), 1 = 2×,
;       2 dead = 3×. The multiplication is a simple add loop.
; [S75v2] The boost banner is NO LONGER armed here — it renders BEFORE the
; slashes, from QuakeAnimHold72's .mourn first entry (user feedback). The
; staleness clears below double as the terminal reset for that fork.
; ROM0 + RAM only; single-target, so $db88 is the stable caster.
; =============================================================================
SkillMourn:
    ; staleness hardening + the anim fork's terminal reset: wMournSlashes is
    ; $FF (sticky done) at this point in every normal action; clear it and
    ; the boost flag so no state leaks into the next cast.
    xor a
    ld [wMournBoosted], a
    ld [wMournSlashes], a
    call MournCountDead                 ; B = dead allies (0-2)
    ; multiply $db56/57 by (B + 1)
    ld a, b
    or a
    ret z                               ; 0 dead: damage stays at 1× (CalcDefenseWrapper result)
    ld a, [$db56]
    ld e, a
    ld a, [$db57]
    ld d, a                             ; DE = base damage
.mulLoop:
    ld a, [$db56]
    add e
    ld [$db56], a
    ld a, [$db57]
    adc d
    ld [$db57], a
    dec b
    jr nz, .mulLoop
    ret

; -----------------------------------------------------------------------------
; [MOURN S75v2] MournCountDead — shared dead-ally counter. Out: B = count
; (0-2). Party slots 0-3, skipping the caster ($db88 — stable: single-target,
; no sweep redirect). Present = $dd1b[slot] != $FF ($00=alive, $01=
; processed-KO "skip" — the engine flips 0->1 when its KO scan runs, measured
; S75; $FF=never existed. A `==0` presence test excluded a processed corpse
; -> the boost died after the scan). Dead = present && battle HP
; ($DBA3+slot*2) == 0. Clobbers A/C/D/HL.
; -----------------------------------------------------------------------------
MournCountDead:
    ld a, [$db88]                       ; caster slot
    ld c, a                             ; C = caster
    ld b, $00                           ; B = dead count
    ld d, $00                           ; D = slot counter (0-3)
.countLoop:
    ld a, d
    cp c
    jr z, .skipSelf                     ; skip the caster
    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    inc a                               ; Z iff was $FF
    jr z, .skipSelf                     ; empty slot (no monster ever)
    ; HP == 0 ?  ($DBA3 + slot * 2)
    ld a, d
    add a                               ; slot * 2
    ld hl, $dba3                        ; wBattleHP base
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    or [hl]                             ; HP low | HP high
    jr nz, .skipSelf                    ; alive
    inc b                               ; dead!
.skipSelf:
    inc d
    ld a, d
    cp $04                              ; party slots 0-3
    jr c, .countLoop
    ret

; =============================================================================
; [ANCHOR S73] AnchorField14Tail (entry 2) — far target of bank $14 entry 4's
; default tail (`rst $10 $7202`). For non-$E4 ids it reproduces the vanilla
; fizzle default ($da5e := $FF) verbatim. For $E4 it classifies the cast
; context and arms one of the four Anchor dialog scripts (medal_vault room
; $71, script ids 2-5, authored in project.json):
;   wInGateworld==1                  -> 2 gate-side confirm ("anchor + warp?")
;   town (wMapID < $30), anchor set  -> 3 return confirm ("spend 3/4 MP?")
;   gate-like room, not a maze floor -> 4 error: can't anchor here
;   town, no anchor stored           -> 5 error: no anchor set
; Arming = the measured ScriptInit-mimic (S73 PyBoy): wScriptMapType=$71
; (routes via GateAwareDispatch's script-type branch to CustomScriptRead),
; script id, counter=0, $D8D7 bit0. The script engine is gated on the UI-busy
; flags, so it only starts ticking after Anchor07Post has torn the menu down.
; The scripts' own init_dialog enters dialog mode (S70 protocol).
; $da5e is left at $E4 as the marker Anchor07Post keys on.
; Runs from bank $14 via rst: ROM0 + RAM only, no HL/BC assumptions on return.
; =============================================================================
AnchorField14Tail:
    ld a, [$da5e]
    cp $E4
    jr z, .anchor
    ld a, $ff                           ; vanilla default: unknown id -> fizzle
    ld [$da5e], a
    ret
.anchor:
    ld a, [wInGateworld]
    or a
    jr nz, .gateSide                    ; standard maze floor (only nonzero here)
    ld a, [wMapID]
    cp $30                              ; CheckGateWorldMapType threshold (MAP_OLDWELL):
    jr nc, .errSpecial                  ;   $30+ = special/boss/custom gate rooms
    ld a, [wAnchorFloor]                ; town side: anchor stored? (0 = none)
    or a
    jr z, .errNoAnchor
    ld a, 3                             ; script 3: return confirm
    jr .arm
.gateSide:
    ld a, 2                             ; script 2: gate-side confirm
    jr .arm
.errSpecial:
    ld a, 4                             ; script 4: can't anchor here
    jr .arm
.errNoAnchor:
    ld a, 5                             ; script 5: no anchor set
.arm:
    ld [$d8d4], a                       ; wScriptNPCId (CustomScriptRead index)
    ld [$d8dc], a                       ; NPC number shadow (belt-and-braces)
    ld a, $ff                           ; counter := $FFFF — the per-frame ticker
    ld [$d8d5], a                       ;   (ScriptExecContinue) pre-increments
    ld [$d8d6], a                       ;   BEFORE reading, landing on word[0]
    ld a, $71
    ld [$d8d3], a                       ; wScriptMapType := medal_vault
    ld a, $01
    ld [$d8d7], a                       ; script active (bit0)
    ld a, [wOPTN_and_Item_selection]    ; caster = the monster whose skill menu
    and $7f                             ;   we are in (party slot 0-2)
    ld [wAnchorCaster], a
    ret                                 ; $da5e stays $E4 -> Anchor07Post closes menu
