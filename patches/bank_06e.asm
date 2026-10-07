; =============================================================================
; BANK $6E — ARENA SYSTEMS (S109, ROADMAP P3.10b; hand-authored,
; patches/bank_06e.asm)
; =============================================================================
; The arena's three-monster teams are FORMULA-addressed enemy-stats rows
; (SIDEQUEST_MAP "Arena / gate-boss ROSTER format"): ArenaBattleSetup (script
; opcode $1F, bank $04) and its between-matches clone LoadArenaEnemyStats
; (bank $50) load EID = $E0 + 9*wArenaGroup + 3*wColiseumBattle + slot into
; the three battle slots, write $DA02 = 2 (3 enemies) and fill the Arena Battle
; room's display list $D7CA-$D7D1 ([draw id, is_monster] x 4: entry 0 = the
; master, entry 2 = slot 0 (the middle monster), entry 1 = slot 1, entry 3 =
; slot 2 — the room's NPCs $F0-$F3 draw them, bank $0B Call_00b_4839).
;
; entry 0  ArenaTeamFixup — far-called from the LAST instruction pair of both
;          routines (`ld a,$01 / ld [$d7d1],a / ret` became `ld hl,$6E00 /
;          rst $10 / ret / nop`, same size; banks $04 and $50 admit no inserts).
;          It writes $D7D1 = 1 (the pair it replaced), then applies the match's
;          TEAM SIZE from ArenaTeamSizeTable (compiler region gd_arena_team_sizes,
;          gamedata.arena.<group>.matches.<m>.size):
;            size 3 (vanilla, and every row of an unedited project) -> nothing
;            size 2 -> $DA02 = 1 (slots 0-1 fight), display entry 3 = [$FF, $00]
;            size 1 -> $DA02 = 0 (slot 0 fights), entries 1 and 3 = [$FF, $00]
;          A display entry whose draw id is $FF gives its NPC sprite $FF = not
;          drawn (Call_00b_4839's own $FF path, the one vanilla SetBtl_67ae
;          uses for the coliseum). The battle itself takes 1-3 enemies from
;          $DA02 like any field battle (PyBoy S109, the user's save: 1- and
;          2-monster arena teams fought, won, the next match loaded).
;          Index = 3*wArenaGroup + wColiseumBattle: ArenaBattleSetup runs with
;          wColiseumBattle = 0 (the lobby script writes it), the bank-$50 clone
;          after each won match with wColiseumBattle = the NEXT match (the Arena
;          Battle room script counts it up before cmd_20); the clone returns
;          early at 3, so it never asks for a fourth. Monster Grandpa's match (group 9, the code
;          overrides its EIDs with $01E1-$01E3) = index 27. An index >= 30
;          (never written by the game) leaves the vanilla values.
; entry 1  ArenaMarkClasses (S128, ROADMAP P3.14e3 — your arena) — far-called by
;          bank $09 ArenaMenuMarkWon (its body moved here, same size): the class
;          menu's eight marks $C0D8[0..7] := $90 (open), the first [$CAB4] := $AC
;          (the star = won; $CAB4 = classes won) — the original, byte for byte.
;          THEN, only in the project's lobby (wMapID = ARENA_LOBBY_MID, a copy of
;          the Arena Lobby — custom.arena, editor2/core/your_arena.py): a class
;          whose lock record in ArenaLockTable does not hold gets ARENA_LOCK_GLYPH
;          ($9C "-"; a won class keeps its star). The menu's A press accepts only
;          $90 (ArenaClassMenu_State2), so a locked class is refused like a won
;          one — with the project's "not open yet" words instead of menu line +6
;          (bank $09 ArenaRefuse09 -> ARENA_LOCKED_OFS). The original arena (map
;          $06) never reads the locks.
;          ArenaLockTable (compiler region arena_rooms): 8 records G..S, each
;          [n terms] + n x dw flag (bit 15 = the flag must be CLEAR); every term
;          must hold for the class to be open; 0 terms = always open.
; The region arena_rooms also carries the EQUs every bank reads (ROM0
; ArenaMapID, bank $50 ArenaLossWarp50): ARENA_LOBBY_MID / ARENA_BATTLE_MID (the
; project's copies; $FF = no arena) and ARENA_RET_X / _Y (the pixel a lost match
; and the win return to in the project's lobby).
; rst $10 contract (bank $00): A/F/BC clobbered; both callers `ret` at once.
; =============================================================================

SECTION "ROM Bank $06E", ROMX[$4000], BANK[$6E]

    db $6E                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw ArenaTeamFixup                   ; entry 0  (HL=$6E00)
    dw ArenaMarkClasses                 ; entry 1  (HL=$6E01, S128)

ARENA_TEAM_ROWS EQU 30                  ; 10 groups x 3 matches

ArenaTeamFixup:
    ld a, $01
    ld [$d7d1], a                       ; display entry 3 = monster (the replaced pair)
    ld a, [wArenaGroup]
    ld b, a
    add a
    add b                               ; 3 * group
    ld b, a
    ld a, [wColiseumBattle]
    add b                               ; + match
    cp ARENA_TEAM_ROWS
    ret nc
    ld hl, ArenaTeamSizeTable
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]                          ; team size 1-3
    cp $03
    ret nc                              ; 3 = the vanilla team
    or a
    ret z                               ; (0 is never emitted)
    dec a
    ld [$da02], a                       ; enemy count - 1
    ld hl, $d7d0                        ; slot 2 (display entry 3) leaves
    ld [hl], $ff
    inc hl
    ld [hl], $00
    or a
    ret nz                              ; size 2
    ld hl, $d7cc                        ; size 1: slot 1 (display entry 1) too
    ld [hl], $ff
    inc hl
    ld [hl], $00
    ret

