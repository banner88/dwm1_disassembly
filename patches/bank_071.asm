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
;     not room-meaningful there; gate/event music assignment is a future item.
; =============================================================================

SECTION "ROM Bank $071", ROMX[$4000], BANK[$71]

    db $71                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw CopyCustomRoomRecord             ; entry 0  (HL=$7100)
    dw CustomEncResolve                 ; entry 1  (HL=$7101)
    dw CustomRoomBGMResolve             ; entry 2  (HL=$7102, S64 M3b)

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
    ld [wGateID], a
    ld a, [hl]                          ; [2] floor
    ld [wCurrentFloor], a
    ld a, $01
    ld [wRoomEncFlag], a
    ret
.disabled:
    xor a
    ld [wRoomEncFlag], a
    ret

; -----------------------------------------------------------------------------
; Entry 2: CustomRoomBGMResolve — E := assigned room BGM id, or 0 (S64, M3b)
; -----------------------------------------------------------------------------
CustomRoomBGMResolve:
    ld e, $00                           ; default: no assignment
    ld a, [wInGateworld]
    or a
    ret nz                              ; gate floors: vanilla floor music
    ld a, [wMapID]
    cp $80
    ret nc                              ; out of table range
    ld hl, CustomRoomBGMTable
    add l
    ld l, a
    adc h
    sub l
    ld h, a
    ld a, [hl]
    ld e, a                             ; 0 entries fall through as "none"
    ret

; -----------------------------------------------------------------------------
; Custom26DDTable — 8-byte $26DD-style records for mapIDs $70+,
; indexed (mapID-$70): [step_id, gfx_bank, w_lo, w_hi, h_lo,
;  h_hi, threshold, pad] (generated by build_project.py).
; -----------------------------------------------------------------------------
Custom26DDTable:
    db $0D, $28, $A0, $00, $80, $00, $30, $00  ; $70

; -----------------------------------------------------------------------------
; RoomEncTable — 3 bytes/room [enabled, gate_id, floor], indexed
; (mapID-$6B). enabled=0 -> room is encounter-silent. (generated)
; -----------------------------------------------------------------------------
ENC_TABLE_LEN EQU 6
RoomEncTable:
    db $01, $00, $01  ; $6B — enabled, gate 0, floor 1
    db $00, $00, $00  ; $6C — disabled
    db $00, $00, $00  ; $6D — disabled
    db $00, $00, $00  ; $6E — disabled
    db $00, $00, $00  ; $6F — disabled
    db $01, $00, $01  ; $70 — enabled, gate 0, floor 1

; -----------------------------------------------------------------------------
; CustomRoomBGMTable — 128 entries indexed by wMapID (S64, M3b).
; Read by entry 2 (CustomRoomBGMResolve, template head) for the
; rewritten LoadNewBGMIdIntoA (patches/bank_001.asm). 0 = no
; assignment -> vanilla derivation; nonzero = the room's default
; BGM id (survives save/reload: the load path re-derives here).
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
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00  ; mapIDs $70-$7F
