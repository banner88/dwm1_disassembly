#!/usr/bin/env python3
"""annotate_ending_5f.py — S153 (ROADMAP E5): labels + comments for bank $5F's
intro / title (game mode 0, sub-mode 0: entries 2 / 3) and the ENDING's credits +
"TO BE CONTINUED" (game mode 4: entries 0 / 1), decoded S153 (PyBoy-measured on
the original ROM; ARCHITECTURE "Game modes", DATA_STRUCTURES "The title screen and
the ending (S153)").

Zero byte impact: renames, comments, and misassembled data turned into the same
bytes (`dw` dispatch tables, `db` data). Applied to BOTH trees — disassembly/
bank_05f.asm (the clean tree: the rebuild must stay 1ca6579…) and patches/
bank_05f.asm (lines 1-1589 are identical in both). Idempotent: a tree already
annotated is left alone.

    annotate_ending_5f.py [--check]     # --check: report, change nothing
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = ['disassembly/bank_05f.asm', 'patches/bank_05f.asm']
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')
MARK = '; [S153] ENDING / TITLE ANNOTATION'


def rom_bytes(a, n):
    rom = open(ROM, 'rb').read()
    o = 0x5F * 0x4000 + a - 0x4000
    return rom[o:o + n]


def db_lines(a, n, per=16, note=None):
    b = rom_bytes(a, n)
    out = []
    for k in range(0, n, per):
        chunk = b[k:k + per]
        out.append('    db ' + ', '.join(f'${x:02X}' for x in chunk))
    return out


# (old block, new block) — the old block must occur exactly once
def edits():
    E = []

    def ed(old, new):
        E.append((old, new))

    ed("""    ; Cross-bank dispatch table (11 entries)
    ; Called via: ld hl, $5FXX / rst $10
    dw $4017                          ; Entry 0
    dw $40F7                          ; Entry 1
    dw $441C                          ; Entry 2
    dw $4619                          ; Entry 3
""", f"""    ; Cross-bank dispatch table (11 entries)
    ; Called via: ld hl, $5FXX / rst $10
    {MARK} (S153, ROADMAP E5; tools/annotate_ending_5f.py):
    ; entries 0 / 1 = game mode 4 (the ENDING: the credits, "TO BE CONTINUED"),
    ; entries 2 / 3 = game mode 0 sub-mode 0 (the intro logos, the monster run,
    ; the TITLE screen) — init / tick pairs called by the ROM0 mode tables
    ; ($030F / $050F) and bank $15 entry 0 (`ld hl, $5f02`). ARCHITECTURE "Game
    ; modes", DATA_STRUCTURES "The title screen and the ending (S153)".
    dw EndingModeInit                 ; Entry 0 ($4017) mode 4 init
    dw EndingModeTick                 ; Entry 1 ($40F7) mode 4 tick
    dw IntroStageInit                 ; Entry 2 ($441C) mode 0 sub 0 init (the stage [$C88C])
    dw IntroStageTick                 ; Entry 3 ($4619) mode 0 sub 0 tick
""")

    ed("""; --- Dispatch entry 0 ($4017) ---
