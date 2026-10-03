; =============================================================================
; BANK $71 — CUSTOM ROOM DISPATCH (keystone: table-driven, ceiling-free)
; =============================================================================
; Reached via `ld hl,$71xx; rst $10`. The far-call mechanism maps this bank,
; runs the entry routine in-bank (so this bank's tables at $4000-$7FFF are
; readable), and restores the previous bank on return. Routines communicate
; results through WRAM scratch (DE/HL returns across rst $10 are unreliable,
; and bank-$71 pointers are invalid once the bank is unmapped) — the proven
; far-COPY contract, mirroring bank $6A's NewSpeciesInfoCopy.
;
; Entry 0 (HL=$7100) CopyCustomRoomRecord:
;     Copy the 8-byte $26DD-style record for wMapID into wRoomRecScratch.
;     For mapIDs <$70: source = ($26DD normal | $2A5D gate) + mapID*8 — byte-
;     identical to the original in-ROM0 table read (replaces CustomGFXMapID +
;     index at all three consumer sites). For mapIDs $70+: source =
;     Custom26DDTable + (mapID-$70)*8 — this is what lifts the old $6F ceiling.
;
; Entry 1 (HL=$7101) CustomEncResolve:
;     Look up RoomEncTable[mapID-$6B]. If enabled, write wGateID + wCurrentFloor
;     and set wRoomEncFlag=$01; else wRoomEncFlag=$00. Replaces the hardcoded
;     Seed6BEncounterPool whitelist in bank $0B.
;
; Entry 2 (HL=$7102) CustomRoomBGMResolve (S64, M3b):
;     E := CustomRoomBGMTable[wMapID] (128-entry table, generated), or 0 when
;     wInGateworld!=0 / wMapID>=$80 / no assignment. Called by the rewritten
;     LoadNewBGMIdIntoA head (patches/bank_001.asm) BEFORE the vanilla
;     derivation, so an assigned id overrides both the vanilla RoomBGMTable
;     and the gate path, for vanilla AND custom rooms alike — and survives
;     save/reload because the load path re-runs the same derivation.
;     Return in E per the proven DE-return contract (KEY_LESSONS: rst $10
;     clobbers A on return but not DE; CustomReadStep returns DE the same way).
;     Gate floors (wInGateworld!=0) keep vanilla floor-derived music: wMapID is
;     not room-meaningful there — EXCEPT the floor before a CUSTOM boss room
;     (S101): the boss room's song (or $34), never RoomBGMTable[custom id].
;
; Entry 3 (HL=$7103) CustomAnimSource (S99, ROADMAP P3.3e):
;     E := CustomAnimSrcTable[wMapID-$6B] — the map ID whose bank-$01 room-
;     animation handler runs for this custom room (a vanilla room's own
;     handler, or ANIM_NONE $6B = the dispatch table's bare-`ret` row).
;     Out-of-range ids get ANIM_NONE. Called every field frame by the
;     rewritten PerRoomVRAMDispatch (patches/bank_001.asm), for wMapID >=
;     CUSTOM_ROOM_START only; E-return per the DE contract (rst $10 clobbers
;     A). Table generated from project.json custom.rooms[].animation
;     (PROJECT_COMPILER §2.15; ROOM_DATA_FORMAT "Animated tiles").
;     S102: first far-calls bank $6C entry 0 CustomTileAnimate (the room's
;     own tile animations, custom.rooms[].tile_anims — §2.19), so a room
;     can play authored animations AND a vanilla room's animation together.
;
; Entry 4 (HL=$7104) CustomGateInsert (S100, ROADMAP P3.7b part 1):
;     Called by bank $16 GateDecisionFork on every NON-boss gate floor (after
;     the anchor check). Scans GateInsertTable (generated from project.json
;     custom.gate_inserts[], in list order) for the first rule whose gate ==
;     wGateID, floor range holds wCurrentFloor (0-based, the value entry 5
;     just incremented), once-per-dive bit is unused this dive, and flag terms
;     all hold — THEN rolls its chance (RNG16 mod 100 < chance, the
;     SelectFloorType roll) — so a gate with no applicable rule draws no RNG
;     and stays vanilla. Hit: writes wMapID, wInGateworld=0 and the spawn
;     pixels (exactly what the vanilla special-room handler $16:$5D0D writes),
;     sets the rule's once bit, returns E=1. Miss: E=0, nothing written.
;     Dive tracking: wGateDiveGate = wGateID+1 of the current dive, reset
;     (with wGateDiveMask) on floor 0 or a different gate. Both bytes are
;     saved/loaded through SRAM $BFCA/$BFCB by bank $73 entries 5/6.
;
; Entry 5 (HL=$7105) CustomRoomFlags (S100):
;     E := CustomRoomFlagsTable[wMapID-$6B] (0 for out-of-range ids). Bit 0 =
;     saving is NOT allowed in this room. Read by the bank $07 save-permission
;     ladder (same-size rewrite, patches/bank_007.asm SaveAllowCheck).
;
; Entry 6 (HL=$7106) CustomBGMStart (S116, ROADMAP P3.13b):
;     Called by the rewritten ROM0 InitBGM (patches/bank_000.asm) for a BGM
;     request id >= $9E, after InitAudioSystem and with [$de24] = the id:
;     starts CustomBGMChanTable[id-$9E] consecutive sound ids (one ROM0
;     AudioProcess each — it maps the song bank itself and returns to this
;     bank), 3 when the table holds 0 (not a song's first id: the old
;     default). Runs inside InitBGM's di.
;
; Entry 7 (HL=$7107) BattleBGMResolve (S116, ROADMAP P3.13b):
;     E := the song a battle starts with. Called by the same-size rewrite of
;     bank $51 LoadBattle's music pick (patches/bank_051.asm). Vanilla: $27,
;     or $2B in the arena battle room ($5D) when wArenaStarryBattle == 2 (the
;     Starry Night final). Project order: link battle ($C86C) = vanilla; this
;     fight (BattleFightBGMTable, the first enemy's EID $DA03/$DA04); the arena
;     (BattleBGMSettings Starry final / arena); the room
;     (CustomRoomBattleBGMTable[wMapID], $FF = follow the gate); the gate being
;     dived (CustomGateBattleBGMTable[wGateID] — maze floors, the special
;     rooms $50/$51/$53-$5C, rooms marked $FF); a boss fight ($DA09 == 3,
;     opcodes $5A/$5B) = the boss setting; else the normal setting (only where
;     vanilla plays $27). 0 everywhere = the vanilla pick.
; =============================================================================

SECTION "ROM Bank $071", ROMX[$4000], BANK[$71]

    db $71                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CopyCustomRoomRecord             ; entry 0  (HL=$7100)
    dw CustomEncResolve                 ; entry 1  (HL=$7101)
    dw CustomRoomBGMResolve             ; entry 2  (HL=$7102, S64 M3b)
    dw CustomAnimSource                 ; entry 3  (HL=$7103, S99 P3.3e)
    dw CustomGateInsert                 ; entry 4  (HL=$7104, S100 P3.7b)
    dw CustomRoomFlags                  ; entry 5  (HL=$7105, S100)
    dw CustomBGMStart                   ; entry 6  (HL=$7106, S116 P3.13b)
    dw BattleBGMResolve                 ; entry 7  (HL=$7107, S116 P3.13b)

; -----------------------------------------------------------------------------
; Entry 0: CopyCustomRoomRecord — 8-byte $26DD record for wMapID → wRoomRecScratch
; -----------------------------------------------------------------------------
CopyCustomRoomRecord:
    ; S55 FIX: maintain wCustomRoomFlag on every call (this entry runs per
    ; movement frame for ALL rooms via the ROM0 collision-threshold reader).
    ; The flag is no longer inside the save image after the $DE74 relocation,
    ; so it must be DERIVED, not restored: flag := (wMapID >= CUSTOM_ROOM_START).
    ; Fixes load-inside-custom-room (flag read $00 after load -> bank $0B
    ; readers took the vanilla path for a custom mapID -> garbage walk on the
    ; first scroll).
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ld a, $00
    jr c, .setFlag
    inc a
.setFlag:
    ld [wCustomRoomFlag], a
    ld a, [wMapID]
    cp $70
    jr nc, .custom
    ; --- mapIDs <$70: replicate the original $26DD/$2A5D base + raw-mapID index ---
    ld hl, $26dd                        ; normal-room tileset table base
    ld a, [wInGateworld]
    or a
    jr z, .haveBase
    ld hl, $2a5d                        ; gate-room tileset table base
.haveBase:
    ld a, [wMapID]                      ; index = raw mapID (CustomGFXMapID contract)
    jr .index
.custom:
    ; --- mapIDs $70+: index Custom26DDTable by (mapID-$70) ---
    sub $70
    ld hl, Custom26DDTable
.index:
    ; HL = base + index*8   (16-bit; vanilla mapIDs up to $6A make index*8 > 255)
    ld e, a
    ld d, $00
    sla e
    rl d                                ; de = index*2
    sla e
    rl d                                ; de = index*4
    sla e
    rl d                                ; de = index*8
    add hl, de                          ; HL = &record
    ; copy 8 bytes HL -> wRoomRecScratch
    ld de, wRoomRecScratch
    ld b, $08
.copy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, .copy
    ret

; -----------------------------------------------------------------------------
; Entry 1: CustomEncResolve — RoomEncTable[mapID-$6B] → wGateID/wCurrentFloor/flag
; -----------------------------------------------------------------------------
CustomEncResolve:
    ld a, [wMapID]
    sub CUSTOM_ROOM_START               ; index = mapID - $6B
    cp ENC_TABLE_LEN
    jr nc, .disabled                    ; out of table range → no encounters
    ld e, a
    ld d, $00
    ld hl, RoomEncTable
    add hl, de
    add hl, de
    add hl, de                          ; HL = &RoomEncTable[index] (stride 3)
    ld a, [hl+]                         ; [0] enabled?
    or a
    jr z, .disabled
    ld a, [hl+]                         ; [1] gate id
    cp $FF                              ; S100: $FF = "follow the gate" (a room
    jr z, .follow                       ;   served inside a dive): never pin —
    ld [wGateID], a                     ;   pinning would re-route the dive's
    ld a, [hl]                          ; [2] floor   next floor to that gate
    ld [wCurrentFloor], a
.follow:
    ld a, $01
    ld [wRoomEncFlag], a
    ret
.disabled:
    xor a
    ld [wRoomEncFlag], a
    ret

; -----------------------------------------------------------------------------
; Entry 2: CustomRoomBGMResolve — E := assigned room BGM id, or 0 (S64, M3b)
; S101: a CUSTOM boss room (wBossMapType >= $6B, custom.gates[].boss) — the
; vanilla derivation would index RoomBGMTable[wBossMapType] past its $70
; entries on the floor before the boss floor (garbage song). There, and in
; an unassigned custom room at that floor (a served room, or stale dive
; values), E := the boss room's CustomRoomBGMTable entry, or $34 (the gate
; theme) when it has none. Vanilla boss maps keep the vanilla derivation.
; S116: a gate's OWN song (CustomGateBGMTable[wGateID], music.gates[].floors)
; plays where vanilla plays the gate theme: maze floors, the special rooms
; ($50/$51/$53-$5C — vanilla routes them to the gate path; they only occur in
; dives) and custom rooms whose table byte is $FF (gate rooms with no song of
; their own — the compiler marks them only when some gate has a song). The
; floor before a VANILLA boss room keeps the vanilla boss song; before a
; custom boss room with no song: the gate's song, else $34. Unmarked custom
; rooms (0) behave exactly as before S116 (no gate song: wGateID may be stale
; outside a dive).
; -----------------------------------------------------------------------------
CustomRoomBGMResolve:
    ld e, $00                           ; default: no assignment
    ld d, $01                           ; D = 1: the gate's own song may play
    ld a, [wInGateworld]
    or a
    jr nz, .dive                        ; maze floors
    ld a, [wMapID]
    cp $80
    ret nc                              ; out of table range
    call .lookup                        ; E = CustomRoomBGMTable[wMapID]
    ld a, e
    cp $FF
    jr z, .dive                         ; a gate room with no song of its own
    or a
    ret nz                              ; assigned: wins
    ld a, [wMapID]
    cp $61
    jr nc, .noGateSong                  ; unmarked custom room: S101 path only
    cp $50
    ret c                               ; RoomBGMTable rooms: vanilla derivation
    cp $52
    ret z                               ; the coliseum: RoomBGMTable
    cp $5D
    ret nc                              ; $5D-$60: RoomBGMTable
    jr .dive                            ; a special room inside a dive
.noGateSong:
    ld d, $00
.dive:
    ld e, $00
    ld a, [wLastFloor]
    sub $02
    ld b, a
    ld a, [wCurrentFloor]
    cp b
    jr nz, .floorSong                   ; not the floor before the boss floor
    ld a, [wBossMapType]
    cp CUSTOM_ROOM_START
    ret c                               ; vanilla boss map: vanilla (its boss song)
    cp $80
    jr nc, .bossNoSong
    call .lookup                        ; the custom boss room's own song
    ld a, e
    or a
    jr z, .bossNoSong
    inc a
    ret nz                              ; a song (not 0, not $FF): it plays
.bossNoSong:
    call .floorSong
    ld a, e
    or a
    ret nz                              ; the gate's song
    ld e, $34                           ; no song: the gate theme
    ret
.floorSong:                             ; E := the gate's song if D, else 0
    ld e, $00
    ld a, d
    or a
    ret z
    ld a, [wGateID]
    cp GATE_BGM_LEN
    ret nc
    ld hl, CustomGateBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld e, [hl]
    ret
.lookup:                                ; A = mapID -> E = table byte
    ld hl, CustomRoomBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld e, [hl]
    ret

; -----------------------------------------------------------------------------
; Entry 3: CustomAnimSource — E := the room's animation source map ID (S99)
; -----------------------------------------------------------------------------
CustomAnimSource:
    ld hl, $6c00                        ; S102: bank $6C entry 0 CustomTileAnimate —
    rst $10                             ; the room's OWN animated tiles (§2.19) first
    ld e, $6b                           ; ANIM_NONE: the table's bare-`ret` row
    ld a, [wMapID]
    sub CUSTOM_ROOM_START               ; index = mapID - $6B
    cp ANIM_TABLE_LEN
    ret nc                              ; out of table range -> none
    ld hl, CustomAnimSrcTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld e, [hl]
    ret

; -----------------------------------------------------------------------------
; Entry 4: CustomGateInsert — serve a custom room on a gate floor (S100)
; -----------------------------------------------------------------------------
; GateInsertTable record (generated; $FF at +0 ends the table):
;   +0 gate  +1 floor_lo  +2 floor_hi (0-based wCurrentFloor, inclusive)
;   +3 chance (1-100; >=100 = always, no RNG)  +4 once-per-dive bit (0 = none)
;   +5 mapID  +6/+7 spawn X px (lo, hi)  +8/+9 spawn Y px (lo, hi)
;   +10 n_terms  +11.. n_terms x dw flag (bit 15 set = flag must be CLEAR)
; Stack discipline: exactly one outstanding push (the record start) on every
; path into .next / .hit.
CustomGateInsert:
    ld e, $00                           ; E = 0: no insertion
    ld a, [wGateID]
    inc a
    ld b, a                             ; B = gate+1 (0 = "no dive")
    ld a, [wCurrentFloor]
    or a
    jr z, .newDive                      ; first floor of a dive
    ld a, [wGateDiveGate]
    cp b
    jr z, .scan                         ; same dive continues
.newDive:
    ld a, b
    ld [wGateDiveGate], a
    xor a
    ld [wGateDiveMask], a
.scan:
    ld hl, GateInsertTable
.rec:
    ld a, [hl]
    cp $FF
    jp z, .none                         ; end of table
    push hl                             ; [sp] = record start
    ld b, a
    ld a, [wGateID]
    cp b
    jp nz, .next                        ; other gate
    inc hl
    ld a, [wCurrentFloor]
    cp [hl]
    jp c, .next                         ; floor < lo
    inc hl
    ld b, a
    ld a, [hl]
    cp b
    jp c, .next                         ; hi < floor
    inc hl
    inc hl                              ; +4 once bit
    ld a, [wGateDiveMask]
    and [hl]
    jp nz, .next                        ; already served this dive
    ld de, $0006
    add hl, de                          ; +10 n_terms
    ld a, [hl+]
    or a
    jr z, .termsOk
    ld d, a                             ; D = terms left
.term:
    ld c, [hl]
    inc hl
    ld b, [hl]
    inc hl
    push hl
    ld a, b
    and $80
    ld e, a                             ; E bit 7 = term wants the flag CLEAR
    res 7, b
    call TestEventFlag                  ; Z = clear, NZ = set (clobbers A, HL)
    pop hl
    jr z, .isClear
    bit 7, e
    jp nz, .next                        ; set, but must be clear
    jr .termNext
.isClear:
    bit 7, e
    jp z, .next                         ; clear, but must be set
.termNext:
    dec d
    jr nz, .term
.termsOk:
    pop hl
    push hl                             ; HL = record start (kept on stack)
    inc hl
    inc hl
    inc hl                              ; +3 chance
    ld a, [hl]
    cp 100
    jr nc, .hit                         ; 100% = always, no RNG drawn
    ld c, a                             ; C = chance (Div16x8To16 keeps BC)
    call GenerateRNG
    ld a, [wRNG1]                       ; the SelectFloorType roll:
    ld l, a                             ;   RNG16 mod 100
    ld a, [wRNG2]
    ld h, a
    ld a, 100
    call Div16x8To16                    ; A = roll 0-99 (clobbers DE, HL)
    cp c
    jp nc, .next                        ; roll >= chance: miss
.hit:
    pop hl                              ; record start
    inc hl
    inc hl
    inc hl
    inc hl                              ; +4 once bit
    ld a, [wGateDiveMask]
    or [hl]
    ld [wGateDiveMask], a
    inc hl                              ; +5 mapID
    ld a, [hl+]
    ld [wMapID], a
    ld a, [hl+]
    ld [wWarpSpawnXLo], a
    ld a, [hl+]
    ld [wWarpSpawnXHi], a
    ld a, [hl+]
    ld [wWarpSpawnYLo], a
    ld a, [hl]
    ld [wWarpSpawnYHi], a
    xor a
    ld [wInGateworld], a                ; render as a fixed room (the
    ld e, $01                           ;   special-room contract, $16:$5D0D)
    ret
.next:
    pop hl                              ; record start
    push hl
    ld de, $000A
    add hl, de
    ld a, [hl]                          ; n_terms
    pop hl
    add a
    add 11                              ; record size = 11 + 2*n_terms
    ld e, a
    ld d, $00
    add hl, de
    jp .rec
.none:
    ld e, $00                           ; E = 0 (E held record sizes above)
    ret

; -----------------------------------------------------------------------------
; Entry 5: CustomRoomFlags — E := CustomRoomFlagsTable[wMapID-$6B] (S100)
; -----------------------------------------------------------------------------
CustomRoomFlags:
    ld e, $00
    ld a, [wMapID]
    sub CUSTOM_ROOM_START
    ret c                               ; vanilla room: no flags
    cp ROOMFLAGS_TABLE_LEN
    ret nc                              ; out of table range: no flags
    ld hl, CustomRoomFlagsTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld e, [hl]
    ret

; -----------------------------------------------------------------------------
; Entry 6: CustomBGMStart — start a project song's own channels (S116)
; -----------------------------------------------------------------------------
CustomBGMStart:
    ld a, [$de24]                       ; the requested id (>= $9E)
    sub $9e
    ld hl, CustomBGMChanTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    or a
    jr nz, .go
    ld a, $03                           ; not a song's first id: 3, as before S116
.go:
    ld b, a
.loop:
    call AudioProcess                   ; one channel; keeps BC/DE/HL, ++[$de24]
    dec b
    jr nz, .loop
    ret

; -----------------------------------------------------------------------------
; Entry 7: BattleBGMResolve — E := the song this battle starts with (S116)
; -----------------------------------------------------------------------------
BattleBGMResolve:
    ld e, $27                           ; vanilla: the battle theme
    ld a, [wMapID]
    cp $5d
    jr nz, .vanillaDone
    ld a, [wArenaStarryBattle]
    cp $02
    jr nz, .vanillaDone
    ld e, $2b                           ; vanilla: the Starry Night final
.vanillaDone:
    ld a, [$c86c]                       ; a link battle: always the vanilla pick
    or a
    ret nz
    ld hl, BattleFightBGMTable          ; 1. this fight: [EID lo, EID hi, song]
.fight:
    ld a, [hl+]
    ld c, a
    ld a, [hl+]
    ld b, a
    and c
    inc a
    jr z, .arena                        ; $FF $FF: end of the table
    ld a, [$da03]                       ; the first enemy's EID (lo)
    cp c
    jr nz, .nextFight
    ld a, [$da04]                       ; (hi)
    cp b
    jr nz, .nextFight
    ld a, [hl]
    jr .use
.nextFight:
    inc hl
    jr .fight
.arena:                                 ; 2. the arena battle room
    ld a, [wMapID]
    cp $5d
    jr nz, .room
    ld a, e
    cp $2b
    jr nz, .arenaMatch
    ld a, [BattleBGMSettings + 3]       ; the Starry Night final
    or a
    jr nz, .use
.arenaMatch:
    ld a, [BattleBGMSettings + 2]       ; any other arena battle
    or a
    jr nz, .use
.room:                                  ; 3. the room
    ld a, [wInGateworld]
    or a
    jr nz, .gate                        ; maze floor
    ld a, [wMapID]
    cp $80
    jr nc, .type
    ld hl, CustomRoomBattleBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    cp $ff
    jr z, .gate                         ; a gate room: the dive's gate
    or a
    jr nz, .use
    ld a, [wMapID]                      ; the special rooms (only in dives)
    cp $50
    jr c, .type
    cp $52
    jr z, .type
    cp $5d
    jr nc, .type
.gate:                                  ; 4. the gate being dived
    ld a, [wGateID]
    cp GATE_BGM_LEN
    jr nc, .type
    ld hl, CustomGateBattleBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    or a
    jr nz, .use
.type:                                  ; 5. boss fights ($5A/$5B: mode 3)
    ld a, [$da09]
    cp $03
    jr nz, .normal
    ld a, [BattleBGMSettings + 1]
    or a
    jr nz, .use
.normal:                                ; 6. every battle vanilla plays $27 for
    ld a, e
    cp $27
    ret nz
    ld a, [BattleBGMSettings]
    or a
    ret z
.use:
    ld e, a
    ret

; -----------------------------------------------------------------------------
; Custom26DDTable — 8-byte $26DD-style records for mapIDs $70+,
; indexed (mapID-$70): [step_id, gfx_bank, w_lo, w_hi, h_lo,
;  h_hi, threshold, pad] (generated by build_project.py).
; -----------------------------------------------------------------------------
Custom26DDTable:
    db $0D, $28, $A0, $00, $80, $00, $30, $00  ; $70
    db $0D, $28, $A0, $00, $80, $00, $30, $00  ; $71
    db $0E, $29, $E0, $01, $80, $00, $5A, $00  ; $72
    db $0D, $28, $A0, $00, $00, $01, $30, $00  ; $73

; -----------------------------------------------------------------------------
; RoomEncTable — 3 bytes/room [enabled, gate_id, floor], indexed
; (mapID-$6B). enabled=0 -> room is encounter-silent. (generated)
; -----------------------------------------------------------------------------
ENC_TABLE_LEN EQU 9
RoomEncTable:
    db $01, $00, $01  ; $6B — enabled, gate 0, floor 1
    db $00, $00, $00  ; $6C — disabled
    db $00, $00, $00  ; $6D — disabled
    db $00, $00, $00  ; $6E — disabled
    db $00, $00, $00  ; $6F — disabled
    db $01, $00, $01  ; $70 — enabled, gate 0, floor 1
    db $00, $00, $00  ; $71 — disabled
    db $00, $00, $00  ; $72 — disabled
    db $01, $00, $01  ; $73 — enabled, gate 0, floor 1

; -----------------------------------------------------------------------------
; CustomAnimSrcTable — 1 byte/room, indexed (mapID-$6B): the map ID
; whose bank-$01 room-animation handler runs for this room ($6B =
; none). Read by entry 3 CustomAnimSource (S99, P3.3e). (generated)
; -----------------------------------------------------------------------------
ANIM_TABLE_LEN EQU 9
CustomAnimSrcTable:
    db $6B  ; $6B — none
    db $6B  ; $6C — none
    db $6B  ; $6D — none
    db $6B  ; $6E — placeholder
    db $6B  ; $6F — placeholder
    db $6B  ; $70 — none
    db $6B  ; $71 — none
    db $06  ; $72 — source: map $06
    db $6B  ; $73 — none

; -----------------------------------------------------------------------------
; GateInsertTable — custom rooms served on gate floors (S100, P3.7b).
; [gate, floor_lo, floor_hi (0-based), chance, once_bit, mapID,
;  spawn_x lo/hi, spawn_y lo/hi, n_terms] + n_terms x dw flag
; (bit 15 = must be CLEAR); $FF ends. Read by entry 4. (generated)
; -----------------------------------------------------------------------------
GateInsertTable:
    db $01, $01, $02, $32, $01, $6D, $48, $00, $68, $00, $00  ; gate 1 floors 2-3 50% -> gate_rotation ($6D) once/dive
    db $FF

; -----------------------------------------------------------------------------
; CustomRoomFlagsTable — 1 byte/room, indexed (mapID-$6B): bit 0 =
; saving NOT allowed (custom.rooms[].can_save false). Read by entry
; 5 CustomRoomFlags for the bank $07 save ladder (S100). (generated)
; -----------------------------------------------------------------------------
ROOMFLAGS_TABLE_LEN EQU 9
CustomRoomFlagsTable:
    db $00  ; $6B — saving allowed
    db $00  ; $6C — saving allowed
    db $00  ; $6D — saving allowed
    db $00  ; $6E — saving allowed
    db $00  ; $6F — saving allowed
    db $00  ; $70 — saving allowed
    db $00  ; $71 — saving allowed
    db $00  ; $72 — saving allowed
    db $00  ; $73 — saving allowed

; -----------------------------------------------------------------------------
; CustomRoomBGMTable — 128 entries indexed by wMapID (S64, M3b).
; Read by entry 2 (CustomRoomBGMResolve, template head) for the
; rewritten LoadNewBGMIdIntoA (patches/bank_001.asm). 0 = no
; assignment -> vanilla derivation; nonzero = the room's default
; BGM id (survives save/reload: the load path re-derives here);
; $FF = a gate room with no song: the dive's gate song (S116).
; Covers VANILLA and custom rooms alike; gate floors
; (wInGateworld!=0) are excluded by the resolver. (generated)
; -----------------------------------------------------------------------------
CustomRoomBGMTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $00-$0F
    db $00, $00, $A4, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $10-$1F: $12=dq6_town1
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $20-$2F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $30-$3F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $40-$4F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $50-$5F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $A1, $00, $00, $00, $00  ; mapIDs $60-$6F: $6B=dwm2_bgm07
    db $00, $A7, $1E, $A1, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $70-$7F: $71=dwm2_bgm10, $72=$1E, $73=dwm2_bgm07

; -----------------------------------------------------------------------------
; CustomBGMChanTable — channel count of the project song starting at
; each id $9E-$FC (0 = no song starts here: the old
; 3-channel default). Read by entry 6 CustomBGMStart (S116). (generated)
; -----------------------------------------------------------------------------
CustomBGMChanTable:
    db $03, $00, $00, $03, $00, $00, $03, $00, $00, $03, $00, $00, $00, $00, $00, $00  ; ids $9E-$AD $9E:dwm2_bgm06_well=3ch $A1:dwm2_bgm07=3ch $A4:dq6_town1=3ch $A7:dwm2_bgm10=3ch
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; ids $AE-$BD
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; ids $BE-$CD
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; ids $CE-$DD
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; ids $DE-$ED
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; ids $EE-$FC

; -----------------------------------------------------------------------------
; CustomGateBGMTable / CustomGateBattleBGMTable — per gate 0-95 (wGateID):
; the song of its floors / of its battles, 0 = vanilla. Read by entries
; 2 and 7 (S116). (generated)
; -----------------------------------------------------------------------------
GATE_BGM_LEN EQU 96
CustomGateBGMTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 0-15
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 16-31
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 32-47
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 48-63
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 64-79
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 80-95
CustomGateBattleBGMTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 0-15
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 16-31
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 32-47
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 48-63
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 64-79
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; gates 80-95

; -----------------------------------------------------------------------------
; CustomRoomBattleBGMTable — 128 entries by wMapID: the song of battles
; in that room (0 = not set, $FF = follow the gate being dived). Read by
; entry 7 BattleBGMResolve (S116). (generated)
; -----------------------------------------------------------------------------
CustomRoomBattleBGMTable:
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $00-$0F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $10-$1F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $20-$2F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $30-$3F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $40-$4F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $50-$5F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $60-$6F
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $70-$7F

; -----------------------------------------------------------------------------
; BattleBGMSettings — [normal, boss, arena, Starry final] (0 = vanilla:
; $27 / $27 / $27 / $2B). BattleFightBGMTable — [EID lo, EID hi, song]
; per fight (the first enemy's row, $DA03), $FF $FF ends. (generated)
; -----------------------------------------------------------------------------
BattleBGMSettings:
    db $00, $00, $00, $00  ; normal, boss, arena, Starry final: 
BattleFightBGMTable:
    db $FF, $FF

