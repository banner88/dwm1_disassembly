; =============================================================================
; BANK $74 — PROJECT SONGS: the song directory + SongStart (S147; compiler-owned,
; patches/bank_074.asm; ROADMAP ARC CAP5 "songs at campaign scale")
; =============================================================================
; Until S147 a project song took ONE SOUND ID PER CHANNEL ($9E-$FC = 95 ids,
; ~31 songs) and its records + streams lived in banks $74 / $75 only (2 x
; 16,000 B — the 11th DWM2-size song stopped the build). Since S147:
;
;   * ONE id per song: ids $9E-$FC = 95 songs. The rewritten ROM0 InitBGM
;     (patches/bank_000.asm) far-calls bank $71 entry 6 CustomBGMStart for an
;     id >= $9E, which forwards here (entry 0, HL=$7400) — inside InitBGM's di,
;     after InitAudioSystem killed every channel, [$de24] = the id.
;   * SongDirectory[id - $9E] (generated) = the song's record: db channels,
;     db the song's BANK ($74, $75 or a bank $80-$FF), then per channel
;     [db dummy id, db state slot, dw stream]. 0 = no song: silence.
;   * Per channel SongStart runs the game's own ROM0 AudioProcess on a DUMMY
;     record (SongRecords below: ids $9E-$B5 = one per (state slot, hw
;     channel) pair — the slot and hw byte the channel needs), so the channel
;     state is initialised exactly as the engine always does it (the NR51
;     mask, +9 := $FF, positions 0, the record's hw byte at +1), then
;     overwrites the state's stream pointer (+2/+3) and DATA BANK (+4) with the
;     real ones. The per-frame driver (ROM0 SaveBankAndAudioState) switches to
;     state +4 before every tick, so a stream may sit in ANY bank; positions are
;     pair indices from the stream base (SOUND_SYSTEM §4), so streams are
;     relocatable. AudioProcess keeps BC/DE/HL and returns to this bank (it
;     saves [$4000]).
;   * AudioMasterTableExt row 4 (ROM0 $3FE8, region rom0_audio_master) =
;     [$9E, SongRecords, $74]: ids $9E-$FC resolve to SongRecords for EVERY
;     request path — a sound-effect request (LoadSE) with an id >= $9E plays
;     silence on a slot instead of a stray record. The S116 row 5 (bank $75)
;     is gone: bank $75 and the banks $80+ hold streams only.
;
; Data (generated below the SONG DATA marker): SongDirectory (95 dw), the song
; records (2 + 4 x channels B each, every song's — wherever its streams are),
; then the streams the plan keeps in this bank (editor2/core/music.py).
; =============================================================================

SECTION "ROM Bank $074", ROMX[$4000], BANK[$74]

    db $74                              ; bank self-ID at $4000

; rst-$10 entry table at $4001
    dw SongStart                        ; entry 0  (HL=$7400)

SONG_IDS EQU 95                         ; ids $9E-$FC

; The dummy records AudioProcess reads for ids $9E-$FC (master-table row 4):
; [state slot, hw channel, stream lo, stream hi] — 4 B each.
SongRecords:
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $9E: state slot $00 (sound-effect slot 1), hw channel 0
    db $00, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $9F: state slot $00 (sound-effect slot 1), hw channel 1
    db $00, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $A0: state slot $00 (sound-effect slot 1), hw channel 2
    db $00, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $A1: state slot $00 (sound-effect slot 1), hw channel 3
    db $1A, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $A2: state slot $1A (sound-effect slot 2), hw channel 0
    db $1A, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $A3: state slot $1A (sound-effect slot 2), hw channel 1
    db $1A, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $A4: state slot $1A (sound-effect slot 2), hw channel 2
    db $1A, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $A5: state slot $1A (sound-effect slot 2), hw channel 3
    db $34, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $A6: state slot $34 (music pulse 1), hw channel 0
    db $34, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $A7: state slot $34 (music pulse 1), hw channel 1
    db $34, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $A8: state slot $34 (music pulse 1), hw channel 2
    db $34, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $A9: state slot $34 (music pulse 1), hw channel 3
    db $4E, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $AA: state slot $4E (music pulse 2), hw channel 0
    db $4E, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $AB: state slot $4E (music pulse 2), hw channel 1
    db $4E, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $AC: state slot $4E (music pulse 2), hw channel 2
    db $4E, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $AD: state slot $4E (music pulse 2), hw channel 3
    db $68, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $AE: state slot $68 (music wave), hw channel 0
    db $68, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $AF: state slot $68 (music wave), hw channel 1
    db $68, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $B0: state slot $68 (music wave), hw channel 2
    db $68, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $B1: state slot $68 (music wave), hw channel 3
    db $82, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $B2: state slot $82 (music noise), hw channel 0
    db $82, $01, LOW(SongSilent), HIGH(SongSilent)   ; id $B3: state slot $82 (music noise), hw channel 1
    db $82, $02, LOW(SongSilent), HIGH(SongSilent)   ; id $B4: state slot $82 (music noise), hw channel 2
    db $82, $03, LOW(SongSilent), HIGH(SongSilent)   ; id $B5: state slot $82 (music noise), hw channel 3
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $B6: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $B7: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $B8: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $B9: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BA: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BB: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BC: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BD: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BE: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $BF: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C0: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C1: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C2: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C3: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C4: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C5: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C6: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C7: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C8: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $C9: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CA: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CB: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CC: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CD: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CE: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $CF: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D0: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D1: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D2: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D3: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D4: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D5: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D6: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D7: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D8: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $D9: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DA: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DB: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DC: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DD: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DE: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $DF: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E0: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E1: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E2: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E3: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E4: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E5: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E6: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E7: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E8: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $E9: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $EA: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $EB: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $EC: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $ED: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $EE: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $EF: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F0: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F1: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F2: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F3: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F4: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F5: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F6: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F7: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F8: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $F9: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $FA: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $FB: unused (silence on slot $00)
    db $00, $00, LOW(SongSilent), HIGH(SongSilent)   ; id $FC: unused (silence on slot $00)

    ASSERT SongRecords == $4003, "AudioMasterTableExt row 4 (music.py) points at $74:$4003"

; The dummy records' stream: a zero header + end. Only a stray sound-effect
; request ever plays it; SongStart replaces the pointer before any tick.
SongSilent:
    db $00, $00, $00, $00, $FF, $00

; -----------------------------------------------------------------------------
; Entry 0: SongStart — start the project song [$de24] (S147)
; -----------------------------------------------------------------------------
SongStart:
    ld a, [$de24]                       ; the requested id (>= $9E)
    sub $9e
    ret c                               ; (never: InitBGM tested it)
    cp SONG_IDS
    ret nc                              ; $FD / $FE: no song
    add a                               ; x 2 (< 256)
    ld l, a
    ld h, $00
    ld de, SongDirectory
    add hl, de
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = the song's record
    or h
    ret z                               ; no song at this id: silence
    ld a, [hl+]
    ld b, a                             ; B = channels (1-6)
    ld a, [hl+]
    ld c, a                             ; C = the song's bank
.channel:
    ld a, [hl+]                         ; the dummy id of this channel's (slot, hw)
    ld [$de24], a
    call AudioProcess                   ; ROM0: init the slot from the dummy record
    ld a, [hl+]                         ; the state slot ($00/$1A/$34/$4E/$68/$82)
    push hl
    ld e, a
    ld d, $00
    ld hl, $dd82                        ; channel state +2 (the stream pointer)
    add hl, de
    pop de                              ; DE -> the stream word
    ld a, [de]
    inc de
    ld [hl+], a                         ; +2 stream lo
    ld a, [de]
    inc de
    ld [hl+], a                         ; +3 stream hi
    ld [hl], c                          ; +4 the data bank
    ld h, d
    ld l, e                             ; HL -> the next channel
    dec b
    jr nz, .channel
    ret

; -----------------------------------------------------------------------------
; SONG DATA (generated)
; -----------------------------------------------------------------------------
