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
;                     (runs once per target: each foe costs half of what is LEFT)
;   $E1  Tame       - recruit (meter +10, FeedMeat tier) + ATK/4 damage, 1 foe.
;   [S111b] the halves / quarters / thirds of $E0-$E9 are data: CustomRatioTable.
;   $E2  TameMore   - Tame tier 2: meter +100 (PorkChop tier).      [Stage2]
;   $E3  TameMost   - Tame tier 3: meter +400 (Sirloin tier).       [Stage2]
; =============================================================================

; [S111] offsets into CustomRatioTable (gd_custom_ratios, below AnchorKeepMP72)
DEF RATIO_MB_BURN    EQU 0              ; MagicBurn: share of current MP spent
DEF RATIO_MB_DAMAGE  EQU 2              ; MagicBurn: damage per MP spent
DEF RATIO_TAME       EQU 4              ; Tame / TameMore / TameMost: damage = ATK x (+2 per tier)
DEF RATIO_ANCHOR     EQU 10             ; Anchor: share of current MP charged on arrival
DEF RATIO_QUAKE_ALLY EQU 12             ; Tremor..QuakeMost: allies' share of the damage (+2 per tier)
DEF RATIO_MOURN      EQU 20             ; Mourn: bonus per fallen ally, x the base damage

; [S155] the seven custom skills of S155 (BATTLE_SKILL_SYSTEM §13.10; ids reused:
; $DE / $DF were the retired S45 POCs Scorch / Smite)
DEF ID_REPEL         EQU $DE            ; field: no random encounters (the Repellant's flag)
DEF ID_LONEWOLF      EQU $DF            ; ATK-vs-DEF x more in a party of two / alone
DEF ID_PLUNDER       EQU $EA            ; [S156] steals one of the target's buffs (SkillPlunder)
DEF ID_PUNISH        EQU $EB            ; ATK-vs-DEF + a share per buff on the target
DEF ID_FINISH        EQU $EC            ; ATK-vs-DEF x (low .. high) by the target's missing HP
DEF ID_RUPTURE       EQU $ED            ; consumes the target's ailments for ATK-vs-DEF x big
DEF ID_RUST          EQU $EE            ; lowers the target's ATK (Sap's roll: resistance 12)
; [S155] word offsets into CustomPctTable (gd_custom_pcts): percentages, 100 = x1
DEF PCT_LW_DUO       EQU 0              ; LoneWolf: the damage in a party of two
DEF PCT_LW_ALONE     EQU 2              ; LoneWolf: the damage alone
DEF PCT_PUNISH       EQU 4              ; Punish: + this per buff on the target
DEF PCT_FIN_LOW      EQU 6              ; Finish: the damage at full HP
DEF PCT_FIN_HIGH     EQU 8              ; Finish: the damage near 0 HP
DEF PCT_RUPTURE      EQU 10             ; Rupture: the damage when ailments burst
DEF PCT_RUST         EQU 12             ; Rust: the ATK lost, a share of the target's base ATK
DEF PCT_MAX          EQU 2000           ; MulPct72's range (x20)
; [S155] extra battle lines (bank $4C CustomLinePtrs, 1-based; 0 = none)
DEF LINE_LONEWOLF    EQU 1
DEF LINE_PUNISH      EQU 2
DEF LINE_FINISH      EQU 3
DEF LINE_RUPTURE     EQU 4
DEF LINE_RUST        EQU 5
DEF LINE_PLUNDER     EQU 6              ; [S156] the steal ({name} / {target} / {buff})
DEF LINE_PLUNDER_DEF EQU 7              ; [S156 r2] + "{name}'s defense goes up by {amount}!"
DEF LINE_PLUNDER_AGL EQU 8              ; [S156 r2] + "{name}'s speed goes up by {amount}!"

SECTION "ROM Bank $072", ROMX[$4000], BANK[$72]

    db $72                              ; bank number (entry-table header)
    dw FarSkillFork                     ; entry 0  ($7200 -> $4001)
    dw CustomBattleExec                 ; entry 1  ($7201 -> $4003)
    dw AnchorField14Tail                ; entry 2  ($7202 -> $4005) [ANCHOR S73]
    dw QuakeSweep72                     ; entry 3  ($7203 -> $4007) [QUAKE] sweep-advance fork
    dw QuakeAnimHold72                  ; entry 4  ($7204 -> $4009) [QUAKE v3] $6c4d anim-gate fork: shakes live in the cast-anim slot (d9ee==3) and hold it until the train completes
    dw ElemLevel72                      ; entry 5  ($7205 -> $400B) [S111] element override (bank $52 ElemLevel52)
    dw CustomLearnRow72                 ; entry 6  ($7206 -> $400D) [S111] custom learn row -> wLearnRowBuf (bank $06 LearnLoopFork)
    dw AnchorKeepMP72                   ; entry 7  ($7207 -> $400F) [S111] Anchor's MP charge (bank $73 arrival commit)
    dw CustomAIRule72                   ; entry 8  ($7208 -> $4011) [S155] AI bonus / veto for custom ids (bank $57 CustomAI57)
    dw CustomTargetPick72               ; entry 9  ($7209 -> $4013) [S155] AI act-time target of a custom id (bank $58 DispatchBoundsStub)
    dw RepelCommit72                    ; entry 10 ($720A -> $4015) [S155] Repel ends when the party leaves its room (bank $73 commit)

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
    jr c, .stock                        ; [S160] a stock id: a reclaimed id's new skill?
    ld c, a                             ; [S111] a NEW custom skill (P3.11d) runs the
    sub $DE                             ;   effect code of a stock skill: CustomBaseTable
    ld e, a                             ;   [id-$DE] = that skill's id ($FF = the
    ld d, $00                           ;   bespoke handlers below). The working id
    ld hl, CustomBaseTable              ;   stays the custom one, so its record (power,
    add hl, de                          ;   targets, MP), name, text, look and element
    ld a, [hl]                          ;   are its own; BC = the base id, as the
    cp $FF                              ;   vanilla path leaves it.
    jr nz, .vanilla
    ld a, c
    cp $E9
    jr z, .mourn                        ; [MOURN S75] defense-calc dispatch path
    call NewDispatch72                  ; [S155] Z: HL = wCustomJump (the S155 skills)
    ret z
    ld hl, $7FED                        ; CustomSkillPtr (bank $52)
    ret
.mourn:
    ld hl, MournDispatchPtr             ; [MOURN S75] -> MournDispatch52 (CalcDefenseWrapper path)
    ret                                 ; (cross-bank label; assembles in one pass via game.asm)
.stock:
    call ReclaimBase72                  ; [S160] A = the base of a reclaimed id's new skill
.vanilla:
    ld c, a
    ld b, $00
    ld hl, $4011
    add hl, bc
    add hl, bc
    ret

; -----------------------------------------------------------------------------
; CustomBattleExec (entry 1) — far-called from $52:CustomDispatch52. Runs the
; per-id handler (CustomBattleRun), then [S111] returns the skill's ELEMENT for
; bank $52 CustomElemTail52: E = the target's resistance level for
; CustomElemTable[id-$DE] ($FF = no element: nothing more happens), HL = the
; target's status byte ($DB05 + 8*slot, what the spell ladder tests).
; -----------------------------------------------------------------------------
CustomBattleExec:
    call CustomBattleRun
    ld e, $FF
    ld a, [$dd6f]                       ; [S155] a handler that applies no damage
    bit 5, a                            ;   (descriptor bit 5 clear: Rust, a Rupture
    jr z, .status                       ;   with nothing to burst, the inert ids) tests no element
    ld a, [$db8a]
    sub $DE
    ld e, a
    ld d, $00
    ld hl, CustomElemTable
    add hl, de
    ld a, [hl]
    ld e, $FF
    cp $FF
    jr z, .status
    call ElemLevelOfA
    ld e, a
.status:
    ld a, [wBattleTargetIdx]
    and $07
    add a
    add a
    add a
    add LOW($db05)
    ld l, a
    ld a, $00
    adc HIGH($db05)
    ld h, a
    ret

; [S111] ElemLevel72 (entry 5) — bank $52 ElemLevel52 asks, for the acting skill,
; which resistance level its damage ladder should use. In: E = the level the
; handler read (its own element). Out: E = that level, or the target's level for
; the skill's override element (StockElemTable / CustomElemTable, $FF = none).
ElemLevel72:
    ld a, [$db8a]
    cp $DE
    jr nc, .custom
    ld hl, StockElemTable
    jr .look
.custom:
    sub $DE
    ld hl, CustomElemTable
.look:
    ld c, a
    ld b, $00
    add hl, bc
    ld a, [hl]
    cp $FF
    ret z                               ; no override: the handler's own element
    call ElemLevelOfA
    ld e, a
    ret

; [S111] ElemLevelOfA — A = a resistance (0-26, gamedata.RESIST_NAMES order) or
; $FE (= none: level 0) -> A = the CURRENT TARGET's level 0-3 for it. The 27
; levels are packed 2 bits each, MSB first, at $DD28 + 7*slot; resistance t
; sits at position t+1 (BATTLE_SKILL_SYSTEM §15.3). Clobbers BC, D, HL.
ElemLevelOfA:
    cp $FE
    jr nz, .elem
    xor a
    ret
.elem:
    inc a                               ; packed position t+1
    ld c, a
    srl a
    srl a
    ld b, a                             ; byte k = position / 4
    ld a, [wBattleTargetIdx]
    and $07
    ld d, a
    add a
    add a
    add a
    sub d                               ; slot * 7
    add b
    add LOW($dd28)                      ; $DD28 + 55 at most: no carry
    ld l, a
    ld h, HIGH($dd28)
    ld b, [hl]                          ; the packed byte
    ld a, c
    and $03                             ; pair p (0 = bits 7:6)
    ld c, a
    ld a, $03
    sub c
    add a                               ; shift right (3-p)*2
    ld c, a
    ld a, b
    jr z, .done
.sh:
    srl a
    dec c
    jr nz, .sh
.done:
    and $03
    ret

; [S111] CustomLearnRow72 (entry 6) — bank $06 LearnLoopFork scans the custom
; ids $DE-$FE (S155; $E0-$FE before) after the vanilla rows: their 18-byte learn rows live here
; (CustomLearnTable, compiler region gd_custom_learn) and are copied one at a
; time into wLearnRowBuf, where the scanner reads them. In: E = the next id to
; try. Out: E = the id whose row is now in wLearnRowBuf, skipping rows with
; level $FF (= not learnable), or E = $FF when none is left.
CustomLearnRow72:
.next:
    ld a, e
    cp $FF
    ret z
    sub $DE                             ; [S155] the table starts at $DE (was $E0)
    ld l, a
    ld h, $00
    ld c, l
    ld b, h
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, bc
    add hl, bc                          ; * 18
    ld bc, CustomLearnTable
    add hl, bc
    ld a, [hl]
    cp $FF
    jr nz, .copy
    inc e
    jr .next
.copy:
    push de
    ld de, wLearnRowBuf
    ld c, 18
.cp:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .cp
    pop de
    ret

