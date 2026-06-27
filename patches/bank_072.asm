; =============================================================================
; BANK $72 — CUSTOM SKILL EFFECT DISPATCH (S2 alias framework)
; =============================================================================
; AliasCommit (bank $50) templatizes a new skill id to Blaze(0) as it enters the
; action queue, so every range-bucketed system (targeting, animation, message,
; MP, record) sees Blaze. The REAL id is stashed in $db86 at commit.
;
; FarSkillFork (entry 0, HL=$7200) replaces the dispatch's
; `ld hl,$4011 / add hl,bc / add hl,bc` at $6CD5. Returns HL=&handler-pointer
; (bank $52) and BC=id; the dispatch's `call RST_08` derefs + jp's in-bank.
;
;   Guard: a normal action (incl. every enemy action) has a NONZERO working id
;   in $db8a, so it dispatches on $db8a and never consults $db86. Only when
;   $db8a==0 (our templatized custom cast, or a real Blaze cast) do we consult
;   $db86: if it holds a custom id ($DE/$DF) this is our aliased cast -> use it;
;   otherwise it's a genuine Blaze cast -> id 0.
;     id < $DE   -> HL = $4011 + id*2   (vanilla SkillFunctionTable)
;     id $DE/$DF -> HL = $7FED + (id-$DE)*2   (CustomSkillTable52)
; =============================================================================

SECTION "ROM Bank $072", ROMX[$4000], BANK[$72]

    db $72
    dw FarSkillFork

FarSkillFork:
    ld a, [$db8a]                       ; working id (0 = templatized custom / real Blaze)
    or a
    jr nz, .have                        ; nonzero -> normal action, dispatch on $db8a
    ld a, [$db86]                       ; $db8a==0: consult stashed real id
    cp $DE
    jr c, .blaze                        ; < $DE -> genuine Blaze cast
    cp $E0
    jr nc, .blaze                       ; >= $E0 (unexpected) -> treat as Blaze
    jr .have                            ; $DE/$DF -> our aliased custom cast
.blaze:
    xor a                               ; id 0 (Blaze)
.have:
    ld c, a
    ld b, $00
    cp $DE
    jr c, .vanilla
    sub $DE
    add a
    add $ED                             ; -> &CustomSkillTable52[id-$DE] ($7FED/$7FEF)
    ld l, a
    ld h, $7F
    ret
.vanilla:
    ld hl, $4011
    add hl, bc
    add hl, bc
    ret
