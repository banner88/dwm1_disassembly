; =============================================================================
; BANK $64 — Custom Room $6B layout + attr (Gate of Beginning: sandy island)
;   graphics = gfx-ID $280D (bank $28 step $0D); BG palette = real gate (slots 0-3).
;   Per-position palette (attr): floor/dune/pit = pal0 (sand), ocean = pal1 (blue),
;   tree = pal3 (green). Objects: TREE metatile $34-$37 (pal3), DUNE $38-$3B (pal0),
;   PIT $3C-$3F. Ocean wall ($08) borders all edges. 2 vertical screens.
;   Edge exits are marked with a walkable STAIRCASE ($3C-$3F): S0 metatile (3,1)
;   and S1 metatile (3,7), so the room exits are visible (not invisible walk-on
;   triggers). Shared layout: $6C/$6D/$70 reuse these entries, so the staircase
;   shows in them too, but only warps where an exit record exists.
; Regenerate with: python3 tools/build_gate_room.py   (see GATE_GENERATION.md §7.2)
; Engine reads via DecompressTileLayout ($1627): D=bank($64), E=entry index.
; =============================================================================
SECTION "ROM Bank $064", ROMX[$4000], BANK[$64]
    db $64  ; bank self-ID
    dw CustomLayout_Room6B_S0
    dw CustomAttr_Room6B_S0
    dw CustomLayout_Room6B_S1
    dw CustomAttr_Room6B_S1
    ; (Pillar A: $6C reuses these same entries 0/2 layout + 1/3 attr as $6B;
    ;  its distinct look comes purely from CustomRoomPalPtr[1] = dusk palette.)
CustomLayout_Room6B_S0:  ; top screen (LZSS)
    db $00, $02, $00, $08, $08, $08, $08, $00, $00, $00, $00, $00, $04, $00, $00, $00
    db $FF, $FF, $FF, $FF, $00, $14, $00, $00, $14, $00, $08, $33, $33, $33, $33, $00
    db $21, $00, $00, $21, $04, $33, $33, $00, $13, $0F, $00, $3C, $3D, $00, $28, $0F
    db $08, $34, $35, $33, $3E, $3F, $00, $28, $0F, $08, $36, $37, $00, $21, $07, $34
    db $35, $00, $32, $0F, $01, $00, $21, $06, $36, $37, $00, $92, $0F, $05, $00, $46
    db $05, $00, $13, $0F, $04, $00, $66, $05, $00, $13, $0F, $20, $38, $39, $00, $28
    db $0F, $0B, $3A, $3B, $00, $28, $0F, $0B, $00, $26, $0F, $0D, $00, $26, $0F, $0D
    db $00, $66, $1F, $2D, $00, $26, $0F, $07

CustomAttr_Room6B_S0:  ; per-position sand/ocean/tree (LZSS)
    db $00, $01, $02, $11, $11, $11, $11, $02, $00, $00, $11, $11, $00, $00, $00, $00
    db $00, $00, $10, $02, $0A, $02, $00, $00, $01, $02, $0A, $0C, $02, $0A, $03, $03
    db $30, $02, $23, $0C, $02, $0A, $01, $33, $02, $19, $0B, $02, $48, $0C, $02, $18
    db $0F, $06, $02, $11, $0F, $0D, $02, $61, $0F, $2D, $02, $11, $0F, $0C

CustomLayout_Room6B_S1:  ; bottom screen (LZSS)
    db $00, $02, $00, $08, $33, $33, $33, $33, $00, $01, $00, $00, $01, $04, $33, $33
    db $08, $FF, $FF, $FF, $FF, $00, $14, $00, $00, $14, $00, $00, $00, $0F, $0D, $00
    db $00, $0B, $34, $35, $00, $11, $0F, $0B, $36, $37, $00, $11, $0F, $00, $38, $39
    db $00, $06, $0F, $0B, $3A, $3B, $00, $06, $0F, $36, $00, $0F, $0F, $28, $3C, $3D
    db $00, $0C, $0F, $0B, $3E, $3F, $00, $AC, $0F, $67, $00, $2A, $15, $00, $0F, $0E
    db $08, $08, $08, $08, $08, $3E, $3F, $00, $E0, $12, $00, $E0, $12, $00, $14, $08

CustomAttr_Room6B_S1:  ; per-position sand/ocean/tree (LZSS)
    db $00, $01, $02, $10, $00, $00, $00, $00, $02, $01, $00, $01, $02, $01, $02, $02
    db $00, $0C, $02, $00, $03, $03, $30, $02, $19, $0C, $02, $09, $0F, $0B, $02, $07
    db $0F, $0D, $02, $47, $0F, $1D, $02, $47, $0F, $36, $11, $11, $11, $02, $EF, $00
    db $02, $F0, $00, $02, $01, $01
