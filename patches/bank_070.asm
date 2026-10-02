; =============================================================================
; BANK $70 — the tile sheets of the project's NEW battle animations (S112;
; compiler-generated from custom.animations, PROJECT_COMPILER §2.28): one LZ
; stream per animation (the tiles its frames draw, gathered from the stock
; sheets), gfx id $70xx, decoded to $8000 by bank $50 AnimLoadFork50 /
; the Effect debugger. The last stream = CustomAnimNone's (one empty tile).
; =============================================================================
SECTION "ROM Bank $070", ROMX[$4000], BANK[$70]
    db $70
CustomAnimSheetPtrs:
    dw CustomAnimSheet0
CustomAnimSheet0:   ; 1 tiles, 13 B
    db $10, $00, $01, $00, $00, $00, $00, $01, $00, $00, $01, $00, $04
