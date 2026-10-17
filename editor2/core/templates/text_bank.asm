; =============================================================================
; S150 (ROADMAP P3.6 / Phase F T-author) — EDITED GAME TEXT: a text bank's copier.
; Pasted into EVERY text bank (the home bank too), {T} = the bank's suffix;
; entry 1 of each text bank. TEXT_SYSTEM "Edited game text (S150)".
; In: DE = an edited text in THIS bank. Copies it, its closing $F0 included, to
; [$C837] — RunTextHandler's buffer (the copy path: names the game copies into
; a buffer before it prints them, e.g. bank $41's names through ROM0 $0981).
; Clobbers A / DE / HL.
; =============================================================================
TextOvrCopy{T}:
    ld a, [$c837]
    ld l, a
    ld a, [$c838]
    ld h, a
.loop:
    ld a, [de]
    ld [hl+], a
    inc de
    cp $f0
    jr nz, .loop
    ret
