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
; =============================================================================

SECTION "ROM Bank $072", ROMX[$4000], BANK[$72]

    db $72                              ; bank number (entry-table header)
    dw FarSkillFork                     ; entry 0  ($7200 -> $4001)
    dw CustomBattleExec                 ; entry 1  ($7201 -> $4003)

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
    ld hl, $7FED                        ; CustomSkillPtr (bank $52)
    ret
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
; SkillTame ($E1) [S2e] — the custom override for Tame. Far-called from
; CustomDispatch52 AFTER LoadBattle_653e (context+base dmg) + SetHLBattle_54e7
; (descriptor), so target/message context is already set (record = single-foe).
; Two effects:
;   (1) damage = ATK/2  -> $db56/57   (OVERRIDES the record's 0 power; anti-abuse cap)
;   (2) taming meter $db83/$db84 += 10 (Beef Jerky tier), clamped to $0640 (1600)
;       -- byte-identical to feeding one Beef Jerky, so post-battle JoinDecision
;          ($54:$55f1, HW-confirmed) rolls recruitment exactly as if fed.
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
    ; (2) taming meter += 10, clamp $0640
    ld a, [$db83]
    ld l, a
    ld a, [$db84]
    ld h, a                             ; HL = meter
    ld bc, $0640                        ; [S2e TEST CRANK] one cast -> meter maxed (1600)
                                        ;   so recruitment is observable; real value = $000A (Beef Jerky)
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