; @BUILD_PROJECT BEGIN gd_arena_team_sizes
ArenaTeamSizeTable:  ; index 3*group + match; 1-3 monsters
    db 3, 3, 3   ; G class
    db 3, 3, 3   ; F class
    db 3, 3, 3   ; E class
    db 3, 3, 3   ; D class
    db 3, 3, 3   ; C class
    db 3, 3, 3   ; B class
    db 3, 3, 3   ; A class
    db 3, 3, 3   ; S class
    db 3, 3, 3   ; Starry Night
    db 3, 3, 3   ; Monster Grandpa's match (only match 1 is fought)
; @BUILD_PROJECT END gd_arena_team_sizes

; -----------------------------------------------------------------------------
; Entry 1: ArenaMarkClasses (S128) — see the header. Clobbers everything.
; -----------------------------------------------------------------------------
ARENA_LOCK_GLYPH EQU $9C                ; font "-": the class is not open yet

ArenaMarkClasses:
    ld hl, $c0d8
    ld b, 8
    ld a, $90
.fill:
    ld [hl+], a                         ; every class open ...
    dec b
    jr nz, .fill
    ld a, [$cab4]
    or a
    jr z, .locks
    ld b, a
    ld hl, $c0d8
.won:
    ld [hl], $ac                        ; ... the first [$CAB4] won (the star)
    inc hl
    dec b
    jr nz, .won
.locks:
    ld a, [wMapID]
    cp ARENA_LOBBY_MID
    ret nz                              ; the original arena: no locks
    ld hl, ArenaLockTable
    ld de, $c0d8                        ; DE = this class's mark
.class:
    ld a, [hl+]                         ; n terms (0 = always open)
    ld b, h
    ld c, l
    push af
    add a                               ; BC := HL + 2n = the next record
    add c
    ld c, a
    ld a, b
    adc $00
    ld b, a
    pop af
    push bc                             ; [sp+2] = the next record
    push de                             ; [sp] = the mark
    ld d, a                             ; D = terms left
    or a
    jr z, .open
.term:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    ld a, b
    and $80
    ld e, a                             ; E bit 7 = the flag must be CLEAR
    res 7, b
    call TestEventFlag                  ; Z = clear, NZ = set (BC / DE kept)
    pop hl
    jr z, .isClear
    bit 7, e
    jr nz, .locked                      ; set, but must be clear
    jr .termNext
.isClear:
    bit 7, e
    jr z, .locked                       ; clear, but must be set
.termNext:
    dec d
    jr nz, .term
.open:
    pop de
    jr .advance
.locked:
    pop de
    ld a, [de]
    cp $ac
    jr z, .advance                      ; a won class keeps its star
    ld a, ARENA_LOCK_GLYPH
    ld [de], a
.advance:
    pop hl                              ; the next record
    inc de
    ld a, e
    cp LOW($c0d8 + 8)
    jr nz, .class
    ret

; @BUILD_PROJECT BEGIN arena_rooms
; (generated by editor2 `arena_rooms` from custom.arena — editor2/core/your_arena.py)
ARENA_LOBBY_MID EQU $FF                 ; the project's lobby (a copy of $06); $FF = none
ARENA_BATTLE_MID EQU $FF                ; the project's arena (a copy of $5D); $FF = none
ARENA_RET_X EQU $00E8                   ; return pixel in the lobby (x)
ARENA_RET_Y EQU $0048                   ; return pixel in the lobby (y)
ARENA_LOCKED_OFS EQU $0006              ; the locked words' text id - $0710 (6 = the won line)
ArenaLockTable:  ; G F E D C B A S: [n terms] + n x dw flag (bit 15 = must be clear)
    db 0, 0, 0, 0, 0, 0, 0, 0
; @BUILD_PROJECT END arena_rooms

    ds $8000 - @, $00