; -----------------------------------------------------------------------------
; CustomBattleRun — the per-id handler (CustomBattleExec before S111). Reads the
; real id and tail-jumps to its handler (handler `ret` returns to the caller).
; -----------------------------------------------------------------------------
CustomBattleRun:
    ld a, [$db8a]
    cp ID_LONEWOLF                      ; [S155] the S155 battle skills
    jp z, SkillLoneWolf
    cp ID_PUNISH
    jp z, SkillPunish
    cp ID_FINISH
    jp z, SkillFinish
    cp ID_RUPTURE
    jp z, SkillRupture
    cp ID_RUST
    jp z, SkillRust
    cp ID_PLUNDER                       ; [S156] the buff thief
    jp z, SkillPlunder
    cp ID_REPEL                         ; field-only (the menu refuses it in battle,
    jr z, .inert                        ;   the AI turns it into Attack): no effect if ever run
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
    ; $E4 Anchor is FIELD-ONLY. The player MENU rejects it (FieldOnlySkillA,
    ; S73b) but the tactics/enemy AI commits straight to the queue, and
    ; CustomDispatch52 has already run MegaMagicDamage_653e + the $a8
    ; descriptor by the time we get here — so the S73 "silent no-op" was in
    ; fact a self-inflicted MegaMagic (measured S85: AI-committed Anchor took
    ; 67 HP off the caster's own side). [S85] Make it a true no-op: zero the
    ; damage and clear descriptor bit5 (the apply gate, §15.7) so the apply
    ; step subtracts nothing. The AI still wastes the turn on it (a proper
    ; AI-side exclusion is a ROADMAP item).
    cp $E4
    ret nz
.inert:
    xor a
    ld [$db56], a
    ld [$db57], a
    ld hl, $dd6f
    res 5, [hl]
    ret

; -----------------------------------------------------------------------------
; SkillMagicBurn ($E0) — the per-skill CUSTOM override, far-called from
; CustomDispatch52 AFTER it has run MegaMagicDamage_653e (context + base damage) and
; SetHLBattle_54e7 (descriptor). So the message/target context is already exactly
; MegaMagic's; here we only replace the damage value and charge the real cost:
;   spent = currentMP >> 1                  (floor; = damage dealt to each foe)
;   $db56/57 <- spent                        (OVERRIDES MegaMagicDamage_653e's value)
;   wBattleMP[attacker] -= spent             (record+4=0, so the engine deducts none)
; Damage is RAW (we set the final $db56; the applier uses it directly). ROM0 + RAM only.
; -----------------------------------------------------------------------------
; [S111] the two fractions are project data (CustomRatioTable, gd_custom_ratios):
;   spent  = currentMP * burn            (default 1/2 = the old `>> 1`)
;   damage = spent * damage-per-MP       (default 1/1), at most 999
SkillMagicBurn:
    ld a, [$db88]                       ; wBattleAttackerIdx
    call GetCombatantMP                 ; HL = attacker current MP (value, not ptr)
    ld a, RATIO_MB_BURN
    call RatioBC72
    call ScaleHL72                      ; HL = MP spent
    push hl                             ; save spent (-> DE below)
    ld a, RATIO_MB_DAMAGE
    call RatioBC72
    call ScaleHL72                      ; HL = damage to each foe
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a                       ; OVERRIDE the damage MegaMagicDamage_653e computed
    ; deduct the spent amount from wBattleMP[attacker]
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
; CustomDispatch52 AFTER MegaMagicDamage_653e (context+base dmg) + SetHLBattle_54e7
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
    ld a, [$db8a]                       ; [S111] damage = ATK * the tier's fraction
    sub $E1                             ;   (CustomRatioTable; default 1/4 = the old
    add a                               ;   two `srl` — weaker than a normal hit)
    add RATIO_TAME
    call RatioBC72
    call ScaleHL72                      ; HL = damage
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
; [S111] compiler region gd_tame_meter (gamedata.skills.<225-227>.tame_meter).
TameMeterTable:
; @BUILD_PROJECT BEGIN gd_tame_meter
    dw 10   ; [$E1] Tame
    dw 100  ; [$E2] TameMore
    dw 400  ; [$E3] TameMost
; @BUILD_PROJECT END gd_tame_meter

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
;   (3) $db56/57 := damage (overrides MegaMagicDamage_653e's context value).
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
    ; [S111] allies take the tier's fraction (CustomRatioTable; default 1/3 =
    ; the old subtract loop, floor)
    ld a, [$db8a]
    sub $E5
    add a
    add RATIO_QUAKE_ALLY
    call RatioBC72
    call ScaleHL72
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
; [S111] compiler region gd_quake_power (gamedata.skills.<229-232>.quake_power).
QuakePowerTable:
; @BUILD_PROJECT BEGIN gd_quake_power
    db 40, 20   ; [$E5] Tremor 40-60
    db 90, 30   ; [$E6] Quake 90-120
    db 150, 40   ; [$E7] QuakeMore 150-190
    db 240, 30   ; [$E8] QuakeMost 240-270
; @BUILD_PROJECT END gd_quake_power

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
    call LineSlot72                     ; [S155] a new action: no stale line; [S155 r2]
                                        ;   the bonus line, before the slash
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
    ; [S111] damage += B * (base * per-fallen fraction) — default 1/1 = the old
    ; x (B + 1); the fraction is CustomRatioTable data
    ld a, b
    or a
    ret z                               ; 0 dead: damage stays at 1× (CalcDefenseWrapper result)
    push bc
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a                             ; HL = base damage
    ld a, RATIO_MOURN
    call RatioBC72
    call ScaleHL72                      ; HL = the bonus per fallen ally
    ld d, h
    ld e, l                             ; DE = bonus
    pop bc
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
; context and arms one of the four Anchor dialog scripts — the custom skills'
; OWN scripts, script type $FF, ids 2-5 (editor2/core/skill_scripts.json, bank
; $60 SkillScriptPtrTable, emitted into EVERY build; S105 P3.9b — S73-S104
; armed room $71 = the example project's medal_vault, scripts 2-5, which other
; projects do not have):
;   wInGateworld==1                  -> 2 gate-side confirm ("anchor + warp?")
;   town (wMapID < $30), anchor set  -> 3 return confirm ("spend 3/4 MP?")
;   gate-like room, not a maze floor -> 4 error: can't anchor here
;   town, no anchor stored           -> 5 error: no anchor set
; (skill script ids start at 2: ids 0/1 are a no-op — 0 = "the player" in
; bank $04 CheckPendingNPC's $D8DC test — so the armed values stay the
; S73-measured 2-5 and only the script TYPE changed)
; Arming = the measured ScriptInit-mimic (S73 PyBoy): wScriptMapType=$FF
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
    cp ID_REPEL                         ; [S155] Repel: the field effect is set here
    jp z, RepelField72                  ;   (validated, then applied — see there)
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
    ld a, 3                             ; skill script 3: return confirm
    jr .arm
.gateSide:
    ld a, 2                             ; skill script 2: gate-side confirm
    jr .arm
.errSpecial:
    ld a, 4                             ; skill script 4: can't anchor here
    jr .arm
.errNoAnchor:
    ld a, 5                             ; skill script 5: no anchor set
.arm:
    ld [$d8d4], a                       ; wScriptNPCId (CustomScriptRead index)
    ld [$d8dc], a                       ; NPC number shadow (belt-and-braces)
    ld a, $ff                           ; counter := $FFFF — the per-frame ticker
    ld [$d8d5], a                       ;   (ScriptExecContinue) pre-increments
    ld [$d8d6], a                       ;   BEFORE reading, landing on word[0]
    ld a, $FF
    ld [$d8d3], a                       ; wScriptMapType := $FF (SKILL_SCRIPT_TYPE, bank $60 CustomScriptRead)
    ld a, $01
    ld [$d8d7], a                       ; script active (bit0)
    ld a, [wOPTN_and_Item_selection]    ; caster = the monster whose skill menu
    and $7f                             ;   we are in (party slot 0-2)
    ld [wAnchorCaster], a
    ret                                 ; $da5e stays $E4 -> Anchor07Post closes menu

; =============================================================================
; [S111] AnchorKeepMP72 (entry 7) — bank $73's Anchor arrival commit asks how
; much MP the caster keeps. In: DE = current MP. Out: DE = current MP *
; (1 - the charged fraction) (CustomRatioTable; default charge 3/4 -> keeps
; cur * 1/4, floor = the old `>> 2`). BC clobbered (rst $10 contract).
; =============================================================================
AnchorKeepMP72:
    ld h, d
    ld l, e                             ; HL = current MP
    ld a, RATIO_ANCHOR
    call RatioBC72                      ; B = charged num, C = den
    ld a, c
    sub b
    ld b, a                             ; B = den - num = the kept part
    call ScaleHL72
    ld d, h
    ld e, l
    ret

; [S111] RatioBC72 — A = byte offset into CustomRatioTable -> B = numerator,
; C = denominator. Clobbers A, DE.
RatioBC72:
    ld e, a
    ld d, $00
    push hl
    ld hl, CustomRatioTable
    add hl, de
    ld b, [hl]
    inc hl
    ld c, [hl]
    pop hl
    ret

; [S111] ScaleHL72 — HL := min(999, floor(HL * B / C)), exact for any HL and
; 1 <= C <= 255: with q, r = HL divmod C, HL*B/C = q*B + (r*B)/C (r*B < 65536).
; Clobbers A, BC, DE.
ScaleHL72:
    push bc
    call Div16by8_72                    ; HL = q, A = r (B clobbered)
    pop bc
    push bc
    push af
    ld d, h
    ld e, l                             ; DE = q
    call Mul16by8_72                    ; HL = q * B (saturating)
    pop af
    pop bc
    push hl
    ld e, a
    ld d, $00                           ; DE = r
    call Mul16by8_72                    ; HL = r * B
    call Div16by8_72                    ; HL = r * B / C
    pop de
    add hl, de
    jr c, .cap
    ld a, h
    cp HIGH(1000)
    jr c, .ok
    jr nz, .cap
    ld a, l
    cp LOW(1000)
    jr c, .ok
.cap:
    ld hl, 999
.ok:
    ret

; [S111] Div16by8_72 — HL := HL / C, A := HL mod C (C >= 1). Clobbers B.
Div16by8_72:
    xor a
    ld b, 16
.loop:
    add hl, hl
    rla
    jr c, .sub                          ; 9-bit remainder: certainly >= C
    cp c
    jr c, .next
.sub:
    sub c
    inc l
.next:
    dec b
    jr nz, .loop
    ret

; [S111] Mul16by8_72 — HL := DE * B, saturating at $FFFF. Clobbers A, B, DE.
Mul16by8_72:
    ld hl, $0000
.loop:
    srl b
    jr nc, .noadd
    add hl, de
    jr c, .sat
.noadd:
    ld a, b
    or a
    ret z
    sla e
    rl d
    jr c, .sat                          ; DE * 2 overflowed with bits left in B
    jr .loop
.sat:
    ld hl, $FFFF
    ret

; [S111] CustomRatioTable — the built-in custom skills' fixed RATIOS as project
; data (compiler region gd_custom_ratios, gamedata.skills.<224-233> `burn`,
; `damage_per_mp`, `damage_of_atk`, `mp_charge`, `ally_damage`, `per_fallen`;
; PROJECT_COMPILER §2.27). Two bytes each: numerator, denominator. No edits =
; the S49-S75 constants (results identical, measured).
; (offsets: the RATIO_* constants at the top of this file)
CustomRatioTable:
; @BUILD_PROJECT BEGIN gd_custom_ratios
    db 1, 2     ; [$E0] MagicBurn: spends 1/2 of the current MP
    db 1, 1     ; [$E0] MagicBurn: damage = 1/1 x the MP spent
    db 1, 4     ; [$E1] Tame: damage = 1/4 x ATK
    db 1, 4     ; [$E2] TameMore: damage = 1/4 x ATK
    db 1, 4     ; [$E3] TameMost: damage = 1/4 x ATK
    db 3, 4     ; [$E4] Anchor: charges 3/4 of the current MP on arrival
    db 1, 3     ; [$E5] Tremor: allies take 1/3
    db 1, 3     ; [$E6] Quake: allies take 1/3
    db 1, 3     ; [$E7] QuakeMore: allies take 1/3
    db 1, 3     ; [$E8] QuakeMost: allies take 1/3
    db 1, 1     ; [$E9] Mourn: + 1/1 x the base damage per fallen ally
; @BUILD_PROJECT END gd_custom_ratios

; =============================================================================
; [S155] THE S155 CUSTOM SKILLS — Repel, LoneWolf, Punish, Finish, Rupture, Rust
; ([S156] + Plunder, below: §13.11). BATTLE_SKILL_SYSTEM §13.10; PROJECT_COMPILER §2.63.
; Their numbers are project data: CustomPctTable (gd_custom_pcts, percentages);
; their extra battle lines are bank $4C CustomLinePtrs (gd_custom_lines).
; =============================================================================

; NewDispatch72 — FarSkillFork's choice of the bank-$52 damage machine for the
; S155 battle skills. In: A = the id. Out: Z = one of them: wCustomJump := the
; machine, HL = wCustomJump (the dispatcher's RST_08 reads the address there —
; WRAM, so any bank-$52 address is reachable without a pointer in full bank $52);
; NZ = not one of them (HL clobbered).
;   LoneWolf / Punish / Finish / Rupture -> MournDispatch52 (CalcDefenseWrapper:
;       the ATK-vs-DEF roll in $DB56, then the shared descriptor + handler tail)
;   Rust / Repel / Plunder -> CustomDispatch52_shared (no damage machine: the
;       handler writes everything; the MegaMagic setup would step the RNG;
;       [S156] Plunder's one BattleRNG step is its pick)
NewDispatch72:
    ld hl, MournDispatch52
    cp ID_LONEWOLF
    jr z, .set
    cp ID_PUNISH
    jr z, .set
    cp ID_FINISH
    jr z, .set
    cp ID_RUPTURE
    jr z, .set
    ld hl, CustomDispatch52_shared
    cp ID_RUST
    jr z, .set
    cp ID_REPEL
    jr z, .set
    cp ID_PLUNDER
    ret nz
.set:
    ld a, l
    ld [wCustomJump], a
    ld a, h
    ld [wCustomJump + 1], a
    ld hl, wCustomJump
    xor a                               ; Z
    ret

; LineSlot72 — called by QuakeAnimHold72 (the $da82 animation gate) every time the
; gate is polled. In an action's announce slot (d9ed 1, d9ee 3: the announce has
; printed, the attack animation has not started) its FIRST poll drops any line
; left over from an earlier action (a miss renders the miss message instead of
; $FD, leaving Rust's pending) and runs SlashLine72 (the S155 bonus line, S155
; r2); every poll outside the slot clears wLineShown, so the next action (or the
; next victim of a sweep) decides again. Clobbers all.
LineSlot72:
    ld a, [$d9ed]
    dec a
    jr nz, .out
    ld a, [$d9ee]
    cp $03
    jr nz, .out
    ld a, [wLineShown]
    or a
    ret nz
    inc a
    ld [wLineShown], a
    xor a
    ld [wCustomLine], a
    jp SlashLine72
.out:
    xor a
    ld [wLineShown], a
    ret

; SetLine72 — A = an extra line (LINE_*): the hit message becomes $FD (bank $4C
; LoadB4c_Fork_custom renders the line, the miss message is unchanged). Rust only
; since S155 r2 (its line IS the result: the ATK lost).
SetLine72:
    ld [wCustomLine], a
    ld a, [$db8a]
    ld [wCustomLineSkill], a
    ld a, $FD
    ld [$dd70], a
    ret

; SlashLine72 — [S155 r2] from LineSlot72, once per action (per victim of a
; sweep) in the announce slot, before the attack animation. For LoneWolf /
; Punish / Finish / Rupture whose bonus applies to this target (the SAME tests
; the handler makes later: SideCount72, CountBuffs72, FinishPct72 > 100, an
; ailment), the skill's line is rendered NOW ($FD, wCustomLine): it replaces the
; announce, appears before the slash and stays while it plays (measured: about
; 20 frames before), and the hit itself keeps the game's own
; message — "X takes Y damage pts!" lands with the damage sound and the shake /
; blink, as for every hit (user S155 r2: "'A lone wolf's fury!' should NOT
; coincide with damage sound but precede it … 'It goes in for the kill' … should
; be there WHILE slash is happening"). The line shows even if the hit then misses
; (the miss is rolled after the animation). Clobbers all.
SlashLine72:
    call LineAlways72                   ; [S155 r3] "every time" for this skill?
    jr nz, .show                        ;   A = its line (CustomLineAlways)
    ld a, [$db8a]
    cp ID_LONEWOLF
    jr z, .lonewolf
    cp ID_PUNISH
    jr z, .punish
    cp ID_FINISH
    jr z, .finish
    cp ID_RUPTURE
    ret nz
    ld a, [wBattleTargetIdx]
    call ScoreAilment72
    or a
    ret z
    ld a, LINE_RUPTURE
    jr .show
.lonewolf:
    call GetCaster72
    call SideCount72
    ld a, b
    cp $03
    ret nc
    ld a, LINE_LONEWOLF
    jr .show
.punish:
    ld a, [wBattleTargetIdx]
    call CountBuffs72
    ld a, b
    or a
    ret z
    ld a, LINE_PUNISH
    jr .show
.finish:
    call FinishPct72                    ; HL = P
    ld a, h
    or a
    jr nz, .fin
    ld a, l
    cp 101
    ret c
.fin:
    ld a, LINE_FINISH
.show:
    ld [wCustomLine], a
    ld a, [$db8a]
    ld [wCustomLineSkill], a
    xor a
    ld [$c822], a                       ; mode 0
    ld a, $FD
    ld [$c823], a
    ld hl, $4c00                        ; the battle-message renderer (bank $4C fork:
    rst $10                             ;   wCustomLine -> CustomLinePtrs, then cleared)
    ret

; GetCaster72 — A = the acting combatant = wBattleAttackerIdx ($DB88). MEASURED
; S155 (PyBoy, tools/walk_skills.py): at the handler $DB88 = the caster for a
; one-foe cast AND on every victim of an all-foes sweep (3 victims), while
; $DB77 (the pending-action actor) already reads $FF ("consumed"). (S74 saw
; $DB88 rewritten mid-sweep in Quake's own two-sided sweep fork; an Imitate
; re-cast's attacker is the imitator — the right side to count then.)
GetCaster72:
    ld a, [wBattleAttackerIdx]
    and $07
    ret

; PctOf72 — A = a PCT_* offset -> DE = the percentage (clamped to PCT_MAX).
PctOf72:
    ld e, a
    ld d, $00
    ld hl, CustomPctTable
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ; fall through
ClampPctDE72:                           ; DE := min(DE, PCT_MAX)
    ld a, d
    cp HIGH(PCT_MAX)
    jr c, .ok
    jr nz, .cap
    ld a, e
    cp LOW(PCT_MAX) + 1
    ret c
.cap:
    ld de, PCT_MAX
.ok:
    ret

; DamagePct72 — DE = a percentage: $DB56 := min(999, $DB56 * DE / 100), at least 1
; when $DB56 was not 0.
DamagePct72:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    push hl
    call MulPct72
    call Cap999HL72
    pop de
    ld a, h                             ; a hit that landed keeps at least 1
    or l                                ;   (Finish x0.2 on 1-4 damage): 0 only
    jr nz, .store                       ;   when the roll itself was 0
    ld a, d
    or e
    jr z, .store
    inc l
.store:
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret

; MulPct72 — HL := floor(HL * DE / 100), exact while HL * DE / 100 < 60000
; (damage 0-999 x a percentage 0-2000; Finish's span 0-2000 x 0-100). With
; HL = 100a + b, DE = 100q + r: a*q*100 + a*r + b*q + floor(b*r / 100).
; Clobbers A, BC, DE; wCustomTmp = b, a, r, q.
MulPct72:
    push de
    ld c, 100
    call Div16by8_72                    ; HL = a, A = b
    ld [wCustomTmp], a
    ld a, l
    ld [wCustomTmp + 1], a
    pop hl
    ld c, 100
    call Div16by8_72                    ; HL = q, A = r
    ld [wCustomTmp + 2], a
    ld a, l
    ld [wCustomTmp + 3], a
    ld a, [wCustomTmp + 1]              ; a * q * 100
    ld e, a
    ld d, $00
    ld a, [wCustomTmp + 3]
    ld b, a
    call Mul16by8_72
    ld d, h
    ld e, l
    ld b, 100
    call Mul16by8_72
    push hl
    ld a, [wCustomTmp + 1]              ; + a * r
    ld e, a
    ld d, $00
    ld a, [wCustomTmp + 2]
    ld b, a
    call Mul16by8_72
    pop de
    add hl, de
    push hl
    ld a, [wCustomTmp]                  ; + b * q
    ld e, a
    ld d, $00
    ld a, [wCustomTmp + 3]
    ld b, a
    call Mul16by8_72
    pop de
    add hl, de
    push hl
    ld a, [wCustomTmp]                  ; + b * r / 100
    ld e, a
    ld d, $00
    ld a, [wCustomTmp + 2]
    ld b, a
    call Mul16by8_72
    ld c, 100
    call Div16by8_72
    pop de
    add hl, de
    ret

; Cap999HL72 — HL := min(HL, 999). Clobbers A.
Cap999HL72:
    ld a, h
    cp HIGH(1000)
    ret c
    jr nz, .cap
    ld a, l
    cp LOW(1000)
    ret c
.cap:
    ld hl, 999
    ret

; SlotPtr72 — A = combatant slot, HL = a battle word array -> HL = &array[slot].
SlotPtr72:
    and $07
    add a
    add l
    ld l, a
    ret nc
    inc h
    ret

; BlockPtr72 — A = slot -> HL = $DB00 + 8 * slot (the slot's status block: +2
; ailments, +3 … +7; +8 / +9 = the next block's +0 / +1 = this slot's shifted
; pair, $DB40 / $DB41 for slot 7 — BATTLE_SKILL_SYSTEM §15.8 / §15.11.F6).
BlockPtr72:
    and $07
    add a
    add a
    add a
    ld l, a
    ld h, HIGH($db00)
    ret

; -----------------------------------------------------------------------------
; LoneWolf ($DF) — the ATK-vs-DEF roll (CalcDefenseWrapper) x PCT_LW_ALONE when
; the caster's side has ONE monster, x PCT_LW_DUO with two, x1 with three. A
; monster counts while it is in the battle at all ($DD1B != $FF: alive or
; fallen — user S155 "dead count as party"); the helper slot (3 / 7: CallHelp,
; the summons) is not counted. Its line LINE_LONEWOLF (fewer than three) is shown as
; the slash starts (SlashLine72, S155 r2).
; -----------------------------------------------------------------------------
SkillLoneWolf:
    call GetCaster72
    call SideCount72                    ; B = monsters on the caster's side
    ld a, b
    cp $02
    jr z, .duo
    ret nc                              ; three: x1
    ld a, PCT_LW_ALONE
    jr .apply
.duo:
    ld a, PCT_LW_DUO
.apply:
    call PctOf72
    jp DamagePct72                      ; [S155 r2] the line came before (SlashLine72)

; SideCount72 — A = a slot -> B = slots 0-2 of its side with $DD1B != $FF.
SideCount72:
    and $04
    add LOW($dd1b)
    ld l, a
    ld h, HIGH($dd1b)
    ld b, $00
    ld c, $03
.lp:
    ld a, [hl+]
    inc a
    jr z, .no
    inc b
.no:
    dec c
    jr nz, .lp
    ret

; -----------------------------------------------------------------------------
; Punish ($EB) — the ATK-vs-DEF roll x (100 + n x PCT_PUNISH) %, n = the buffs
; on the target (CountBuffs72, BuffTable). Its line LINE_PUNISH (n > 0) is shown as the
; slash starts (SlashLine72, S155 r2).
; -----------------------------------------------------------------------------
SkillPunish:
    ld a, [wBattleTargetIdx]
    call CountBuffs72                   ; B = n
    ld a, b
    or a
    ret z
    push bc
    ld a, PCT_PUNISH
    call PctOf72                        ; DE = the share per buff
    pop bc
    ld hl, 100
.add:
    add hl, de
    dec b
    jr nz, .add
    ld d, h
    ld e, l
    call ClampPctDE72
    jp DamagePct72                      ; [S155 r2] the line came before (SlashLine72)

; CountBuffs72 — A = a slot -> B = how many of the BuffTable states it has.
CountBuffs72:
    call BlockPtr72
    ld e, l
    ld d, h                             ; DE = the slot's block
    ld hl, BuffTable
    ld b, $00
    ld c, BUFF_COUNT
.lp:
    ld a, [hl+]                         ; the byte's offset in the block
    push hl
    add e
    ld l, a
    ld h, d
    ld a, [hl]
    pop hl
    and [hl]                            ; its mask
    inc hl
    jr z, .no
    inc b
.no:
    dec c
    jr nz, .lp
    ret

; BuffTable — what counts as a BUFF (user S155: "any positive buff counts …
; exclude iron and transform"): the game's own DeMagic "has a buff" test
; (AIRuleDeMagicVetoNoBuff_6bcb: +3 & $3C, +4 & $6F, +5 & $40, +7 & $CC,
; +8 & $40) without iron (+7 & $C0) and the transformed bits (+3 & $30), plus
; the one-round stances DeMagic does not test. One entry = one buff:
;   [offset in the slot's block, mask]   (BATTLE_SKILL_SYSTEM §15.11.F4/F6/F7)
BuffTable:
    db 3, $04                           ; TwinHits armed
    db 3, $08                           ; ALLCHANGE (sure crits)
    db 4, $01                           ; TakeMagic
    db 4, $02                           ; Bounce
    db 4, $04                           ; Barrier
    db 4, $20                           ; MagicBack
    db 4, $40                           ; TailWind / StormWind
    db 5, $40                           ; MagicWall
    db 6, $03                           ; ChargeUP
    db 6, $30                           ; SuckAir
    db 6, $C0                           ; Focus
    db 7, $0C                           ; SideStep
    db 8, $40                           ; a stat RAISED (Upper / Increase / Speed / SpeedUp)
    db 8, $20                           ; Dodge
    db 8, $08                           ; Imitate
    db 8, $02                           ; SuckAll
    db 9, $07                           ; Defence / StrongD / BladeD stance
DEF BUFF_COUNT EQU (@ - BuffTable) / 2

; -----------------------------------------------------------------------------
; Finish ($EC) — the ATK-vs-DEF roll x P %, P = low + (high - low) x the share
; of the target's HP that is missing (PCT_FIN_LOW at full HP, PCT_FIN_HIGH near
; 0; high < low works the other way). The share is in whole percent of the
; target's MaxHP (both shifted below 256 first). Its line (LINE_FINISH, when
; P > 100) is shown as the slash starts (SlashLine72, S155 r2).
; -----------------------------------------------------------------------------
SkillFinish:
    call FinishPct72
    ld d, h
    ld e, l
    jp DamagePct72

; LineAlways72 — [S155 r3] NZ + A = the acting skill's line when the project shows
; it EVERY time (CustomLineAlways bit: 0 LoneWolf, 1 Punish, 2 Finish, 3 Rupture —
; `line_shows: "always"`, the default since S155 r3: the user, "I would prefer it
; displayed the text regardless of whether threshold is reached or not - so the
; user can see what the skill is trying to do"); Z = test the bonus as before.
LineAlways72:
    ld a, [$db8a]
    ld b, LINE_LONEWOLF
    ld c, $01
    cp ID_LONEWOLF
    jr z, .test
    inc b
    sla c
    cp ID_PUNISH
    jr z, .test
    inc b
    sla c
    cp ID_FINISH
    jr z, .test
    inc b
    sla c
    cp ID_RUPTURE
    jr z, .test
    xor a                               ; Z: not one of the four
    ret
.test:
    ld a, [CustomLineAlways]
    and c
    ret z
    ld a, b
    or a                                ; NZ
    ret

; FinishPct72 — HL = Finish's P (%) for the target wBattleTargetIdx. Clobbers all.
FinishPct72:
    ld a, [wBattleTargetIdx]
    call MissingShare72                 ; HL = the share of its HP it has lost (%)
.share:
    push hl                             ; the share
    ld a, PCT_FIN_HIGH
    call PctOf72
    push de                             ; high
    ld a, PCT_FIN_LOW
    call PctOf72                        ; DE = low
    pop hl                              ; HL = high
    ld a, l                             ; HL = high - low
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    jr c, .down
    push de                             ; low
    pop bc
    pop de                              ; DE = the share
    push bc
    call MulPct72                       ; HL = (high - low) * share / 100
    pop de
    add hl, de                          ; + low
    ret
.down:
    ld a, l                             ; HL = low - high
    cpl
    ld l, a
    ld a, h
    cpl
    ld h, a
    inc hl
    push de                             ; low
    pop bc
    pop de                              ; DE = the share
    push bc
    call MulPct72                       ; HL = (low - high) * share / 100
    pop de
    ld a, e                             ; low - that
    sub l
    ld l, a
    ld a, d
    sbc h
    ld h, a
.apply:
    ret

; -----------------------------------------------------------------------------
; Rupture ($ED) — the target's AILMENTS burst: when it has any of +2 (poison,
; the heavy poison, sleep, confusion, curse, paralysis — every bit) or +3 & $C3
; (StopSpell, Surround, DanceShut, MouthShut), they are all cleared and the
; ATK-vs-DEF roll x PCT_RUPTURE hits (its line LINE_RUPTURE was shown as the slash
; started, SlashLine72, S155 r2); without one the
; skill fails: "But nothing happens!" ($BB, descriptor $84 — Sap's failure
; shape; the MP is spent). (User S155: "any debuff counts … consume all … fail
; with mp spent.")
; -----------------------------------------------------------------------------
SkillRupture:
    ld a, [wBattleTargetIdx]
    call BlockPtr72
    inc hl
    inc hl                              ; +2
    ld b, [hl]
    inc hl                              ; +3
    ld a, [hl]
    and $C3
    or b
    jp z, RustFail72
    ld a, [hl]
    and $3C
    ld [hl-], a                         ; +3: only the twin-hit / ALLCHANGE / form bits stay
    ld [hl], $00                        ; +2: every ailment gone
    ld a, PCT_RUPTURE
    call PctOf72
    jp DamagePct72                      ; [S155 r2] the line came before (SlashLine72)

; -----------------------------------------------------------------------------
; Rust ($EE) — lowers the target's ATK, the way Sap lowers DEF (bank $52
; SkillSap: SapHitRoll_5dcc then StatDefDown_5dfc; BATTLE_SKILL_SYSTEM
; §15.11.F7): the same roll — resistance 12 (DefDown, user S155 "fold under
; DefDown"), $DB42 bit 2 = sure, else ladder B (RustRoll72); a miss -> "Has no
; effect" ($B8, descriptor $80); ATK <= 1 or [S155 r5] already blunted
; (wBlunted bit: Blunt does NOT stack — the user: "MadKnight cast blunt like 6
; times in a row … Blunt should NOT stack") -> "But nothing happens!" ($BB,
; $84; MP spent); else ATK -= base ATK x PCT_RUST % (at least 1), ATK never below 1
; (user S155: "floor 1"; Sap's DEF floor is 0); $DB56 = the ATK lost (the
; line's number); the slot's "lowered" mark (+8 bit 7: Surge / DeMagic put it
; back — bank $53 RustRestoreATK53); descriptor $98 (no HP damage) with hit
; message $FD = LINE_RUST.
; -----------------------------------------------------------------------------
SkillRust:
    xor a
    ld [$db56], a
    ld [$db57], a
    ld a, [wBattleTargetIdx]            ; [S155 r5] already blunted: fails
    call BluntBit72
    jp nz, RustFail72
    call RustRoll72
    jr c, .lands
    ld a, $b8                           ; resisted: Sap's miss shape
    ld [$dd70], a
    ld [$dd71], a
    ld a, $80
    ld [$dd6f], a
    ret
.lands:
    ld a, [wBattleTargetIdx]
    ld hl, wBattleATK
    call SlotPtr72
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = ATK
    ld a, h
    or a
    jr nz, .some
    ld a, l
    cp $02
    jr c, .failPop                      ; ATK 0 / 1: nothing to lower
.some:
    push hl                             ; ATK
    ld a, [wBattleTargetIdx]
    and $07
    ld [$dd72], a
    ld hl, $5706                        ; bank $57 entry 6 = the base ATK of slot [$dd72]
    rst $10                             ;   (party record +$58 / the enemy row)
    ld a, [$dd72]
    ld l, a
    ld a, [$dd73]
    ld h, a
    ld a, PCT_RUST
    push hl
    call PctOf72
    pop hl
    call MulPct72                       ; HL = the amount
    ld a, h
    or l
    jr nz, .amt
    inc l                               ; at least 1
.amt:
    ld d, h
    ld e, l                             ; DE = amount
    pop hl                              ; HL = ATK (>= 2)
    ld a, l                             ; new = ATK - amount, at least 1
    sub e
    ld c, a
    ld a, h
    sbc d
    ld b, a                             ; BC = new
    jr c, .floor
    or c
    jr nz, .ok
.floor:
    ld bc, $0001
.ok:
    ld a, l                             ; the ATK lost = ATK - new
    sub c
    ld [$db56], a
    ld a, h
    sbc b
    ld [$db57], a
    pop hl                              ; &ATK
    ld a, c
    ld [hl+], a
    ld [hl], b
    ld a, [wBattleTargetIdx]
    call BlockPtr72
    ld a, l
    add 8
    ld l, a
    set 7, [hl]                         ; +8 bit 7: a stat LOWERED
    ld a, [wBattleTargetIdx]            ; [S155 r5] the slot is blunted
    call BluntBit72
    ld a, [hl]
    or b
    ld [hl], a
    ld a, $98                           ; Sap's success descriptor (no HP damage)
    ld [$dd6f], a
    ld a, $b8
    ld [$dd71], a
    ld a, LINE_RUST
    jp SetLine72
.failPop:
    pop hl
RustFail72:                             ; "But nothing happens!" (no HP damage)
    xor a
    ld [$db56], a
    ld [$db57], a
    ld a, $bb
    ld [$dd70], a
    ld [$dd71], a
    ld a, $84
    ld [$dd6f], a
    ret

; BluntBit72 — [S155 r5] A = a slot -> B = its wBlunted bit, HL = wBlunted,
; A = [wBlunted] & B (NZ = blunted). Clobbers C.
BluntBit72:
    and $07
    inc a
    ld c, a
    ld b, $80
.sh:
    rlc b
    dec c
    jr nz, .sh
    ld hl, wBlunted
    ld a, [hl]
    and b
    ret

; RustRoll72 — carry = the ATK-down lands. A port of bank $52 SapHitRoll_5dcc
; with the ladder CheckTargetGuardB (bank $52 is not callable from here): the
; target's resistance 12 level ($DD2B + 7t bits 5:4) -> $DB4E; $DB5A/$DB5B := 0
; (as the original); level 3 -> never (no RNG); the attacker's $DB42 bit 2 ->
; sure (no RNG); else by the target's +5 byte: bit 6 (MagicWall's guard row)
; [always, $BF, $66, never], bit 7 [always, always, $BF, never], else
; [always, $D8, $7F, never] — one BattleRNG step, hit iff wRNG1 < the value.
RustRoll72:
    xor a
    ld [$db5a], a
    ld [$db5b], a
    ld a, [wBattleTargetIdx]
    and $07
    ld b, a
    add a
    add b
    add a
    add b                               ; 7t
    add LOW($dd2b)
    ld l, a
    ld a, $00
    adc HIGH($dd2b)
    ld h, a
    ld a, [hl]
    swap a
    and $03
    ld [$db4e], a
    cp $03
    jr z, .never
    ld c, a                             ; C = level 0-2
    ld a, [wBattleAttackerIdx]
    and $07
    add LOW($db42)
    ld l, a
    ld h, HIGH($db42)
    bit 2, [hl]
    jr nz, .sure
    ld a, [wBattleTargetIdx]
    call BlockPtr72
    ld a, l
    add 5
    ld l, a
    ld a, [hl]                          ; +5
    ld hl, RustLadderPlain
    bit 6, a
    jr z, .nog
    ld hl, RustLadderGuard
    jr .pick
.nog:
    bit 7, a
    jr z, .pick
    ld hl, RustLadderAmp
.pick:
    ld b, $00
    add hl, bc
    ld a, [hl]
    or a
    jr z, .sure                         ; 0 = always, no RNG
    inc a
    jr z, .never                        ; $FF = never
    dec a
    push af
    call BattleRNG72
    pop af
    ld b, a
    ld a, [wRNG1]
    cp b                                ; carry iff wRNG1 < the value
    ret
.sure:
    scf
    ret
.never:
    and a                               ; carry clear
    ret
RustLadderPlain:
    db $00, $D8, $7F                    ; BattleFunc_67ec (level 3 never: handled above)
RustLadderGuard:
    db $00, $BF, $66                    ; BattleFunc_680f
RustLadderAmp:
    db $00, $00, $BF                    ; Compare_6802 (levels 0 / 1 always)

; BattleRNG72 — bank $52 BattleRNG: the link battle's private RNG ($C1ED/$C1EE)
; or GenerateRNG.
BattleRNG72:
    ld a, [$c86c]
    or a
    jp z, GenerateRNG
    push hl
    ld a, [$c1ed]
    ld [wRNG1], a
    ld a, [$c1ee]
    ld [wRNG2], a
    call GenerateRNG
    ld a, [wRNG1]
    ld [$c1ed], a
    ld a, [wRNG2]
    ld [$c1ee], a
    pop hl
    ret

; -----------------------------------------------------------------------------
; [S156] Plunder ($EA) — steals ONE buff of the target and puts it on the
; caster "as if you cast it that round on yourself" (the user, S155 / S156:
; "Requires enemy to have a buff. Requires to select enemy … Steal 1 at random
; … Exclude iron"; "fresh"; "only caster"; "always lands"). BATTLE_SKILL_SYSTEM
; §13.11. One foe; no roll (record flags 7 / 8 = 0, DeMagic's shape: never
; misses, never reflected, Covered or dodged; an iron target can be robbed —
; iron itself is never taken).
;   * The buffs = StealTable (18 rows: BuffTable's 17 with "a stat raised"
;     split into DEF and AGL; never iron +7 & $C0 or the transformed bits).
;   * The pick: ONE BattleRNG step, row = the k-th eligible one, k =
;     (wRNG1 x n) >> 8 — among the target's buffs the caster LACKS (for DEF /
;     AGL: the caster's stat can still rise), else among all of them (the
;     target loses it, the caster gains nothing new). None -> "But nothing
;     happens!" ($BB, descriptor $84; the MP is spent — the user: "1) Yes").
;   * The move (StealApply72): the target's bits cleared; the caster's byte
;     := (byte & ~clear) | value — the persistent bits as they are, Bounce /
;     MagicBack replacing each other, ChargeUP / SuckAir / Focus FRESH ($03 /
;     $30 / $80: they power the caster's next round), SideStep and the
;     Defence / StrongD / BladeD level copied, Dodge / Imitate / SuckAll for
;     the rest of this round. A side-wide buff moves only the target's copy,
;     only to the caster. SuckAll also moves its side mark (side byte bit 6,
;     $DB4A + side), not when the caster's side already has one (SkillSuckAll).
;     DEF / AGL raised: the target's stat back to its base (bank $57 entries 7
;     / 8), its raised mark (+8 bit 6) kept only while the other stat is still
;     above base; the caster gets ONE Upper / Speed on itself (+ its base / 2,
;     999 / 511 and the x4 party / x2 enemy cap — StatDefUp_5e3e /
;     StatAglUp_5f08 — the mark set) (the user, S155: "the foe drops back to
;     base and you get one Upper's worth on yourself, within the usual caps").
;   * [S156 r2] a raised DEF / AGL that rose on the caster: LINE_PLUNDER_DEF /
;     _AGL = the same line + a page "{name}'s defense / speed goes up by
;     {amount}!" ($DB56 = the rise, [INS 10]) — the user: "the next textbox should
;     report by how much the effect affects new monster. Same with enemies".
;   * The line LINE_PLUNDER replaces the hit message ($FD, Rust's shape): the
;     game fills [INS 00] = the target, [INS 20] = the caster (measured S156 at
;     the $FD render: $C180 / $C1A0); the handler puts the buff's name in
;     [INS 30] ($C1B0, unused in battle — measured): the name of the stock
;     skill that gives it (StealTable's last byte; the stance by its level), so
;     a renamed stock skill shows its new name.
; -----------------------------------------------------------------------------
DEF STEAL_BIT     EQU 0                 ; a bit field (offset, mask, clear, value)
DEF STEAL_DEF     EQU 1                 ; DEF raised (wBattleDEF over the base)
DEF STEAL_AGL     EQU 2                 ; AGL raised (wBattleAGL over the base)
DEF STEAL_SUCKALL EQU 3                 ; SuckAll (+ its side mark)
DEF STEAL_STANCE  EQU 4                 ; Defence / StrongD / BladeD (+9 level, named by it)
DEF STEAL_ROW     EQU 6                 ; bytes per StealTable row
DEF STEAL_ROW_DEF EQU 12                ; [S156 r2] the DEF-raised row (AGL = the next; ASSERTed)

SkillPlunder:
    xor a
    ld [$db56], a
    ld [$db57], a
    ld a, [wBattleAttackerIdx]
    and $07
    ld [wSteal], a                      ; +0 the caster
    ld b, a
    ld a, [wBattleTargetIdx]
    and $07
    ld [wSteal + 1], a                  ; +1 the target
    cp b
    jp z, RustFail72                    ; (never from itself)
    ld a, $01                           ; first the buffs the caster lacks
    ld [wSteal + 2], a
    call StealCount72                   ; B = n
    ld a, b
    or a
    jr nz, .pick
    xor a                               ; it has them all: any of the target's
    ld [wSteal + 2], a
    call StealCount72
    ld a, b
    or a
    jp z, RustFail72                    ; no buff: "But nothing happens!" (MP spent)
.pick:
    push bc
    call BattleRNG72
    pop bc
    ld a, [wRNG1]
    ld e, a
    ld d, $00
    call Mul16by8_72                    ; HL = RNG1 x n (B = n; < 256 x 18)
    ld a, h                             ; k = (RNG1 x n) >> 8 = 0 .. n-1
    ld [wSteal + 3], a
    call StealFind72                    ; [wSteal+4] = the row
    call StealApply72
    ld a, $98                           ; Rust's success shape (no HP damage)
    ld [$dd6f], a
    ld a, $b8
    ld [$dd71], a
    ld b, LINE_PLUNDER                  ; [S156 r2] a raised DEF / AGL that rose on the
    ld a, [$db56]                       ;   caster: the line + a page with the amount
    ld c, a                             ;   ($DB56 = the rise -> [INS 10]; the user: "the
    ld a, [$db57]                       ;   next textbox should report by how much the
    or c                                ;   effect affects new monster. Same with enemies")
    jr z, .line
    ld a, [wSteal + 4]
    sub STEAL_ROW_DEF
    jr c, .line
    cp $02
    jr nc, .line
    add LINE_PLUNDER_DEF
    ld b, a
.line:
    ld a, b
    jp SetLine72

; StealCount72 — B = the eligible StealTable rows (StealOK72). Clobbers all.
StealCount72:
    ld bc, $0000                        ; B = count, C = row
.lp:
    push bc
    ld a, c
    call StealOK72
    pop bc
    jr z, .no
    inc b
.no:
    inc c
    ld a, c
    cp STEAL_COUNT
    jr c, .lp
    ret

; StealFind72 — [wSteal+4] := the [wSteal+3]-th eligible row (0-based; k < n).
StealFind72:
    ld c, $00
.lp:
    push bc
    ld a, c
    call StealOK72                      ; (writes [wSteal+4] = C)
    pop bc
    jr z, .no
    ld a, [wSteal + 3]
    or a
    ret z                               ; this one
    dec a
    ld [wSteal + 3], a
.no:
    inc c
    ld a, c
    cp STEAL_COUNT
    jr c, .lp
    ret                                 ; (unreachable while k < n)

; StealOK72 — A = a row ([wSteal+4] := A): NZ = the target ([wSteal+1]) has its
; buff and, in mode 1 ([wSteal+2]), the caster ([wSteal]) does not / can rise.
StealOK72:
    ld [wSteal + 4], a
    ld a, [wSteal + 1]
    call StealHas72
    ret z
    ld a, [wSteal + 2]
    or a
    jr z, .yes
    ld a, [wSteal]
    call StealCasterHas72
    jr nz, .no
.yes:
    or $01                              ; NZ
    ret
.no:
    xor a
    ret

; StealRowPtr72 — HL = StealTable row [wSteal+4]. Clobbers A, DE.
StealRowPtr72:
    ld a, [wSteal + 4]
    ld e, a
    add a
    add e
    add a                               ; 6 x row
    ld e, a
    ld d, $00
    ld hl, StealTable
    add hl, de
    ret

; StealByte72 — A = a slot, D = an offset in its block -> HL = the byte.
StealByte72:
    call BlockPtr72
    ld a, l
    add d                               ; $DB00 + 8 x 7 + 9 at most: no carry
    ld l, a
    ret

; StealHas72 — A = a slot: NZ = it HAS the buff of row [wSteal+4]: its bits;
; DEF / AGL: the raised mark (+8 bit 6), not transformed (+3 & $30), and the
; stat above its base. Clobbers all.
StealHas72:
    ld c, a
    call StealRowPtr72
    ld a, [hl+]
    ld d, a                             ; offset
    ld e, [hl]                          ; mask
    inc hl
    inc hl
    inc hl
    ld a, [hl]                          ; kind
    cp STEAL_DEF
    jr z, .stat
    cp STEAL_AGL
    jr z, .stat
    ld a, c
    call StealByte72
    ld a, [hl]
    and e
    ret
.stat:
    ld e, a                             ; E = the kind
    ld a, c
    call BlockPtr72
    inc hl
    inc hl
    inc hl
    ld a, [hl]                          ; +3
    and $30
    jr nz, .not                         ; transformed: its stats are copies
    ld a, l
    add 5
    ld l, a                             ; +8
    bit 6, [hl]
    jr z, .not
    ld a, c
    jp StatAboveBase72
.not:
    xor a
    ret

; StealCasterHas72 — A = the caster: NZ = it already has row [wSteal+4]'s
; buff (DEF / AGL: its stat cannot rise any more; SuckAll: its side already has
; a SuckAll user). Clobbers all.
StealCasterHas72:
    ld c, a
    call StealRowPtr72
    ld a, [hl+]
    ld d, a                             ; offset
    ld e, [hl]                          ; mask
    inc hl
    inc hl
    inc hl
    ld a, [hl]                          ; kind
    cp STEAL_DEF
    jr z, .stat
    cp STEAL_AGL
    jr z, .stat
    cp STEAL_SUCKALL
    jr z, .suck
    ld a, c
    call StealByte72
    ld a, [hl]
    and e
    ret
.suck:
    ld a, c
    call SideByte72
    ld a, [hl]
    and $40
    ret
.stat:
    ld e, a
    ld a, c
    call StatLoad72
    call StatRoom72                     ; carry = it can rise
    ld a, $00
    jr c, .ok
    inc a
.ok:
    or a
    ret

; SideByte72 — A = a slot -> HL = its side byte ($DB00 party / $DB01 enemy),
; A = the side (0 / 1).
SideByte72:
    and $04
    rrca
    rrca
    ld l, a
    ld h, HIGH($db00)
    ret

; StealApply72 — moves row [wSteal+4]'s buff from the target to the caster and
; puts its name in [INS 30] ($C1B0). Clobbers all.
StealApply72:
    call StealRowPtr72
    ld a, [hl+]
    ld d, a                             ; D = offset
    ld a, [hl+]
    ld e, a                             ; E = mask
    ld a, [hl+]
    ld b, a                             ; B = the caster's bits to clear
    ld a, [hl+]
    ld c, a                             ; C = the value ($FF = the target's bits)
    ld a, [hl+]                         ; kind
    push af
    ld a, [hl]
    ld [wSteal + 5], a                  ; the name's skill id
    pop af
    cp STEAL_DEF
    jp z, .stat
    cp STEAL_AGL
    jp z, .stat
    cp STEAL_SUCKALL
    jp z, .suck
    push af                             ; kind (bits / stance)
    push bc
    ld a, [wSteal + 1]
    call StealByte72
    pop bc
    ld a, [hl]
    and e
    push af                             ; the target's bits
    ld a, e
    cpl
    and [hl]
    ld [hl], a                          ; the target loses them
    push bc
    ld a, [wSteal]
    call StealByte72
    pop bc
    pop af
    ld d, a                             ; D = the target's bits
    ld a, c
    inc a
    jr nz, .val
    ld c, d                             ; $FF: copied as they were
.val:
    ld a, b
    cpl
    and [hl]
    or c
    ld [hl], a                          ; the caster gains them
    pop af                              ; kind
    cp STEAL_STANCE
    jr nz, .name
    ld a, d                             ; the stance by its level
    ld b, $8E                           ; 2: StrongD
    cp $02
    jr z, .lvl
    ld b, $90                           ; 4: BladeD
    cp $04
    jr z, .lvl
    ld b, $8D                           ; 1: Defence
.lvl:
    ld a, b
    ld [wSteal + 5], a
    jr .name
.suck:                                  ; the target: +8 bit 1 and its side's mark
    ld a, [wSteal + 1]
    call BlockPtr72
    ld a, l
    add 8
    ld l, a
    res 1, [hl]
    ld a, [wSteal + 1]
    call SideByte72
    res 6, [hl]
    add LOW($db4a)
    ld l, a
    ld a, [hl]
    and $03
    ld [hl], a
    ld a, [wSteal]                      ; the caster: as SkillSuckAll (its side's
    call SideByte72                     ;   mark set already: nothing)
    bit 6, [hl]
    jr nz, .name
    set 6, [hl]
    add LOW($db4a)
    ld l, a
    ld a, [wSteal]
    and $03
    add a
    add a
    or [hl]
    ld [hl], a
    ld a, [wSteal]
    call BlockPtr72
    ld a, l
    add 8
    ld l, a
    set 1, [hl]
    jr .name
.stat:                                  ; A = STEAL_DEF / STEAL_AGL
    ld e, a
    push de
    ld a, [wSteal + 1]
    call StatToBase72                   ; the target's stat back to its base
    pop de
    push de
    ld a, [wSteal]
    call StatRise72                     ; one Upper / Speed on the caster
    pop de
    ld a, e
    xor STEAL_DEF ^ STEAL_AGL           ; the other stat
    ld e, a
    ld a, [wSteal + 1]
    call StatAboveBase72
    jr nz, .name                        ; still raised: the mark stays
    ld a, [wSteal + 1]
    call BlockPtr72
    ld a, l
    add 8
    ld l, a
    res 6, [hl]
.name:
    ld a, [wSteal + 5]
    ; fall through
; StealName72 — A = a stock skill id: its name (bank $41 mode 6, the game's own
; copy — SetupVRAMParams = bank $41 entry 1) into [INS 30] ($C1B0, $F0-ended).
StealName72:
    ld l, a
    ld h, $06
    ld de, $c1b0
    jp SetupVRAMParams

; ---- the stats (wCustomTmp: +0 slot, +1 kind, +2/+3 the base) ----------------
; StatInfo72 — E = STEAL_DEF / STEAL_AGL -> HL = its battle array, D = the bank
; $57 base entry (7 DEF / 8 AGL).
StatInfo72:
    ld hl, wBattleDEF
    ld d, $07
    ld a, e
    cp STEAL_DEF
    ret z
    ld hl, wBattleAGL
    ld d, $08
    ret

; BaseStat72 — A = a slot, E = a bank $57 entry (6 ATK / 7 DEF / 8 AGL) -> HL =
; its BASE (the party record / the enemy row, BATTLE_SKILL_SYSTEM §15.11.F7).
; $DD72 / $DD73 are kept (the AI's plan byte shares them: ScoreSteal72 runs in
; the AI's rule walk). Clobbers all else.
BaseStat72:
    and $07
    ld b, a
    ld a, [$dd72]
    ld c, a
    ld a, [$dd73]
    push af
    push bc
    ld a, b
    ld [$dd72], a
    ld l, e
    ld h, $57
    rst $10
    pop bc
    ld a, [$dd72]
    ld l, a
    ld a, [$dd73]
    ld h, a
    pop af
    ld [$dd73], a
    ld a, c
    ld [$dd72], a
    ret

; StatLoad72 — A = a slot, E = the kind -> wCustomTmp (+0 slot, +1 kind, +2/+3
; base); HL = &its stat, DE = the stat. Clobbers all.
StatLoad72:
    ld [wCustomTmp], a
    ld a, e
    ld [wCustomTmp + 1], a
    call StatInfo72
    ld e, d
    ld a, [wCustomTmp]
    call BaseStat72
    ld a, l
    ld [wCustomTmp + 2], a
    ld a, h
    ld [wCustomTmp + 3], a
    ld a, [wCustomTmp + 1]
    ld e, a
    call StatInfo72
    ld a, [wCustomTmp]
    call SlotPtr72
    ld e, [hl]
    inc hl
    ld d, [hl]
    dec hl
    ret

; StatRoom72 — after StatLoad72, DE = a value of the stat: carry = it is below
; the limit (999 DEF / 511 AGL) and below the cap (base x4 for a slot < 4 or a
; link battle, x2 for an enemy — UpperStatCapCheck_6a13 / StatCapMul_6af5);
; BC = the bound it met (the limit when at / over it, else the cap). Keeps DE,
; HL.
StatRoom72:
    push hl
    ld a, [wCustomTmp + 1]
    ld bc, 999
    cp STEAL_DEF
    jr z, .lim
    ld bc, 511
.lim:
    ld a, e
    sub c
    ld a, d
    sbc b
    jr nc, .no                          ; at / over the limit
    ld a, [wCustomTmp + 2]
    ld l, a
    ld a, [wCustomTmp + 3]
    ld h, a
    add hl, hl                          ; x2
    ld a, [$c86c]
    or a
    jr nz, .x4
    ld a, [wCustomTmp]
    cp $04
    jr nc, .cap
.x4:
    add hl, hl                          ; x4
.cap:
    ld b, h
    ld c, l
    ld a, e                             ; carry = DE < cap
    sub c
    ld a, d
    sbc b
    pop hl
    ret
.no:
    and a
    pop hl
    ret

; StatAboveBase72 — A = a slot, E = the kind: NZ = the stat is above its base.
StatAboveBase72:
    call StatLoad72                     ; DE = the stat
    ld a, [wCustomTmp + 2]              ; base - stat: a borrow = above
    sub e
    ld a, [wCustomTmp + 3]
    sbc d
    ld a, $00
    rla
    or a
    ret

; StatToBase72 — A = a slot, E = the kind: the stat := its base.
StatToBase72:
    call StatLoad72
    ld a, [wCustomTmp + 2]
    ld [hl+], a
    ld a, [wCustomTmp + 3]
    ld [hl], a
    ret

; StatRise72 — A = a slot, E = the kind: one Upper (DEF) / Speed (AGL) on it,
; as StatDefUp_5e3e / StatAglUp_5f08 do: nothing when the stat is at the limit
; or the cap; else + base / 2, a sum at / over the limit -> the limit, else over
; the cap -> the cap; the raised mark (+8 bit 6) set; [S156 r2] $DB56 := the rise
; (unchanged when nothing rose).
StatRise72:
    call StatLoad72                     ; HL = &stat, DE = the stat
    call StatRoom72
    ret nc                              ; no room: nothing
    push hl
    ld a, [wCustomTmp + 2]
    ld l, a
    ld a, [wCustomTmp + 3]
    ld h, a
    srl h
    rr l                                ; base / 2
    add hl, de
    ld d, h
    ld e, l                             ; DE = the sum
    pop hl
    call StatRoom72
    jr c, .store
    ld d, b                             ; the bound it met
    ld e, c
.store:
    ld a, e                             ; [S156 r2] $DB56 := new - old (the rise, for
    sub [hl]                            ;   the line's [INS 10])
    ld [$db56], a
    inc hl
    ld a, d
    sbc [hl]
    ld [$db57], a
    ld [hl], d
    dec hl
    ld [hl], e
    ld a, [wCustomTmp]
    call BlockPtr72
    ld a, l
    add 8
    ld l, a
    set 6, [hl]                         ; raised
    ret

; ScoreSteal72 — A = a slot -> A = how many of the StealTable buffs it has (the
; AI's veto / bonus and the one-foe pick: the handler's own test). Clobbers all.
ScoreSteal72:
    ld [wSteal + 1], a
    ld bc, $0000
.lp:
    push bc
    ld a, c
    ld [wSteal + 4], a
    ld a, [wSteal + 1]
    call StealHas72
    pop bc
    jr z, .no
    inc b
.no:
    inc c
    ld a, c
    cp STEAL_COUNT
    jr c, .lp
    ld a, b
    ret

; StealTable — Plunder's buffs: [offset in the slot's block, mask (the
; target's bits), the caster's bits cleared, the value set ($FF = the target's
; bits copied), kind, the stock skill whose name the line shows]
; (BuffTable's 17 with the raised stat split; BATTLE_SKILL_SYSTEM §15.11.F4 /
; F6 / F7, §13.11).
StealTable:
    db 3, $04, $04, $04, STEAL_BIT, $25      ; TwinHits (armed; persistent)
    db 3, $08, $08, $08, STEAL_BIT, $A6      ; ALLCHANGE (sure crits; persistent)
    db 4, $01, $01, $01, STEAL_BIT, $1B      ; TakeMagic
    db 4, $02, $22, $02, STEAL_BIT, $28      ; Bounce (replaces MagicBack, as cast)
    db 4, $04, $04, $04, STEAL_BIT, $24      ; Barrier (only the target's copy)
    db 4, $20, $22, $20, STEAL_BIT, $27      ; MagicBack (replaces Bounce)
    db 4, $40, $40, $40, STEAL_BIT, $8A      ; TailWind / StormWind
    db 5, $40, $40, $40, STEAL_BIT, $26      ; MagicWall (only the target's copy)
    db 6, $03, $03, $03, STEAL_BIT, $41      ; ChargeUP — fresh: $03
    db 6, $30, $30, $30, STEAL_BIT, $43      ; SuckAir — fresh: $30
    db 6, $C0, $C0, $80, STEAL_BIT, $54      ; Focus — fresh: $80 (the follow-up next round)
    db 7, $0C, $0C, $FF, STEAL_BIT, $77      ; SideStep (+7 bits 3:2 copied; persistent)
    ASSERT (@ - StealTable) / STEAL_ROW == STEAL_ROW_DEF   ; [S156 r2] SkillPlunder's line choice
    db 8, $40, $00, $00, STEAL_DEF, $1E      ; DEF raised -> one Upper on the caster
    db 8, $40, $00, $00, STEAL_AGL, $22      ; AGL raised -> one Speed on the caster
    db 8, $20, $20, $20, STEAL_BIT, $8C      ; Dodge (this round)
    db 8, $08, $08, $08, STEAL_BIT, $7F      ; Imitate (this round)
    db 8, $02, $00, $00, STEAL_SUCKALL, $8F  ; SuckAll (this round; + the side mark)
    db 9, $07, $0F, $FF, STEAL_STANCE, $8D   ; Defence / StrongD / BladeD (level copied; this round)
DEF STEAL_COUNT EQU (@ - StealTable) / STEAL_ROW

; -----------------------------------------------------------------------------
; Repel ($DE) — FIELD only: the Repellant's own effect ($C93E bit 1: bank $16
; label16_6f05, the per-step encounter roll, does nothing while it is set).
; Reached from AnchorField14Tail (bank $14 entry 4, the field skill's
; validation, run after the MP check and before the deduct): refused ($DA5E :=
; $FF, the field menu's "fizzle") when already active or where no random
; encounter can happen (EncountersHere72); else set at once. On a gate floor it
; ends at the next floor like the item (bank $16 label16_5b4e clears $C93E);
; elsewhere wRepelArmed / wRepelPlace end it when the party arrives in another
; place (RepelCommit72, bank $73's commit). Bank $07 Anchor07Post then takes
; StepGuard's way: no message, the MP deducted.
; -----------------------------------------------------------------------------
RepelField72:
    ld a, [$c93e]
    bit 1, a
    jr nz, .fizzle
    call EncountersHere72
    jr nc, .fizzle
    ld hl, $c93e
    set 1, [hl]
    ld a, [wInGateworld]
    or a
    ld a, $00
    jr nz, .arm                         ; a gate floor: its next floor clears it
    ld a, [wMapRegion]
    ld [wRepelPlace], a
    ld a, [wMapID]
    ld [wRepelPlace + 1], a
    ld a, $01
.arm:
    ld [wRepelArmed], a
    ret
.fizzle:
    ld a, $ff
    ld [$da5e], a
    ret

; EncountersHere72 — carry = random encounters can happen here: a gate floor
; (wInGateworld != 0), the special floors bank $0B Jump_00b_4674 runs the
; per-step roll in ($53-$59 forest / conveyor / mazes, $61-$64 the forest
; rooms), or a custom room ($6B+) with encounters on (wRoomEncFlag of bank $71
; entry 1 CustomEncResolve — asked again here: bank $0B refreshes it only at
; each step, so right after an arrival it still describes the room before;
; measured S155 tools/walk_skills.py: a cast in Cities_FOUNT just after the
; den was accepted). Clobbers all.
EncountersHere72:
    ld a, [wInGateworld]
    or a
    jr nz, .yes
    ld a, [wMapID]
    cp $53
    jr c, .no
    cp $5A
    jr c, .yes
    cp $61
    jr c, .no
    cp $65
    jr c, .yes
    cp $6B
    jr c, .no
    ld hl, $7101                        ; bank $71 entry 1: this room's RoomEncTable row
    rst $10                             ;   -> wRoomEncFlag (and the gate / floor it pins,
    ld a, [wRoomEncFlag]                ;   as every step there does)
    or a
    jr nz, .yes
.no:
    and a
    ret
.yes:
    scf
    ret

; RepelCommit72 (entry 10) — bank $73 CF2WarpCommitDrain, after RegionCommit
; (wMapRegion / wMapID = the destination): a Repel cast outside a gate floor
; ends when the party arrives anywhere else (a battle's return to the same
; room keeps it). Clobbers A.
RepelCommit72:
    ld a, [wRepelArmed]
    or a
    ret z
    ld a, [wMapRegion]
    ld hl, wRepelPlace
    cp [hl]
    jr nz, .end
    inc hl
    ld a, [wMapID]
    cp [hl]
    ret z
.end:
    xor a
    ld [wRepelArmed], a
    ld hl, $c93e
    res 1, [hl]
    ret

; -----------------------------------------------------------------------------
; CustomAIRule72 (entry 8) — bank $57 CustomAI57, at the end of the AI's rule
; walk for one option of a custom id (the vanilla rules self-select on stock
; ids). Adjusts the BONUS $DD26 (saturating) / PENALTY $DD27 ($FF = veto); the
; actor = wBattleAttackerIdx (as the vanilla rules read it). The numbers are
; the vanilla rules' own sizes (+20 / +30, BATTLE_SKILL_SYSTEM §15.10.5):
;   Repel     -> veto (field-only)
;   Plunder   -> [S156] veto unless a live opponent has a buff it can steal
;                (ScoreSteal72 = the handler's own test); else +20 per buff on
;                the opponent with the most (at most +60)
;   Rupture   -> veto unless a live opponent has an ailment; else +50
;   Punish    -> +20 per buff on the most-buffed live opponent (at most +60)
;   Finish    -> +40 when a live opponent has lost half its HP or more;
;                penalty 20 when every live opponent has lost under a quarter
;   Rust      -> veto unless a live opponent has ATK > 1
;   LoneWolf  -> +40 alone, +20 in a party of two
; (sized against the cat-1 plain-attack score, bank $58 entry 11 $67BA: 20 +
; 10 per damage threshold met — a skill must out-score it to be used; measured
; S155 tools/walk_skills.py.)
; The built-ins of S49-S75 keep no rule (unchanged). Clobbers all.
; -----------------------------------------------------------------------------
CustomAIRule72:
    ld a, [$db8a]
    cp ID_REPEL
    jr z, .veto
    cp ID_PLUNDER
    jr z, .plunder
    cp ID_RUPTURE
    jr z, .rupture
    cp ID_PUNISH
    jr z, .punish
    cp ID_FINISH
    jr z, .finish
    cp ID_RUST
    jr z, .rust
    cp ID_LONEWOLF
    ret nz
    ld a, [wBattleAttackerIdx]
    call SideCount72
    ld a, b
    cp $02
    ld a, 20
    jr z, AIBonus72
    ret nc
    ld a, 40
    jr AIBonus72
.veto:
    ld a, $ff
    ld [$dd27], a
    ret
.rupture:
    ld hl, ScoreAilment72
    call OppScan72
    ld a, b
    or a
    jr z, .veto
    ld a, 50
    jr AIBonus72
.plunder:                               ; [S156] veto unless an opponent has a buff
    ld hl, ScoreSteal72                 ;   Plunder can take; else +20 per buff on the
    call OppScan72                      ;   richest one (at most +60, as Punish)
    ld a, b
    or a
    jr z, .veto
    jr .per
.rust:
    ld hl, ScoreRust72
    call OppScan72
    ld a, b
    or a
    jr z, .veto
    ret
.punish:
    ld hl, ScoreBuffs72
    call OppScan72
    ld a, b
    or a
    ret z
.per:
    cp $03
    jr c, .p
    ld a, $03
.p:
    add a                               ; x20
    add a
    ld b, a
    add a
    add a
    add b
    jr AIBonus72
.finish:
    ld hl, ScoreHurt72
    call OppScan72                      ; B = 1 + the largest missing share %
    ld a, b
    or a
    ret z
    cp 51
    ld a, 40
    jr nc, AIBonus72
    ld a, b
    cp 26
    ret nc
    ld a, [$dd27]                       ; penalty 20 (saturating; $FF stays a veto)
    add 20
    jr nc, .pen
    ld a, $fe
.pen:
    ld [$dd27], a
    ret

AIBonus72:                              ; $DD26 += A, saturating at $FF (AISatAdd_455f)
    ld hl, $dd26
    add [hl]
    jr nc, .ok
    ld a, $ff
.ok:
    ld [hl], a
    ret

; OppScan72 — HL = a scorer (A = a slot -> A = its score, 0 = unsuitable).
; Walks the live opponents of wBattleAttackerIdx (slots 0-2 of the other side,
; $DD1B == 0). Out: B = the best score (0 = none suitable), C = its slot ($FF),
; D = the first live opponent ($FF = none). Ties keep the first.
OppScan72:
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld e, a
    ld bc, $00ff
    ld d, $ff
.lp:
    push hl
    ld a, e
    add LOW($dd1b)
    ld l, a
    ld h, HIGH($dd1b)
    ld a, [hl]
    pop hl
    or a
    jr nz, .next
    ld a, d
    inc a
    jr nz, .first
    ld d, e
.first:
    push bc
    push de
    push hl
    ld a, e
    call .callhl
    pop hl
    pop de
    pop bc
    or a
    jr z, .next
    cp b
    jr c, .next
    jr z, .next
    ld b, a
    ld c, e
.next:
    inc e
    ld a, e
    and $03
    cp $03
    jr nz, .lp
    ret
.callhl:
    jp hl

ScoreAilment72:                         ; 1 = an ailment Rupture bursts
    call BlockPtr72
    inc hl
    inc hl
    ld b, [hl]
    inc hl
    ld a, [hl]
    and $C3
    or b
    ret z
    ld a, $01
    ret

ScoreBuffs72:                           ; the buff count
    call CountBuffs72
    ld a, b
    ret

ScoreRust72:                            ; ATK > 1 -> 1 + ATK / 4 (the strongest first)
    push af                             ; [S155 r5] a blunted one scores 0 (no
    push bc                             ;   stacking: the AI vetoes Blunt when every
    call BluntBit72                     ;   opponent is blunted, the pick skips them)
    pop bc
    jr z, .fresh
    pop af
    xor a
    ret
.fresh:
    pop af
    ld hl, wBattleATK
    call SlotPtr72
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, h
    or a
    jr nz, .big
    ld a, l
    cp $02
    jr nc, .big
    xor a
    ret
.big:
    srl h
    rr l
    srl h
    rr l
    ld a, l
    inc a
    ret

ScoreHurt72:                            ; 1 + the share of its MaxHP it has lost (%)
    call MissingShare72
    ld a, l
    inc a
    ret

; -----------------------------------------------------------------------------
; CustomTargetPick72 (entry 9) — bank $58 DispatchBoundsStub, for a custom id
; whose CustomTargetBaseTable row is $F0 (the act-time AI's target of a one-foe
; S155 skill — the vanilla rows pick blindly). Out: E = the slot: the best
; opponent by the skill's own scorer (Rupture: one with an ailment; Punish: the
; most buffs; [S156] Plunder: the most buffs it can steal; Finish: the most HP
; lost; Rust: the highest ATK; others: the first), else the first live
; opponent, else the opposing side's base.
; -----------------------------------------------------------------------------
CustomTargetPick72:
    ld a, [$db8a]
    ld hl, ScoreAilment72
    cp ID_RUPTURE
    jr z, .scan
    ld hl, ScoreBuffs72
    cp ID_PUNISH
    jr z, .scan
    ld hl, ScoreSteal72                 ; [S156] the most buffs Plunder can take
    cp ID_PLUNDER
    jr z, .scan
    ld hl, ScoreHurt72
    cp ID_FINISH
    jr z, .scan
    ld hl, ScoreRust72
    cp ID_RUST
    jr z, .scan
    ld hl, ScoreFirst72
.scan:
    call OppScan72
    ld e, c
    ld a, c
    inc a
    ret nz                              ; a suitable one
    ld e, d
    ld a, d
    inc a
    ret nz                              ; the first live one
    ld a, [wBattleAttackerIdx]
    and $04
    xor $04
    ld e, a
    ret

ScoreFirst72:
    ld a, $01
    ret

; MissingShare72 — A = a slot -> HL = the share of its MaxHP it has lost, in
; whole percent (0-100; MaxHP and the loss shifted below 256 first; MaxHP 0 ->
; 0). Clobbers A, BC, DE.
MissingShare72:
    push af
    ld hl, $dbb3                        ; MaxHP
    call SlotPtr72
    ld c, [hl]
    inc hl
    ld b, [hl]
    pop af
    ld hl, $dba3                        ; HP
    call SlotPtr72
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = HP, BC = MaxHP
    ld a, c                             ; DE = MaxHP - HP (0 if HP >= MaxHP)
    sub l
    ld e, a
    ld a, b
    sbc h
    ld d, a
    jr nc, .scale
    ld de, $0000
.scale:
    ld a, b
    or a
    jr z, .div
    srl b
    rr c
    srl d
    rr e
    jr .scale
.div:
    ld a, c
    or a
    ld hl, $0000
    ret z
    push bc
    ld b, 100
    call Mul16by8_72                    ; HL = loss * 100 (< 25600)
    pop bc
    jp Div16by8_72                      ; HL = the share

; [S155] CustomPctTable — the S155 skills' numbers as project data (compiler
; region gd_custom_pcts, gamedata.skills.<223 / 235-238> `duo` / `alone`,
; `per_buff`, `at_full_hp` / `near_zero_hp`, `burst`, `atk_loss`; PROJECT_COMPILER
; §2.63): percentages, 100 = x1, at most PCT_MAX. Offsets: the PCT_* constants.
CustomPctTable:
; @BUILD_PROJECT BEGIN gd_custom_pcts
    dw 200   ; [$DF] LoneWolf: x2 — the damage in a party of two (duo)
    dw 400   ; [$DF] LoneWolf: x4 — the damage alone (alone)
    dw 50    ; [$EB] Punish: x0.5 — the extra damage per buff on the target (per_buff)
    dw 20    ; [$EC] Finish: x0.2 — the damage when the target has full HP (at_full_hp)
    dw 200   ; [$EC] Finish: x2 — the damage when the target is near 0 HP (near_zero_hp)
    dw 300   ; [$ED] Rupture: x3 — the damage when the ailments burst (burst)
    dw 50    ; [$EE] Blunt: x0.5 — the ATK lost, a share of the target's base ATK (atk_loss)
CustomLineAlways:
    db %00001111   ; [S155 r3] the line every time (line_shows "always"): LoneWolf Punish Finish Rupture
; @BUILD_PROJECT END gd_custom_pcts

; =============================================================================
; [S111] SKILL TABLES the compiler owns (PROJECT_COMPILER §2.27; editor2/core/
; custom_skills.py). No edits = the S110 behaviour.
; =============================================================================
; CustomBaseTable [id-$DE] — $FF = the bespoke handler of a built-in custom
; skill ($E0-$E9); else the STOCK skill whose effect code a NEW custom skill
; runs (FarSkillFork). Ids $DE-$FE.
CustomBaseTable:
; @BUILD_PROJECT BEGIN gd_custom_base
    db $FF   ; [$DE] Repel
    db $FF   ; [$DF] LoneWolf
    db $FF   ; [$E0] MagicBurn
    db $FF   ; [$E1] Tame
    db $FF   ; [$E2] TameMore
    db $FF   ; [$E3] TameMost
    db $FF   ; [$E4] Anchor
    db $FF   ; [$E5] Tremor
    db $FF   ; [$E6] Quake
    db $FF   ; [$E7] QuakeMore
    db $FF   ; [$E8] QuakeMost
    db $FF   ; [$E9] Mourn
    db $FF   ; [$EA] Plunder
    db $FF   ; [$EB] Punish
    db $FF   ; [$EC] Finish
    db $FF   ; [$ED] Rupture
    db $FF   ; [$EE] Blunt
    db $FF   ; [$EF] -
    db $FF   ; [$F0] -
    db $FF   ; [$F1] -
    db $FF   ; [$F2] -
    db $FF   ; [$F3] -
    db $FF   ; [$F4] -
    db $FF   ; [$F5] -
    db $FF   ; [$F6] -
    db $FF   ; [$F7] -
    db $FF   ; [$F8] -
    db $FF   ; [$F9] -
    db $FF   ; [$FA] -
    db $FF   ; [$FB] -
    db $FF   ; [$FC] -
    db $FF   ; [$FD] -
    db $FF   ; [$FE] -
; @BUILD_PROJECT END gd_custom_base
; [S160] ReclaimBaseTable [id-$BC] (ROADMAP E13, BATTLE_SKILL_SYSTEM §13.12) — the
; stock skill whose effect code the NEW skill on a RECLAIMED id runs ($BC-$C1 / $CC-$D3,
; the battle skills of 14 items the game never lets the hero use in battle); $FF = no new
; skill there (the item's own handler, $52:$4625, as the original game). $C2-$CB (the
; meats and staves, which stay items) are always $FF. Compiler region gd_reclaim_base
; (editor2/core/custom_skills.py); read by ReclaimBase72 (FarSkillFork's stock path).
ReclaimBaseTable:
; @BUILD_PROJECT BEGIN gd_reclaim_base
    db $FF, $FF, $FF, $FF, $FF, $FF   ; [$BC-$C1] LifeAcorn MysticNut AtkSeed DefSeed AglSeed IntSeed
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [$C2-$CB] the meats and staves (items, never reclaimed)
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [$CC-$D3] WarpWing TinyMedal QuestBk HorrorBk BeniceBk CheaterBk SmartBk ComedyBk
; @BUILD_PROJECT END gd_reclaim_base
; [S160] ReclaimBase72 — FarSkillFork's stock path: A = a stock id (< $DE) -> A = the base
; of the new skill on a reclaimed id (ReclaimBaseTable), else A unchanged. Keeps BC / DE / HL.
ReclaimBase72:
    cp RECLAIM_A
    ret c
    cp RECLAIM_B_END
    ret nc
    push hl
    push de
    ld e, a
    sub RECLAIM_A
    ld hl, ReclaimBaseTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    cp $FF
    jr nz, .base
    ld a, e                             ; no new skill on this id: the item's own handler
.base:
    pop de
    pop hl
    ret
; StockElemTable [id] (0-221) / CustomElemTable [id-$DE] — the resistance a
; skill's damage tests (gamedata.skills.<id>.element): $FF = the effect code's
; own (stock) / none (built-in custom), $FE = none (level 0), 0-26 = one of the
; 27 resistances. Read by ElemLevel72 / CustomBattleExec.
StockElemTable:
; @BUILD_PROJECT BEGIN gd_skill_elements
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [  0- 15]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 16- 31]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 32- 47]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 48- 63]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 64- 79]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 80- 95]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [ 96-111]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [112-127]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [128-143]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [144-159]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [160-175]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [176-191]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [192-207]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [208-221]
CustomElemTable:
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [$DE-$ED]
    db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF   ; [$EE-$FD]
    db $FF   ; [$FE-$FE]
; @BUILD_PROJECT END gd_skill_elements
; CustomLearnTable [id-$DE] — the 18-byte learn rows of ids $DE-$FE (S155; $E0-$FE before) (the
; SkillLearnReqTable format: level, six u16 stat minimums, five prerequisite
; ids $FF-padded); level $FF = not learnable. Read by CustomLearnRow72.
CustomLearnTable:
; @BUILD_PROJECT BEGIN gd_custom_learn
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$DE] Repel: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$DF] LoneWolf: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$E0] MagicBurn: not learnable
    db $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$E1] Tame: level 2
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E1, $FF, $FF, $FF, $FF   ; [$E2] TameMore: level 3
    db $05, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E2, $FF, $FF, $FF, $FF   ; [$E3] TameMost: level 5
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$E4] Anchor: not learnable
    db $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$E5] Tremor: level 2
    db $04, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E5, $FF, $FF, $FF, $FF   ; [$E6] Quake: level 4
    db $06, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E6, $FF, $FF, $FF, $FF   ; [$E7] QuakeMore: level 6
    db $08, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $E7, $FF, $FF, $FF, $FF   ; [$E8] QuakeMost: level 8
    db $03, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$E9] Mourn: level 3
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$EA] Plunder: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$EB] Punish: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$EC] Finish: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$ED] Rupture: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$EE] Blunt: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$EF] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F0] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F1] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F2] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F3] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F4] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F5] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F6] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F7] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F8] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$F9] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$FA] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$FB] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$FC] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$FD] -: not learnable
    db $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $FF, $FF, $FF, $FF, $FF   ; [$FE] -: not learnable
; @BUILD_PROJECT END gd_custom_learn
