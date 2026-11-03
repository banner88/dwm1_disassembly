"""ai_fixes.py — S164: the original enemy AI's bugs as project switches (ROADMAP E17 note "the
original AI's bugs"; BATTLE_SKILL_SYSTEM §15.10.5 "S164"; PROJECT_COMPILER §2.72).

The enemy AI scores each skill with the bank $57 rule chains (S81 / S163 decode). Five rules of
the original game do not do what they were written for — each reads the first opposing slot
only, counts it twice, or divides by the wrong number. A project may switch each one ON
(`gamedata.ai_fixes.<key>: true`); OFF (the default, or absent) = the original bytes, so the
original game's difficulty is untouched unless the author asks.

  key           what the original does                      the fix
  aoe_count     $4E36 "+20 to a group skill when 2+ live    counts the live opponents
                opponents": the slot loop never advances —  (the loop's `inc c`)
                +20 whenever the FIRST opposing slot is
                alive (its twin $5D8E counts correctly)
  class_count   the status-class bonuses ($5FFD +20 Sleep   the count starts at 0
                class, $6180 poison, $61BC Curse, $604A,    (CallBtlAI_7d4d returns
                $60C8, $6107, $6144): CallBtlAI_7d4d falls  before SetBtlAI_7d54)
                into SetBtlAI_7d54 and counts the first
                opposing slot once before the loop counts
                it again (count = 1 + n, sum + its level)
  family_cut    $4C41 "+20 to a family cut (DragonCut …)    all three opposing slots
                when a live foe is of that family": after   (the miss loops back to
                a miss the loop `inc c / dec b / jr nz`     the test)
                jumps back to ITSELF — only the first slot
                is ever tested
  demagic_scan  $6BCB DeMagic's "veto unless a foe has a    all three opposing slots
                buff": the slot loop never advances — the
                first opposing slot is read three times
  averages      the averages the AI compares are never      the sums are summed and
                computed: $4D56 (+10 to a physical special  divided by the count
                when the caster's ATK >= the foes' average
                DEF: FuncBtlAI_7dc5 adds the running sum 0
                INTO each DEF entry and divides 0 by the
                sum's high byte — 0 against 1-2 foes, $FFFF
                against 3) and $551B (+10 to a defensive
                buff — Surround, Upper, Increase, SandStorm,
                Radiant, SideStep — when the foes' average
                ATK beats twice the own side's average DEF:
                the ATK sum is divided by its own high byte)

Each fix is a compiler region in patches/bank_057.asm (same size, `ASSERT`ed): the original
text or the fixed one. `averages` owns two regions: FuncBtlAI_7dc5's body (rewritten in its own
91 bytes, + OppAvgDiv57 in the rest) and AIRule_551b's divide (`call OppAvgDiv57`).
The Balance simulator follows the switches (simulator/ai_rules.evaluate_chain `fixes`).
"""

AI_FIXES = ('aoe_count', 'class_count', 'family_cut', 'demagic_scan', 'averages')

# what the editor shows: key -> (title, the original, the fix)
TEXT = {
    'aoe_count': (
        'Group skills against several foes',
        'The +20 meant for a group skill (Firebal, Bang, the breaths …) when two or more foes '
        'are alive looks at the first foe three times: it is given whenever the first foe '
        'is alive, even against a lone foe.',
        'The +20 only when two or more foes are alive (the game\'s own -20 against a lone '
        'foe is unchanged).'),
    'class_count': (
        'Status skills: counting the foes',
        'The bonus of a status skill (Sleep, poison, Curse, Surround, the MP takers, the DEF / '
        'AGL downs) compares the foes it can still affect with how much they resist; the '
        'count starts at one, the first foe counted twice, so the bonus comes too easily.',
        'Each foe is counted once.'),
    'family_cut': (
        'Family cuts (DragonCut, ZombieCut …)',
        'The +20 when a foe is of the cut\'s family looks at the first foe only.',
        'The +20 when any live foe is of that family.'),
    'demagic_scan': (
        'DeMagic: does a foe have a buff?',
        'DeMagic is ruled out unless a foe has a buff to remove — but only the first foe is '
        'looked at (three times).',
        'All three foes are looked at.'),
    'averages': (
        'Average ATK / DEF',
        'Two rules compare averages that are never computed: physical specials get +10 when '
        'the caster\'s ATK beats the foes\' average DEF (taken as 0 against one or two foes, '
        'as the highest number against three); defensive buffs (Surround, Upper, Increase, '
        'SandStorm, Radiant, SideStep — the cleverest enemies only) get +10 when the foes\' '
        'average ATK beats twice their own side\'s average DEF (the foes\' sum divided by '
        'the wrong number).',
        'Both averages are the real averages of the live monsters.'),
}

REGION_KEYS = {'gd_ai_fix_aoe': 'aoe_count', 'gd_ai_fix_count': 'class_count',
               'gd_ai_fix_cut': 'family_cut', 'gd_ai_fix_demagic': 'demagic_scan',
               'gd_ai_fix_avgdef': 'averages', 'gd_ai_fix_avg': 'averages'}