DispatchEntry_5F_0:
""", """; --- Dispatch entry 0 ($4017) ---
; EndingModeInit — game mode 4's INIT (S153). Entered from a script: `write_ram
; $C88A 4 / write_ram $C88B sub / op $3E` (the intro bedroom's step-on script 13 /
; 14 → sub 0 = the credits; its entry script after them → sub 1 = "TO BE
; CONTINUED"). Clears the tilemap to tile $E0, then [$C88B]: 0 = CreditsInit,
; 1 = ContinueInit.
EndingModeInit:
DispatchEntry_5F_0:
""")

    ed("""    ld a, [$c88b]
    rst $00
    add hl, sp
    ld b, b
    sub l
    ld b, b
    ld hl, $8000
    ld bc, $0c00
    call WriteFldUI_40eb
""", """    ld a, [$c88b]
    rst $00
    dw CreditsInit                    ; sub 0 ($4039)
    dw ContinueInit                   ; sub 1 ($4095)

; CreditsInit ($4039): the credits' screen — blank tiles $8000-$97FF, the font
; ($2E00 → $8D00, box tiles $1202 → $8B00), the page layout tilemap
; CreditsPageTilemap ($66B3, 20 x 18 tiles: the ROLE grid = tiles $00-$27 (20 x
; 2, rows 2-3), the NAMES grid = tiles $26-$A9 (11 x 12, rows 5-16, each grid row
; on its own screen row; rows 7 / 9 / 11 show 9 / 10 / 9 of their 11 cells), the
; MONSTER = tiles $AA-$CD (6 x 6, palette 4)); page 0 drawn ($C0D9 = 0); SetGBCPalette
; $FC; the credits song **$21** (`ld a, $21` — patched builds: region credits_song).
CreditsInit:
    ld hl, $8000
    ld bc, $0c00
    call WriteFldUI_40eb
""")

    ed("""    ld a, $fc
    call SetGBCPalette
    ld a, $21
    call SetBGM
""", """    ld a, $fc
    call SetGBCPalette
    ld a, $21                       ; the credits' song (S153)
    call SetBGM
""")

    ed("""    jp EnableLCDAndInterrupts


    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld hl, $8800
    ld bc, $0800
    call WriteFldUI_40eb
    ld de, $42cf
""", """    jp EnableLCDAndInterrupts


; ContinueInit ($4095): "…TO BE CONTINUED" — blank tiles $8800-$97FF, the box
; ContinueBoxTilemap (20 x 4 at $99A0), the font; the song **$31** (the Starry
; Shrine's theme; `ld a, $31` — patched builds: region continue_song). Its tick
; (ContinueShowText …) shows credits_end row 0, waits for a button, asks text $0256
; ("save?"): YES = SaveGameState (the ending's ONLY save) + $0257, NO = $0258; then
; ContinueRest waits for ever (the player resets; CONTINUE comes back where the
; player stood — the room the script ran in).
ContinueInit:
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld hl, $8800
    ld bc, $0800
    call WriteFldUI_40eb
    ld de, ContinueBoxTilemap
""")

    ed("""    ld a, $fc
    call SetGBCPalette
    ld a, $31
    call SetBGM
""", """    ld a, $fc
    call SetGBCPalette
    ld a, $31                       ; "TO BE CONTINUED"'s song (S153)
    call SetBGM
""")

    ed("""WriteFldUI_40eb:
jr_05f_40eb:
""", """; CreditsBlankTiles ($40EB): HL = VRAM, BC = words: every word $FF, $00 = a blank
; tile in colour 1 (the cream backdrop).
CreditsBlankTiles:
WriteFldUI_40eb:
jr_05f_40eb:
""")

    ed("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88b]
    rst $00
    inc b
    ld b, c
    ld [de], a
    ld b, c
    ld a, [$c0d8]
    rst $00
    jr nz, @+$43

    ld b, b
    ld b, c
    ld d, l
    ld b, c
    ld h, e
    ld b, c
    ld a, b
    ld b, c
    ld a, [$c0d8]
    rst $00
    jp c, $ed41

    ld b, c
    or $41
    db $10
    ld b, d
    ld b, h
    ld b, d
    ld hl, $c0da
""", """    ret


; --- Dispatch entry 1 ($40F7) --- EndingModeTick: mode 4's TICK by [$C88B].
; The state machines run in [$C0D8] (cleared by the inits: $C0D8-$C0FF).
EndingModeTick:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c88b]
    rst $00
    dw CreditsTick                    ; sub 0 ($4104)
    dw ContinueTick                   ; sub 1 ($4112)
; The credits: [$C0D9] = the page, [$C0DA] / [$C0DB] = frames / seconds.
CreditsTick:
    ld a, [$c0d8]
    rst $00
    dw CreditsWaitPage                ; 0 ($4120) the page shows 5 s
    dw CreditsNextPage                ; 1 ($4140) next page: its texts + monster
    dw CreditsPageFadeIn              ; 2 ($4155)
    dw CreditsLoop                    ; 3 ($4163) more pages, or the end
    dw CreditsDone                    ; 4 ($4178) 5 s, then back to the field
ContinueTick:
    ld a, [$c0d8]
    rst $00
    dw ContinueShowText               ; 0 ($41DA) credits_end row 0 (bank $4C mode 7)
    dw ContinueReady                  ; 1 ($41ED)
    dw ContinueWaitButton             ; 2 ($41F6) a button → "save?" (text $0256)
    dw ContinueSave                   ; 3 ($4210) YES: SaveGameState
    dw ContinueRest                   ; 4 ($4244) for ever (the player resets)

; CreditsWaitPage ($4120): 60 frames x **5** (`cp $05` — patched builds: region
; credits_seconds), then the fade out ($C88F) and the next state.
CreditsWaitPage:
    ld hl, $c0da
""")

    ed("""    cp $05
    ret c

    ld [hl], $00
    ld hl, $c0d8
    inc [hl]
    ld hl, $c88f
    inc [hl]
    ld a, $04
    call SetGBCPalette
    ret


    ld hl, $c0d9
    inc [hl]
    ld a, [hl]
    cp $1a
    call z, $440f
""", """    cp $05                          ; the seconds a page shows (S153)
    ret c

    ld [hl], $00
    ld hl, $c0d8
    inc [hl]
    ld hl, $c88f
    inc [hl]
    ld a, $04
    call SetGBCPalette
    ret


; CreditsNextPage ($4140): page += 1; the LAST page (26 = $1A: `cp $1a` — patched
; builds: region credits_last_a) first draws CreditsCopyrightLayout; then the
; page's role / names texts and monster.
CreditsNextPage:
    ld hl, $c0d9
    inc [hl]
    ld a, [hl]
    cp $1a                          ; the last page's number (S153)
    call z, CreditsCopyrightLayout
""")

    ed("""    ret


    ld hl, $0802
    rst $10
    ld a, $fc
    call SetGBCPalette
    ld hl, $c0d8
    inc [hl]
    ret


    xor a
    ld [$c88f], a
    ld a, [$c0d9]
    cp $1a
    jr z, jr_05f_4173
""", """    ret


CreditsPageFadeIn:
    ld hl, $0802
    rst $10
    ld a, $fc
    call SetGBCPalette
    ld hl, $c0d8
    inc [hl]
    ret


; CreditsLoop ($4163): the last page shown (`cp $1a` — patched builds: region
; credits_last_b) → CreditsDone, else back to CreditsWaitPage.
CreditsLoop:
    xor a
    ld [$c88f], a
    ld a, [$c0d9]
    cp $1a                          ; the last page's number (S153)
    jr z, jr_05f_4173
""")

    ed("""jr_05f_4173:
    ld hl, $c0d8
    inc [hl]
    ret


    ld hl, $c0da
""", """jr_05f_4173:
    ld hl, $c0d8
    inc [hl]
    ret


; CreditsDone ($4178): 5 s more, then the field again: the WARP MAILBOX to the
; intro bedroom ($2F, X $38 / Y $C8 px = cell (3, 12)), wIsPlayerChangingMaps 1,
; HRAM $90 (the hidden player) / the script / the text box off, game mode 1.
; Patched builds: the mailbox block is region credits_after (a project's "Roll
; the credits" step names its own room — bank $79 entry 4 CreditsAfter).
CreditsDone:
    ld hl, $c0da
""")

    ed("""    ld [hl], $00
    ld hl, $002f
    ld a, l
    ld [wWarpGateId], a
""", """    ld [hl], $00
CreditsDoneWarp:                    ; S153: the 38-byte mailbox block (region credits_after)
    ld hl, $002f
    ld a, l
    ld [wWarpGateId], a
""")

    ed("""    ld a, $01
    ld [wIsPlayerChangingMaps], a
    xor a
    ldh [$90], a
""", """    ld a, $01
    ld [wIsPlayerChangingMaps], a
CreditsDoneWarpEnd:
    xor a
    ldh [$90], a
""")

    ed("""    ret


    ld a, $07
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4c02
    rst $10
    ld hl, $c0d8
    inc [hl]
    ret


    xor a
    ld [$c88f], a
    ld hl, $c0d8
    inc [hl]
    ret


    ld a, [wJoypad_current_frame]
""", """    ret


ContinueShowText:                   ; credits_end row 0 into the box (bank $4C entry 2, mode 7)
    ld a, $07
    ld [$c822], a
    ld a, $00
    ld [$c823], a
    ld hl, $4c02
    rst $10
    ld hl, $c0d8
    inc [hl]
    ret


ContinueReady:
    xor a
    ld [$c88f], a
    ld hl, $c0d8
    inc [hl]
    ret


ContinueWaitButton:                 ; any of A / B / SELECT / START → text $0256 + YES / NO
    ld a, [wJoypad_current_frame]
""")

    ed("""    ret


    ld a, [$c825]
    or a
    ret nz

    ld a, [$c83c]
    or a
    ld hl, $0258
""", """    ret


; ContinueSave ($4210): the answer [$C83C]: YES (0) → HRAM $90 / the script off,
; $C8EA := 1, SaveGameState, sound $59, text $0257; NO → text $0258.
ContinueSave:
    ld a, [$c825]
    or a
    ret nz

    ld a, [$c83c]
    or a
    ld hl, $0258
""")

    ed("""    ret


    ld a, [$c825]
    or a
    ret nz

    ret


SaveFldUI_424a:
""", """    ret


ContinueRest:                       ; nothing more: the game waits for a reset
    ld a, [$c825]
    or a
    ret nz

    ret


; CopyTilemapBlock ($424A): DE = tile bytes, HL = BG map, B = width, C = rows.
CopyTilemapBlock:
SaveFldUI_424a:
""")

    ed("""LoadFldUI_4263:
    ld a, [de]
""", """; DrawTilemapStream ($4263): DE = [dw offset] + tile bytes, $D8 = the next row
; (+32 from the row's start), $D9 = the end; written straight to HL + offset (the
; LCD is off). LoadFldUI_4298 = the same through Write_gfx_tile (LCD on).
DrawTilemapStream:
LoadFldUI_4263:
    ld a, [de]
""")
    return E


def data_block():
    """$42CF-$431E: the TBC box tilemap (80 B = 20 x 4), misassembled as code."""
    old = """    ldh [$e0], a
    ld a, [$efef]
    rst $28
"""
    return old


def apply(text):
    if MARK in text:
        return text, []
    errs = []
    for old, new in edits():
        n = text.count(old)
        if n != 1:
            errs.append(f'block occurs {n} x: {old.splitlines()[0][:60]!r} …')
            continue
        text = text.replace(old, new)
    # the TBC box tilemap $42CF-$431E (80 bytes) — between jr_05f_42b5's jr and LoadFldUI_431f
    b = text.find('LoadFldUI_431f:')
    a = text.rfind('    jr jr_05f_42a7\n\n', 0, b)
    if a < 0 or b < 0:
        errs.append('the $42CF data block anchors')
    else:
        a += len('    jr jr_05f_42a7\n\n')
        new = ['; ContinueBoxTilemap ($42CF): "TO BE CONTINUED"\'s box, 20 x 4 tiles '
               '(CopyTilemapBlock to $99A0).',
               'ContinueBoxTilemap:'] + db_lines(0x42CF, 80, per=20) + ['']
        text = text[:a] + '\n'.join(new) + '\n' + text[b:]
    # the monster table $43F4-$440E (27 B) + CreditsCopyrightLayout $440F
    a = text.find("    ld hl, $1706\n    rst $10\n    ret\n\n\n")
    b = text.find("    ld a, [$c88c]\n    rst $00\n    ld l, $44\n")
    if a < 0 or b < 0:
        errs.append('the $43F4 table anchors')
    else:
        a += len("    ld hl, $1706\n    rst $10\n    ret\n\n\n")
        new = ['; CreditsMonsterTable ($43F4): the monster of each page (species, 27 pages;',
               '; $FF = none: CreditsDrawMonster returns). Patched builds read the table',
               '; through region credits_monster_ptr (a project\'s pages, up to 64).',
               'CreditsMonsterTable:'] + db_lines(0x43F4, 27, per=9) + [
               '',
               '; CreditsCopyrightLayout ($440F): the LAST page\'s layout — CreditsCopyright-',
               '; Tilemap ($681B, 20 x 11 tiles over rows 0-10): the NAMES grid shown two rows',
               '; to a line (19 cells: grid rows 0+1 on row 6, 2+3 on row 8, 4+5 on row 10) —',
               '; the copyright text\'s lines are 19 cells long and end in $F1 $F1.',
               'CreditsCopyrightLayout:',
               '    ld de, $681b',
               '    ld hl, $9800',
               '    ld bc, $140b',
               '    call CopyTilemapBlock',
               '    ret',
               '', '',
               '; --- Dispatch entry 2 ($441C) --- IntroStageInit: game mode 0 sub 0 (the',
               '; intro + the title), one INIT per stage [$C88C] (each stage ends by',
               '; [$C88C] += 1 and the mode latch $C88E += 1, so its init runs next).',
               'IntroStageInit:']
        text = text[:a] + '\n'.join(new) + '\n' + text[b:]
    more = [
        ("""    ld a, [$c88c]
    rst $00
    ld l, $44
    jr nz, jr_05f_4469

    jr nz, @+$47

    jr nz, @+$47

    ld [hl], d
    ld b, l
    jr nz, @+$47

    ret nz

    ld b, l
    ld a, [$c88d]
    rst $00
    add hl, sp
    ld b, h
    add [hl]
    ld b, h
    db $d3
    ld b, h
    ret


    ld a, $02
""", """    ld a, [$c88c]
    rst $00
    dw IntroLogosInit                 ; stage 0 ($442E) the three logo screens
    dw IntroRunInit                   ; stage 1 ($4520) the monster run
    dw IntroRunInit                   ; stage 2
    dw IntroRunInit                   ; stage 3
    dw IntroLogoDropInit              ; stage 4 ($4572) the logo comes down
    dw IntroRunInit                   ; stage 5
    dw TitleInit                      ; stage 6 ($45C0) THE TITLE SCREEN
IntroLogosInit:                       ; [$C88D] = the logo screen
    ld a, [$c88d]
    rst $00
    dw IntroLogo0Init                 ; $4439 "LICENSED BY NINTENDO"
    dw IntroLogo1Init                 ; $4486 EIDOS INTERACTIVE
    dw IntroLogo2Init                 ; $44D3 ENIX
    ret


IntroLogo0Init:
    ld a, $02
"""),
        ("""    ret


    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $560c
""", """    ret


IntroLogo1Init:
    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $560c
"""),
        ("""    ret


    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b1f
""", """    ret


IntroLogo2Init:
    ld a, $02
    call SetColorMode
    call DisableSRAM
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b1f
"""),
        ("""    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $9000
""", """    ret


IntroRunInit:                         ; the monsters running past (stages 1-3, 5)
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    ld a, $ff
    ld hl, $9000
"""),
        ("""    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitLCDTransfer
""", """    ret


IntroLogoDropInit:                    ; stage 4: the logo (tilemap $64F1, palettes set 1)
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitLCDTransfer
"""),
        ("""    ret


    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitDMATransfer
""", """    ret


; TitleInit ($45C0): THE TITLE SCREEN (stage 6; also re-entered by a button during
; the intro and by B from the title menu). LCD off: the logo's tiles ($5B20 →
; $9000, $5B21 → $8800), TitleTilemap ($6583: the logo rows 6-11 + the copyright
; rows 15-16), the title song **$06** (`ld a, $06` — patched builds: region
; title_song), palette set 1 (bank $17 entry 11, $C81E = 1), every attribute =
; palette 5 (VRAM bank 1 $9800-$9AFF; DMG: skipped). Rows 0-5, 12-14 and 17 are
; empty; VRAM bank 1's tiles are unused (S153, PyBoy). Patched builds: TitleInitDone
; is region title_text (bank $79 entry 3 TitleText draws the project's lines).
TitleInit:
    xor a
    ld hl, $9800
    ld bc, $0400
    call FillNBytesWithRegA
    xor a
    ld hl, $c0d8
    ld bc, $0028
    call FillNBytesWithRegA
    ld de, $5b20
    ld hl, $9000
    call WaitDMATransfer
"""),
        ("""    ld a, $06
    call SetBGM
    ld a, $01
    ld [$c81e], a
""", """    ld a, $06                       ; the title song (S153)
    call SetBGM
    ld a, $01
    ld [$c81e], a
"""),
        ("""jr_05f_4614:
    ld a, $00
    ldh [rVBK], a
    ret
""", """jr_05f_4614:
TitleInitDone:                      ; S153: region title_text (5 bytes)
    ld a, $00
    ldh [rVBK], a
    ret
"""),
        ("""    ret


    ld a, $f4
    call SerialTransfer
""", """    ret


; --- Dispatch entry 3 ($4619) --- IntroStageTick: A / B / START during the intro
; → the title (Jump_05f_464a: stage 6); on the title (stage 6) → the title menu
; (jr_05f_4663: sub-mode 1); else the stage's tick.
IntroStageTick:
    ld a, $f4
    call SerialTransfer
"""),
        ("""    ld a, [$c88c]
    rst $00
    and [hl]
    ld b, [hl]
    ld a, [de]
    ld b, a
    or b
    ld b, a
    ld b, c
    ld c, b
    push de
    ld c, b
    ld [$b349], sp
    ld c, c
""", """    ld a, [$c88c]
    rst $00
    dw IntroLogosTick                 ; stage 0 ($46A6)
    dw IntroRun1Tick                  ; stage 1 ($471A)
    dw IntroRun2Tick                  ; stage 2 ($47B0)
    dw IntroRun3Tick                  ; stage 3 ($4841)
    dw IntroLogoDropTick              ; stage 4 ($48D5)
    dw IntroRun5Tick                  ; stage 5 ($4908)
    dw TitleTick                      ; stage 6 ($49B3)
"""),
        ("""    ld a, [$c88d]
    rst $00
    or c
    ld b, [hl]
    jp nc, $f346

    ld b, [hl]
    ret


    ld a, [$c850]
""", """IntroLogosTick:
    ld a, [$c88d]
    rst $00
    dw IntroLogo0Tick                 ; $46B1  60 frames
    dw IntroLogo1Tick                 ; $46D2 180 frames
    dw IntroLogo2Tick                 ; $46F3 180 frames, then the run
    ret


IntroLogo0Tick:
    ld a, [$c850]
"""),
        ("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88d
""", """    ret


IntroLogo1Tick:
    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88d
"""),
        ("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
""", """    ret


IntroLogo2Tick:
    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $b4
    ret nz

    ld a, $04
    call SetGBCPalette
    xor a
    ld [$c0d8], a
    ld hl, $c88c
"""),
        ("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_472a
""", """    ret


IntroRun1Tick:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_472a
"""),
        ("""    ret


    ld a, [$c0d8]
    or a
    jr nz, jr_05f_47bb
""", """    ret


IntroRun2Tick:
    ld a, [$c0d8]
    or a
    jr nz, jr_05f_47bb
"""),
        ("""    ret


    ld a, [$c0d8]
    or a
    jr nz, jr_05f_484c
""", """    ret


IntroRun3Tick:
    ld a, [$c0d8]
    or a
    jr nz, jr_05f_484c
"""),
        ("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $78
    ret nz
""", """    ret


IntroLogoDropTick:
    ld a, [$c850]
    or a
    ret nz

    ld hl, $c0d8
    inc [hl]
    ld a, [$c0d8]
    cp $78
    ret nz
"""),
        ("""    ret


    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_4918
""", """    ret


IntroRun5Tick:
    ld a, [$c850]
    or a
    ret nz

    ld a, [$c0d8]
    or a
    jr nz, jr_05f_4918
"""),
        ("""    ret


    ld a, [$ddb4]
    ld hl, $ddce
""", """    ret


; TitleTick ($49B3): the title waits; when the song's four channels are all done
; (each channel state's +0 = $FF) the title song **$06** starts again (patched
; builds: region title_song_again).
TitleTick:
    ld a, [$ddb4]
    ld hl, $ddce
"""),
        ("""    ld a, $06
    di
    call SetBGM
""", """    ld a, $06                       ; the title song again (S153)
    di
    call SetBGM
"""),
        ("""LoadFldUI_431f:
""", """; CreditsDrawRole ($431F): the page's ROLE (bank $4C entry 2 = RunTextHandler, text
; mode [$C822] 5 = credits_role, id [$C823] = the page) into the tile grid at
; [$C827] $8000, [$C829] 2 rows x [$C82A] 20 tiles: each glyph = the next tile,
; $F1 = the line's start + one row (no wrap: a long line runs into the next row —
; TEXT_SYSTEM "$F1"). (Its restore stores E to $C828 and D to $C829: an original
; slip, harmless here.)
CreditsDrawRole:
LoadFldUI_431f:
"""),
        ("""LoadFldUI_435e:
""", """; CreditsDrawNames ($435E): the page's NAMES (mode 6 = credits_name) into the grid
; at $8260 (tile $26), 12 rows x 11 tiles.
CreditsDrawNames:
LoadFldUI_435e:
"""),
        ("""LoadFldUI_439d:
""", """; CreditsDrawTexts ($439D): page [$C0D9]'s role + names.
CreditsDrawTexts:
LoadFldUI_439d:
"""),
        ("""LoadFldUI_43ba:
    ld a, [$c0d9]
    ld hl, $43f4
""", """; CreditsDrawMonster ($43BA): page [$C0D9]'s monster (CreditsMonsterTable; $FF =
; none): its battle pose → tiles $8AA0 ($AA-$CD; bank $51 entry $11, $C81E = the
; species, $C81F = 4) + its battle palette → BG palette 4 (bank $17 entry 6).
CreditsDrawMonster:
LoadFldUI_43ba:
    ld a, [$c0d9]
    ld hl, CreditsMonsterTable
"""),
    ]
    for old, new in more:
        n = text.count(old)
        if n != 1:
            errs.append(f'block occurs {n} x: {old.splitlines()[0][:60]!r} … / {new.splitlines()[-1][:40]!r}')
            continue
        text = text.replace(old, new)
    return text, errs


def main(argv):
    check = '--check' in argv
    bad = 0
    for f in FILES:
        p = os.path.join(REPO, f)
        t = open(p).read()
        head, sep, tail = t.partition('\nHitReactionArm:')
        nt, errs = apply(head)
        for e in errs:
            print(f'{f}: {e}')
        bad += len(errs)
        if errs:
            continue
        if nt == head:
            print(f'{f}: already annotated')
            continue
        if not check:
            open(p, 'w').write(nt + sep + tail)
            print(f'{f}: annotated')
        else:
            print(f'{f}: would annotate')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