_ORIG = {
    'gd_ai_fix_cut': """    jr nz, jr_057_44ca
""",
    'gd_ai_fix_aoe': """jr_057_4e5d:
    push de
    ld a, c
    call CheckMonsterSlot
    pop de
    jr c, jr_057_4e66
    inc e
jr_057_4e66:
    dec b
    jr nz, jr_057_4e5d
""",
    'gd_ai_fix_count': """    xor a
    ld [$db54], a
""",
    'gd_ai_fix_demagic': """    dec b
    jr nz, jr_057_6bec
    call ClearBattleAction
    ret
""",
    'gd_ai_fix_avg': """    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call Div16x8To16
""",
    'gd_ai_fix_avgdef': """    ld c, a
    ld b, $03
    ld de, $0000
    ld a, e
    ld [$db56], a
    ld a, d
    ld [$db57], a

jr_057_7dd3:
    ld a, c
    call CheckMonsterSlot
    jr c, jr_057_7deb

    ld a, c
    ld hl, wBattleDEF
    call AIIndexWordTable_45ea
    ld a, [$db56]
    add [hl]
    ld [hl+], a
    ld a, [$db57]
    adc [hl]
    ld [hl], a
    inc d

jr_057_7deb:
    inc c
    dec b
    jr nz, jr_057_7dd3

    ld a, d
    cp $01
    ret z

    cp $02
    jr z, jr_057_7e0b

    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    call Div16x8To16
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret


jr_057_7e0b:
    ld a, [$db56]
    ld l, a
    ld a, [$db57]
    ld h, a
    sra h
    rr l
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret
""",
}

_FIXED = {
    'gd_ai_fix_cut': """    jr nz, LoadBtlAI_44a7               ; [S164 family_cut] back to the TEST: all three slots
""",
    'gd_ai_fix_aoe': """jr_057_4e5d:                            ; [S164 aoe_count] count the live opponents
    ld a, c                             ; (CheckMonsterSlot keeps BC / DE / HL: no push)
    call CheckMonsterSlot
    jr c, jr_057_4e66
    inc e
jr_057_4e66:
    inc c                               ; the next slot (the original never advanced)
    dec b
    jr nz, jr_057_4e5d
    nop
""",
    'gd_ai_fix_count': """    ld [$db54], a                       ; [S164 class_count] A = 0 (LoadBtlAI_7d73 ends xor a)
    ret                                 ; no fall into SetBtlAI_7d54: the loop counts each once
""",
    'gd_ai_fix_demagic': """    inc c                               ; [S164 demagic_scan] the next opposing slot
    dec b
    jr nz, jr_057_6bec
    jp ClearBattleAction                ; = call / ret, a byte shorter
""",
    'gd_ai_fix_avg': """    call OppAvgDiv57                    ; [S164 averages] the ATK sum / the count [$db6c]
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
""",
    'gd_ai_fix_avgdef': """    ld c, a                             ; [S164 averages] the live monsters' average DEF
    ld b, $03                           ; of the side starting at slot A -> $DB56 / $DB57
    ld d, $00                           ; D = how many are alive
    xor a
    ld [$db56], a
    ld [$db57], a
AvgDefLoop57:
    ld a, c
    call CheckMonsterSlot
    jr c, AvgDefNext57
    ld a, c
    ld hl, wBattleDEF
    call AIIndexWordTable_45ea
    ld a, [$db56]                       ; the SUM += this DEF (the original added the sum
    add [hl]                            ; into the DEF entry instead)
    ld [$db56], a
    inc hl
    ld a, [$db57]
    adc [hl]
    ld [$db57], a
    inc d
AvgDefNext57:
    inc c
    dec b
    jr nz, AvgDefLoop57
    ld a, d
    cp $02
    ret c                               ; none alive: 0; one: its DEF
    ld hl, $db56
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, d
    call Div16x8To16                    ; HL = the sum / the count
    ld a, l
    ld [$db56], a
    ld a, h
    ld [$db57], a
    ret
; OppAvgDiv57 — AIRule_551b's divide: HL = the opposing ATK sum ($DB56 / $DB57) / the count
; [$DB6C] (the original divided by the sum's high byte).
OppAvgDiv57:
    ld hl, $db56
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, [$db6c]
    jp Div16x8To16
    ds $7e20 - @, $00
""",
}

REGION_FILE = 'patches/bank_057.asm'


class AIFixError(ValueError):
    pass


def fixes_of(prj):
    """The switched-on fixes (a frozenset of keys) of a Project or a project.json dict."""
    data = prj if isinstance(prj, dict) else getattr(prj, 'data', None) or {}
    v = (data.get('gamedata') or {}).get('ai_fixes') or {}
    return frozenset(k for k in AI_FIXES if v.get(k) is True)


def validate(gd, errors):
    v = gd.get('ai_fixes')
    if v is None:
        return
    if not isinstance(v, dict):
        errors.append('gamedata.ai_fixes: must be an object {fix: true / false}')
        return
    for k, x in v.items():
        if k not in AI_FIXES:
            errors.append(f'gamedata.ai_fixes.{k}: unknown (known: {", ".join(AI_FIXES)})')
        elif not isinstance(x, bool):
            errors.append(f'gamedata.ai_fixes.{k}: must be true or false')


def _emitter(name):
    key = REGION_KEYS[name]

    def emit(prj, warnings):
        return (_FIXED if key in fixes_of(prj) else _ORIG)[name]
    emit.__name__ = f'emit_{name}'
    return emit


REGIONS = [(name, REGION_FILE, _emitter(name), 0x57) for name in
           ('gd_ai_fix_cut', 'gd_ai_fix_aoe', 'gd_ai_fix_count', 'gd_ai_fix_demagic',
            'gd_ai_fix_avg', 'gd_ai_fix_avgdef')]
