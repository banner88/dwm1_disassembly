# Text System — Complete Reference

## IMPORTANT CORRECTION
The dispatch table at `$01:$6119` is a **per-room VRAM visual update** system
(palette animation, tile swaps), NOT NPC dialogue. See [$6119 System](#6119-system) below.

## Character Encoding (charmap.asm)

| Range | Characters |
|-------|-----------|
| $00-$09 | 0-9 |
| $10-$19 | Monster type icons (slime, dragon, beast, bird, plant, bug, devil, zombie, material, ???) |
| $24-$3D | A-Z |
| $3E-$57 | a-z |
| $5C-$64 | ' → , . ; .. (space) ! ? |

## One-cell contractions and extra glyphs — $65-$71, $80-$BF (S120, measured; there is NO DTE)

**Corrected S120 (DOC_AUDIT S120):** this section used to be a "DTE" table of letter
PAIRS (`$65 ll`, `$6D th`, `$6E he` … `$7F al`) copied from another game. The font has no
such pairs. Rendered from the font (bank `$4F` `$4010` + code × 16) and shown in PyBoy on
the user's save (S120 probe texts): **`$65` = `"`** (the double quote; 10 vanilla uses);
**`$66-$71` = ONE-cell contractions — an apostrophe + a letter drawn in one tile**:

| Code | Glyph | Vanilla uses | Example |
|---|---|---|---|
| $66 | 'l | 205 | `I` + $66 + `l` = "I'll" |
| $67 | 't | 341 | `don` + $67 = "don't" |
| $68 | 's | 445 | `it` + $68 = "it's" |
| $69 | 'r | 415 | `you` + $69 + `e` = "you're" |
| $6A | 'm | 392 | `I` + $6A = "I'm" |
| $6B | 'y | 3 | `D` + $6B + `a` = "D'ya" (the old decoders printed "Dn'a") |
| $6C | 'v | 39 | `you` + $6C + `e` = "you've" |
| $6D | 'd | 12 | `I` + $6D = "I'd" |
| $6E | 'e | 8 | `t` + $6E + `m` = "t'em" |
| $6F | 'c | 3 | |
| $70 | 'n | 3 | |
| $71 | 'T | 1 | |

`$72-$7F` are blank tiles (never used). Other glyphs of the font that text uses
(`$80-$BF`): `$96 [`, `$97 ]`, `$9C -`, `$9D ~`, `$9E /`, `$9F *` (the speaker star),
`$A0 (`, `$A1 )`, `$A2 +`, `$A3 :`, `$A4 …`, `$B6 &` (also `$8F` °, `$A5` Lv, `$A6` Ex,
`$AC` ★, arrows `$A9 $AD-$B3`, `$B4` Zz, `$B5` ©). Vanilla dialogue uses `$9F` 3,860 ×,
`$A3` 4,818 ×, `$B6` 175 ×, `$9C` 40 ×, `$A4` 22 ×, `$A2` 9 ×, `$96`/`$97` 8 ×.
The charmap (`disassembly/charmap.asm`) stops at `$64`; the editor emits the rest as
hex bytes (`editor2/core/textenc.py`, PROJECT_COMPILER §2.3 "S120").

## Glyphs, speakers and voices (S120, PyBoy on the user's save)

- **The opener only picks the VOICE.** `$EA` and `$EB` take NO parameter bytes and print
  nothing: they set `$C826` bit 0 (voice on) and `$C840` = the blip sound — **`$EA` →
  sound `$5B`**, **`$EB` → sound `$5A`** — which bank $00 `HandleTextCharacter` plays per
  printed cell (spaces included; measured: 62 blips for 62 cells). A text with **no
  opener is silent** (the hero's lines: 115 vanilla ids start with `$F6 $A3`). `$FD` /
  `$FE` turn the blip on / off mid-text. Layout is IDENTICAL for `$EA` and `$EB` (line 2
  starts at cell 0 under both — the old "the vanilla indent comes from `$EB`" note was
  wrong). Vanilla speakers per opener: `$EA` "*" 1,371, King 67, Mick, Durran, the
  bosses; `$EB` "*" 656, Pulio 50, Watabou 47, Milayou 31, Slio, Santi, May.
- **The speaker label is ordinary text**: `$9F $A3` = "*:", or a name + `$A3`
  ("Milayou:"), or `$F6 $A3` (the hero's name + ":"). Its cells count against line 1's 18
  ("Milayou:" leaves 10: "Terry! Wait!" lost "t!" in the probe).
- **`$F6` HERO** copies the 8 bytes at `$CA42` to `$C0C8` (+ `$F0`), saves the text
  pointer in `$C831/$C832`, sets `$C825` bit 4 and prints from `$C0C8`; `$F0` there returns
  to the saved pointer. All 8 letters print when the name has no `$F0`. The editor counts
  `{hero}` as **4 cells** — **MEASURED S120b** (PyBoy, the Castle's naming scene on the
  original ROM): the naming screen takes at most **4** letters (8 presses of A gave
  "AAAA", the cursor then jumps to END); a new game holds the 4 tiles `$D3-$D6` (bank $01
  writes them; font bank $4F `$4D40-$4D7F`, the ONLY copy of those tile bytes in the
  ROM), the naming screen offers them (`$C8F2/$C8F3` → `$CA42`, `$C8F4` = 0; the copy to
  `$C0C8` stops at `$00` / `$F0` / `$9F`) and accepting the offer stores `$D3 $D4 $D5
  $D6 $F0 $F0 $F0 $F0`; a typed name is stored the same way ("MILY" = `$30 $2C $2F $3C`
  + `$F0` × 4). The END check (bank $09 `SetFld9_68ef`) refuses four identical letters
  and a 14-name list at `$09:$6985` (8 B each, `$FF` end) with "Please choose another".
  **Patched (S120b, user: "change TERRY to MILLY as default, but leave otherwise as 4
  letters"):** `patches/bank_04f.asm` draws those 4 tiles as "MILLY" (64 B, same size;
  the clean tree's INCBIN still says TERRY) — the naming box offers MILLY and "King:Oh
  MILLY!" follows (PyBoy, the user's project). The editor previews use the same bytes
  (`textenc.PATCHED_GLYPHS`). Inserted names blip like other letters.
  **S121: under the Milly hook** (PROJECT_COMPILER §2.34): region `milly_name_tiles` —
  hook off = the original TERRY tiles, on = MILLY; the hook's bedroom script also writes
  the 4 tiles + `$F0` × 4 to `$CA42` at the dresser. The cutscene step **Name the hero**
  (`name_hero`) opens the Castle's naming screen anywhere (`write_ram $C8F4 0`,
  `write_ram2 $C8F2 $CA42`, op `$04` 15 0 — Castle script 0 pos 107-113); it offers the
  current name (PyBoy S121: "MILLY", then "Is MILLY okay?").
- **`$F9 nn`** prints the name in slot `$C180 + nn` the same way; script op **`$3F`
  `load_lead_name`** fills slot 0 with the first party monster's SPECIES name (text mode 5,
  ≤ 9 cells) — the editor's `{lead}` (the compiler puts `$3F` before the text).
- **Where the box opens:** at the bottom normally, at the TOP when the player stands low
  on the screen (the S120 sign NPC at row 5 of a 1-screen room).
- **Nested YES/NO** (a question inside an answer) works as written: measured S120 YES→YES,
  YES→NO, NO, each branch rejoining (talk.steps / cutscene ask).

## Control Codes ($E0+)

| Code | Name | Purpose |
|------|------|---------|
| $E0-$E6 | — | unused codes: open the YES/NO box like `$FF` (handler `TextCode_E0_E6`) |
| $E7 | **CHOICE** | **YES/NO box + continuation flags. NOT "END".** Sets $C83C (= 1, NO), $C83A=$FF. Script checks result via opcode $15. (Vanilla dialogue mostly uses `$FF`: 220 ids; `$E7`: 1.) |
| $E8 | POS | Set the draw position — **2 parameter bytes** (S108, handler $56:$451F; was listed as "PAUSE"; textenc keeps the token name `PAUSE`) |
| $E9 | SOUND | Play a sound effect — **1 parameter byte** (S108, handler $56:$4554 `PlaySoundEffect`; was listed as "NUM") |
| $EA | VOICE_LOW | Voice on, blip sound `$5B` (S120 — prints nothing, takes no parameter; the "*:" after it is text) |
| $EB | VOICE_HIGH | Voice on, blip sound `$5A` (S120 — same layout as `$EA`; was "BOX2 / indented") |
| $EC | SPEED | Text speed back to the menu setting (`TextSpeedFrames`, 7 = instant) — S120; was listed as "NAME" (never used in field text) |
| $ED | FAST | Print the rest at once (`$C826` bit 7) — S120; was listed as "MONSTER" (field text: never; battle messages use their own `$ED`) |
| $EE | NEWLINE | Line break — **MUST be preceded by $EF** or overwrites line 1 |
| $EF | PAGE | Advance rendering position. Use `$EF $EE` together for line breaks |
| $F0 | END | End the text — or, inside a `$F6` / `$F9` insert ($C825 bit 4), return to the saved pointer |
| $F1 | NEXTROW | Next row (the descriptions' line break) |
| $F2 | REFRESH | Redraw the canvas |
| $F3 | NEWCANVAS | Redraw + clear the canvas, position to its start (20 ids, before the speaker) |
| $F4 | — | `$C826` bit 7 off, `$C825` bit 1 off (`SetB56_4771`) |
| $F5 | INSTANT | `$C825` bit 1: no per-letter delay |
| $F6 | HERO | Insert the hero's name (`$CA42`, 8 bytes — S120) |
| $F7 | CLEAR | Clear text box contents |
| $F8 | SPEEDN | `$C833` := n — **1 parameter byte** (S120; unused in dialogue) |
| $F9 | INSERT | `$F9 nn` — print the name in slot `$C180 + nn` (**1 parameter byte**) |
| $FA | WAIT | Wait for A button press |
| $FB | — | `$C825` bit 6, `$C835` := n — **1 parameter byte** (S120; unused in dialogue) |
| $FC | — | `$C825` bit 7, `$C836` := n — **1 parameter byte** (S120; battle messages) |
| $FD | VOICE_ON | Voice blip on (current sound) |
| $FE | VOICE_OFF | Voice blip off |
| $FF | CHOICE2 | YES/NO box only, does NOT set continuation flags |

(S120: the handler of every code is labelled in `bank_056.asm` — `TextCodeTable` at
**`$56:$44CE`** (the dispatch `rst $00` is at `$44CD`; this doc said the table was there),
`TextCode_E7_Choice` … `TextCode_FE_VoiceOff`, `TextSpeedFrames` `$45A0`.)

**Text strings terminate with `$F7 $F0` (CLEAR + SECTION), NOT `$E7`.**

### Standard NPC Text Format (verified)
```
$EA $9F $A3 line1_text $EF $EE line2_text $F7 $F0
```

### Text boxes (PyBoy-measured S97 round 2)
- A field dialog box shows **2 lines × 18 cells** (canvas tiles $B0-$C1 and
  $C2-$D3; the glyphs are typed into those tiles, not into the BG map).
- `$EA $9F $A3` prints "*:" in the first 2 cells of line 1 → **16 cells left
  on the first line**; every other line (and every later box) starts at cell
  0 — no indent, under `$EA` and `$EB` alike (S120 measured; this line said the
  `$EB` opener indents — it only picks the other voice, see "Glyphs, speakers
  and voices").
- **Between boxes: `$FA $F7 $EF $EE`** (6,029 vanilla uses): WAIT (arrow,
  waits for A) + CLEAR + PAGE/NEWLINE → the next box starts clean on line 1.
- **A line past its cells is NOT wrapped safely**: the extra cells go to the
  next line and the next `$EF $EE` line overwrites them — they are lost; the
  engine's line counter is then off by one (the next box scrolled instead of
  clearing). A third `$EF $EE` line scrolls the box up **without waiting**.
- The editor's `boxes` form (PROJECT_COMPILER §dialogue) emits exactly
  these rules; the charmap's ".." is ONE glyph ($61), so "..." takes 2 cells,
  and (S120) a contraction ("don't") is one cell for the apostrophe + letter.
- **Font:** 2bpp 8×8 tiles at bank **$4F $4010 + code×16** (glyph = text
  code; `disassembly/bank_04f.asm` INCBINs "0-9", "A-P" …) — verified: the
  canvas tiles hold exactly these bytes for "*:Hello". The box frame tiles
  ($FA-$FF, $EE/$EF, $E0 at VRAM $8E00-$8FFF) are NOT the font glyphs at
  those codes.
- **GBC colours:** the dialog machine (bank $06, `$C915` states; box base
  `$C919/$C91A`, the room's tiles backed up at `$C100 + row×20`) and the
  YES/NO box (bank $56 `SetB56_4855` backs the 18 visible rows up to
  `$C500`, frame from `$56:$48DE` at screen row 8 col 14; bank $00
  `ClearTextBitsRedraw` restores) write tile ids only — the room's attrs
  stay under them. Vanilla looks cream only because colour 1 is forced to
  $6BFF; free-colour custom rooms need bank $73 entries 14-18 (S97 r2).

### YES/NO Choice (two-part system, verified)
Text ends with `$EF $EE $E7 $F0` (the S2 custom form) or — the vanilla form, PyBoy S97 r2 — the question's last line directly followed by `$E7 $F0` (both lines stay, YES/NO opens; `$13:$67F7` "…again?" `$E7 $F0`). Script then checks `$C83C` via opcode `$15`:
```
dw question_text_id       ; text ending in $E7 $F0
dw $FF15                  ; CheckAndBranch
dw $C83C                  ; 0=YES, 1=NO
dw $0001                  ; branch if NO
dw .no_target
dw yes_text_id            ; shown if YES
dw $FFFF
.no_target:
dw no_text_id             ; shown if NO
dw $FFFF
```

### Custom Text Routing ($0A00+)
IDs with high byte ≥ $0A intercepted in bank $04 TextQueueCheck before ROM0 cascade.
Routed to bank $60 entry 5. Two-level pointer table required (see below).

### Custom Text Pointer Table
`SaveBankAndSwitch` (ROM0 $0940) does two-level indexing:
`table[$C822*2]` → section, `section[$C823*2]` → text address.
Flat tables crash.

**S136 (ROADMAP ARC CAP2b): a section (256 ids) lives in any bank.** Bank $60 entry 5 reads
`TextSectionBanks[$C822]` and calls entry 5 of that bank — bank $60 itself or a place bank $80+ —
whose reader does `ld de, PlaceTextRows - 2 * PLACE_TEXT_FIRST / call CallTextEngine` (the bank's
own sections only, the base biased by the first one). `CallTextEngine` → `SaveBankAndSwitch` stores
`[$4000]` = the home bank in `$C824`, and every later byte read (`ReadNextTextByte`,
`SaveBankForTextDisplay`) switches to `$C824` with all 8 bits, so the text displays from there.
The compiler keeps a section within one bank: auto-numbered texts start a new section before one
passes 12,288 B (PROJECT_COMPILER §2.45). Measured: PyBoy S136 — the user's own rooms in bank $60
showing texts from banks $82-$84.

## NPC → Dialogue Pipeline

```
Player presses A near NPC
  → Bank $01 NPCTalkHandler ($55D7)
    → Bank $0B entry 5: find NPC at facing position, return script_id
      → $D8D4 ← script_id, $D8D3 ← wMapID
    → Bank $04 ScriptInit ($55EC)
      → ScriptDataRead dispatches to bank $0C/$0D/$0E/$0F based on $D8D3:
          <$06→$0C, <$20→$0D, <$40→$0E, ≥$40→$0F
          ≥$6B→$60 (CUSTOM ROOMS, added by bank $04 patch)
      → Triple-index lookup: map_type→script_id→BC command pairs
      → B≠$FF: BC is text ID → queued to $D8D9/$D8DA
      → B=$FF: C is script opcode (0-99) dispatched via rst $00
    → ROM0 TextDispatchCascade ($0AD9) routes text ID to handler bank
      → Text IDs ≥$0A00: intercepted by bank $04 patch → bank $60 entry 5
```

## Text Storage

Handler banks ($42-$4E) each contain:
1. Bank number byte at $4000
2. Jump table (5 entries, 10 bytes) at $4001
3. Text pointer table at $400B (2 bytes per entry, LE)
4. Text strings in remaining space

## Text ID → Bank Routing (ROM0 Cascade at $0AD9)

Exact ranges determined by CPU-simulating the cascade for all 2067 text IDs:

| ID Range | Count | Bank | Content |
|----------|-------|------|---------|
| $0000-$00E1 | 226 | $42 | Early game, intro, GreatTree |
| $00E2-$0197 | 182 | $43 | Arena, Castle mid-game |
| $0198-$0243 | 172 | $44 | Gate world, mid-game |
| $0244-$02FF | 188 | $45 | Late arena, story gates |
| $0300-$03C7 | 200 | $46 | Boss events, cutscenes |
| $03C8-$0473 | 172 | $47 | Advanced gates, NPCs |
| $0474-$0511 | 158 | $48 | Tournament, arena special |
| $0512-$05DF | 206 | $49 | Post-game, special events |
| $05E0-$07BF | 480 | $4A | Largest — mixed content |
| $07C0-$0867 | 168 | $4B | System messages, menus |
| $0868-$09FF | 408 | $4E | Battle text, monster info |

Total: **2,560 text ids** ($0000-$09FF; the "2067" this line said came from the old
dump's count). **S108: the "Bank" column is only where an id STARTS** — see the next
section; every id's real bank / address / text is in `extracted/dialogue.json`.

## Text id resolution (measured S108)

Each corpus bank's entry 0 (the routine the cascade `rst $10`s into, e.g. bank $42
`LoadB42_40eb`) keeps the first part of its index range and forwards the rest to an
**overflow bank** (`cp $71 / jr c / sub $71 / … ld hl,$1A00 / rst $10` in bank $42).
Measured for all 2,560 ids by `tools/dump_dialogue.py` (PyBoy stub-calls ROM0
`TextBankDispatch` $0AD9 with HL = id and reads $C824 = bank, $C82D/$C82E = string):

| ids | corpus bank (ids kept) | overflow bank (ids) |
|---|---|---|
| $0000-$00E1 | $42 (113) | $1A (113) |
| $00E2-$0197 | $43 (142) | $1A (40) |
| $0198-$0243 | $44 (98) | $1B (74) |
| $0244-$02FF | $45 (124) | $1F (64) |
| $0300-$03C7 | $46 (144) | $1B (56) |
| $03C8-$0473 | $47 (56) | $21 (116) |
| $0474-$0511 | $48 (108) | $1F (50) |
| $0512-$05DF | $49 (158) | $18 (48) |
| $05E0-$07BF | $4A (288) | $22 (192) |
| $07C0-$0867 | $4B (64) | $3F (104) |
| $0868-$09FF | $4E (88) | $4F (320) |

So banks $18 $1A $1B $1F $21 $22 $3F and $4F hold dialogue too (1,177 ids: farm
chatter, monster talk, the bonus-gate bosses, the ending, the font bank's tail …).
A bank's mode-0 table starts at the word at its own $4007 (bank $42: $4009 = dispatch
entry 4 — id $0000 = `$42:$4142` "Milayou:Terry! Wait! It's time for bed!", the new-
game intro, PyBoy screenshot S108). 382 ids show the same string as an earlier id; 2
ids resolve to non-text bytes ($45 $65EA / $65F6, "suspect"). **The pre-S108
`text_id_map.json` modelled this** (pointer table at a fixed $400B, a guessed per-page
index rule, no overflow banks): 62 of its 2,061 entries matched — the script-bank text
previews and bank $47's TextStr id comments built from it named the wrong lines until
S108 (`tools/refresh_script_text_comments.py`; DOC_AUDIT S108). `text_id_map.json` is
now derived from `dialogue.json` (`tools/dump_text_id_map.py`).

**Control-code parameters (bank $56 handler table $44CE — S120 address fix, read S108 for the decoder):**
`$E8` takes 2 bytes (sets the draw position — not "PAUSE"), `$E9` 1 byte (plays a
sound effect — not "NUM"; 7 uses in the ids, all `$E9 $60`), `$F9` 1 byte (insert:
`$00` / `$10` / `$20` / `$30` — the inserted names of the join / upgrade messages; S118:
the name is read from **`$C180 + nn`** (16-byte slots, `$F0`-terminated; bank $56
`jr_056_4806`; in game mode `$0B` from `$0D8A` "MSGBUF" instead) — filled by the
caller's code right before the text: a slot left unfilled prints on through RAM and
crashes the game, KEY_LESSONS S118),
`$F3` none (a box opener like `$EA` / `$EB`, 20 uses before the speaker). The Control
Codes table above carries these corrections.
Battle messages (bank $4C) use their own codes (`$ED`, `$FC xx`, `$EC`, `$F2` — not
decoded; shown raw by the Dialogue tab). **S111 (the forms the custom skills' own lines
use — `editor2/core/custom_skills.encode_line` / `decode_line`, read from the vanilla
lines and verified in PyBoy with new lines):** `$ED` opens a line box, `$F9 $00` inserts
the acting monster's name (`{name}`), `$F9 $10` the acting skill's name (`{skill}`; for
ids ≥ $DE fixed S111, BATTLE_SKILL_SYSTEM §13.9), `$F1` = next line, `$FC $10 $EC $F2` =
a new page, `$EC $F0` = the end. Other `$FC` arguments and codes stay undecoded.

## Monster text blocks (S108)

The three per-species text blocks (all contiguous, id-ordered, one string per
species, reached only through their pointer tables — `extract_gamedata --selftest`):

| What | Text mode / table | Block | Format |
|---|---|---|---|
| species NAME | bank $41 mode 5, `MonsterNamePtrTable` $4339 (256) | $5B1F-$628D (1,903 B): 0-219, then "" (220-224), "?????" (225-255) | 3-9 glyphs + $F0 |
| DEFAULT NICKNAME | bank $41 mode 7, `MonsterNickPtrTable` $4739 (215; was `FamilyCodePtrTable`) | $69F2-$6C76 (645 B) | 2 letters + $F0 ("SL" = Slime) |
| DESCRIPTION (library page line 2) | bank $4D mode 1 = dispatch entries 261-475 | $53D3-$7719 (9,031 B; re-sectioned S108 as `MonsterDesc_NNN_<Name>`) | ≤ 3 lines × ≤ 18 cells, $F1 between lines; $9C `-`, $B6 `&`, $67 `'t`, $68 `'s` (one cell each, font bank $4F) |

The default nickname is what the JOIN naming screen pre-fills (PyBoy S108: "SL" +
two blank slots for a Slime; bank $09 `FuncFld9_621f` copies mode 7 id [$C8F5] into
the name buffer when the name is blank and $C8F4 ≠ 0); a name left blank at END gets
a random family name instead (mode 3, `LoadFld9_688e`). The editor writes all three
blocks from `gamedata.monster_text` (PROJECT_COMPILER §2.24).

## Skill text blocks (S110)

| What | Text mode / table | Block | Format |
|---|---|---|---|
| skill NAME | bank $41 mode 6, `SkillNamePtrTable` $4539 (256) | `SkillNameStrings` $628E-$69F1 (1,892 B): ids 0-221 + the empty 222nd, id-ordered | 1-9 cells + $F0 (the monster-name encoder) |
| SKIL-menu DESCRIPTION | bank $56 `SkillDescModeTable` $664B: mode 0 → `SkillDebugTextPtrs` $664F (12 debug strings, $4E4C-$502E), mode 1 → `SkillDescPtrTable` $6667 (256 dw) | `SkillDescStrings` $502F-$664A (5,660 B; re-sectioned S110 as `SkillDesc_NNN_<Name>`): the owned texts 0-150, `SkillDesc_Blank` $6599 (ids 151-212 share it), 213-218, `SkillDesc_None` $664A (219-255 share it) | ≤ 3 lines × ≤ 18 cells, $F1 between lines, same cells as the monster descriptions |
| custom skills $DE-$FE | the same pointer tables, rows 222-254 (S111: regions `gd_custom_skill_name_ptrs` / `gd_custom_skill_desc_ptrs`) | names: bank $41 `gd_custom_skill_names` $7F98-$7FF5 (94 B; then the shared extents); texts: bank $56 `gd_custom_skill_desc` $7E42-$7FFF (446 B; then `gd_skill_desc_extra`) — PROJECT_COMPILER §2.27 | as above |

The battle announce line ("Slib casts Blaze!") is NOT a per-skill string: bank $58
`AnnounceTemplateTable` ($5806, 222 B) gives each skill a battle-message template id
(the name is inserted). The editor writes the names / texts from
`gamedata.skills.<id>.name` / `.description`; the announce template stays read-only
(PROJECT_COMPILER §2.26).

## Source re-section: text corpus was misassembled as fake instructions {#text-resection}

The text-string runs in the corpus banks were decoded by mgbdis as ~12k bogus
instruction lines per bank: the bytes are byte-perfect (clean build stays
`1ca6579…`) but the source READS as garbage, so vanilla text is not editable in
place. Per-bank layout (verified): a small dispatch table + text-loader stubs
(real CODE) at the bank head, then one **contiguous DTE string run**, then `$00`/
`$FF` padding to the bank tail. The string run is the misassembled part.

**`tools/resection_text_bank.py`** converts a bank's string run into labeled
`TextStr_<bank>_<addr>:` + `db` blocks (one label per text id, decoded text in a
comment), **labels/comments only → byte-impact zero**. Region bounds come from
data, not guesses: first string addr from `text_id_map.json`, region end = start
of the bank's trailing fill (ROM scan). `R_start`/`R_end` are snapped to real
line boundaries (probe-build line→address map, same machinery as
`resection_library_tables.py`) so no fake instruction is split; the exact ROM
bytes are emitted as `db`, so byte-perfection is automatic and a wrong split
fails the build instantly. Idempotent and re-runnable from the clean tree.

Per-bank text run bounds (string region only; head = loader code, tail = fill):

| Bank | distinct strings | string run | re-sectioned |
|------|------------------|-----------|--------------|
| $47 | 69 (125 ids) | `$4174-$5b74` | ✅ T1 keystone |
| $42 | 161 ids | `$4149-~$7dc4` | pending |
| $43–$46, $48–$4B, $4E | — | (see `text_id_map.json` addrs) | pending |

Note: many ids alias the same addr or are **alternate mid-string entry points**
(e.g. `$47:$4248` re-enters `$423e` partway) — a real game feature; each listed
addr gets its own label, all byte-exact. Banks `$4C`/`$4D` are NOT in the corpus
(no `text_id_map` entries) — different bank content (e.g. `$4D` lineage text).
Editing a vanilla string in place is the Arc-1 `T-author` follow-up (ROADMAP
Phase F). See ROADMAP "Phase F — Authorable subsystems" for the full roll-out.

## $6119 System (VRAM Visual Updates — NOT Text) {#6119-system}

Function at `$01:$60E7` runs per-frame during gameplay. Dispatches via `rst $00`
indexed by `wMapID` to the table at `$6119`. Each handler does room-specific visual work:
- Castle ($00): VRAM updates via $65E0
- GateHub2 ($08): Palette animation using $C8A6/$C8A7 as counter
- GoopyRooms ($19/$1A): VRAM tile swaps at $9320↔$93D0
- Most rooms: RET (no visual effects)

## Key RAM Variables

| Address | Purpose |
|---------|---------|
| $C822 | Text section/page index (level 1 of two-level pointer table) |
| $C823 | Text entry index within section (level 2) |
| $C824 | Text data bank number (for async bank switching) |
| $C825 | Rendering state: bit 0=active, bit 2=waiting input, bit 4=inserted text |
| $C82D/$C82E | Text data read position (current, auto-incremented) |
| $C831/$C832 | Text data base position (for $F0 reset when bit 4 set) |
| $C83A | Last special control code ($FF = YES/NO choice active) |
| $C83C | **YES/NO result: 0=YES, 1=NO** (checked by script opcode $15) |
| $D8D3 | wScriptMapType — script-bank selector. Set from wMapID for normal/custom rooms, BUT gate world sets it to `$70` (a bank-$0F selector, NOT the room mapID). ⚠️ It is NOT always == wMapID; assuming so froze gate entry (see GATE_FREEZE_FIX.md). Use wMapID to test "which room." |
| $D8D4 | wScriptNPCId (script_id from NPC entry byte 4) |
| $D8D5/$D8D6 | wScriptCounter (16-bit, indexes script data) |
| $D8D9/$D8DA | Queued text ID from script (set when B≠$FF) |

## Data Files

- `extracted/dialogue.json` — S108: ALL 2,560 text ids with their MEASURED bank /
  address / raw bytes / decoded text (+ `same_as` for shared strings) and every text
  table (battle messages, bank $41 message tables, item / skill / monster
  descriptions) — `tools/dump_dialogue.py`; read by the editor's Dialogue tab
- `extracted/text_id_map.json` — derived from dialogue.json since S108 (id → bank /
  index / address / one-line text; the pre-S108 file was modelled and mostly wrong)
- `extracted/decoded_text.json` — 1374 text strings organized by handler bank (pre-S108,
  per corpus bank only)


## Bank $56 Text Control Code Jump Table

Located at **`$56:$44CE`** (S120 correction: `sub $E0` is at `$44CB`, `rst $00` at
`$44CD`; labelled `TextCodeTable` in both trees).
32 entries (2 bytes each) for control codes $E0-$FF:

| Code | Handler | Code | Handler | Code | Handler | Code | Handler |
|------|---------|------|---------|------|---------|------|---------|
| $E0 | $450E | $E8 | $451F | $F0 | $46FE | $F8 | $47BF |
| $E1 | $450E | $E9 | $4554 | $F1 | $472B | $F9 | $47CE |
| $E2 | $450E | $EA | $455E | $F2 | $474F | $FA | $481B |
| $E3 | $450E | $EB | $4569 | $F3 | $4758 | $FB | $4821 |
| $E4 | $450E | $EC | $4574 | $F4 | $4771 | $FC | $4835 |
| $E5 | $450E | $ED | $45A7 | $F5 | $477C | $FD | $4849 |
| $E6 | $450E | $EE | $45AD | $F6 | $4782 | $FE | $484F |
| $E7 | $4511 | $EF | $4640 | $F7 | $47B4 | $FF | $4855 |

(Merged from SESSION2_CUSTOM_CONTENT.md, 2026-06-13.)

---

## Two-Level (Mode × Species) Text Source Selection — `SaveBankAndSwitch`

Many per-entity text renders (monster detail lines, name slots, icon slot) do
**not** pass a text source directly. They pass a **mode-table base** (`$4007` in
the active text bank) and let `SaveBankAndSwitch` (`$00:$092F`) resolve the real
source with two indexed reads:

```
$C824 = current ROMX bank             ; render bank
de    = $4007                         ; mode-table base (passed in)
de    = [ $4007 + [$C822]*2 ]          ; LEVEL 1: pick a per-species ptr table by MODE
de    = [ de    + [$C823]*2 ]          ; LEVEL 2: index that table by SPECIES/id
$C82D/$C82E = de                      ; final text source pointer
```

- Entry point is **`CallTextEngine` = `$00:$05B6`** (mgbdis mislabels the `$05B5`
  `ret`; the real routine starts at `$05B6`).
- HRAM: `$C822` = mode, `$C823` = species/id, `$C824` = render bank,
  `$C82D/$C82E` = source.
- Bank `$4D` (monster detail text) and bank `$41` (name/dispatch text) each have
  their own `$4007` mode-table.

**Bank `$4D` `$4007` = `dw $400b,$420b,$43ce,$43e1,$43f4,$4407,$441a,$442d`:**

| Mode | Base | Use | Entries |
|------|------|-----|---------|
| 0 | `$400B` | detail line 1 — the **breeding recipe line** (two 9-char parent fields; BREEDING_SYSTEM "Library recipe TEXT") | 256 |
| 1 | `$420B` | detail line 2 — **per-species description** | **215** (0–214) |
| 2–7 | `$43CE…$442D` | **not tables**: these words are dispatch entries 5-10 = the mode-0 pointers of species 0-5, i.e. the addresses of their recipe strings (19 B apart). A mode 2-7 lookup would read string bytes as pointers — no reader uses them (S103 correction; the S29 row said "small routine targets") | — |

The mode table ($4007 = entries 3-10) and the mode-0 table ($400B = entries
5+) OVERLAP, so an editor must never repoint the recipe strings of species 0-5:
the compiler rewrites recipe strings **in place** (`gd_library_text`, S103;
the block $43CE-$53D2 is re-sectioned as `LibRecipeText_NNN` db rows in both
trees).

**Bank `$41` `$4007` mode bases line up with the named tables in `DATA_STRUCTURES.md`:**
mode 5 → `MonsterNamePtrTable` (`$4339`, 256), mode 6 → `SkillNamePtrTable`
(`$4539`, 256), mode 7 → `MonsterNickPtrTable` (`$4739`, **215**; the default nicknames — mgbdis named it `FamilyCodePtrTable`, renamed S108). Modes 0–4
(S104: decoded and re-sectioned in both trees as labelled `dw` tables,
`TextModeList41` + `TextMode0_Debug` … `FamilyIconStrTable_Old`; bytes unchanged):

| Mode | Base | Entries | Content |
|------|------|---------|---------|
| 0 | `$4025` | 10 | debug-menu strings ("DEBUG MODE" …) |
| 1 | `$4039` | 100 | debug stage names (NORMAL, ACREATE, STAGEID, CASTLE …) |
| 2 | `$4101` | 113 | field messages ("[F9]0 dumps…", "Cannot dump here!", "WHOINFOOKMONEGG" …) |
| 3 | `$41E3` | 160 | `FamilyNamePoolTable`: DEFAULT NAMES, 16 per family — id = `family<<4 \| gender*8 \| RNG&7` (bank `$09` `jr_009_68aa`, naming screen). S104: ids `$A0`–`$A7` = Spirit's pool (bank `$6D` `FamilyDefaultNameId`), reached through the dead `$4323` words |
| 4 | `$4323` (patched: `$7E18`) | 11 (patched 16) | family ICON strings `"<$10+fam>"+$F0`; **id 10 = `$5B1E`, the EMPTY string = the "no family" icon** (bank `$07` pedigree page, family `$FF`). B9 relocated the table to `$7E18` with id 10 = Spirit; S104 moved the "no family" request to id 11 (same empty string) |

Mode 4 is the one text path that prints a family icon: INFO page, library tab
strip, pedigree parents. The HUD / list icons are gfx streams instead (bank
`$2E` entries 3-12, the same 10 tiles; Spirit: bank `$6D` gfx id `$6D04`).

### Worked example & trap — the encyclopedia detail-page freeze (Session 29)

The per-mode tables have **different entry counts**, and there is **no bounds
check** — a high species id overshoots any mode whose table is ≤ id and reads the
following bytes as a pointer. This froze the new-species (id 224) detail page:

- Detail line 2 (mode 1) source = `[ [$4009] + 224*2 ] = [$420B + $1C0] = [$43CB]`.
- The mode-1 description table is only **215 entries** and ends exactly at `$43B9`
  (where `SetB4d_43b9`'s code begins), so `$43CB` is **inside routine code** and
  reads the bytes `09 06` = **`$0609`** (a ROM0 address). The VM then renders ROM0
  *opcodes* as glyphs forever, `$C825` (text-busy) never clears, and
  `WaitScreenUpdateDone` (`$060E→$065F→$0CE7`) spins → freeze. The `$0609`/`$0617`
  in the crash dumps is exactly this overshoot value. (Line 1 / mode 0 is fine: its
  name-template table is 256 entries.) Vanilla never hit it because ids 215–223
  never open a detail page.

**Fix (`patches/bank_04d.asm`, byte-neutral):** `SetB4d_43b9` (7 B) → `jp
HighDetailTextFork` + 4 `nop`. The fork gates on id (`cp $E0`): id < 224 → vanilla
`$4007`; id ≥ 224 → a custom mode-table whose mode-1 base = `HighLine2Ptrs - $1C0`
so `[base + 224*2] = HighLine2Ptrs[0]`. Modes 0/2–7 keep vanilla bases. This is the
project's standard "high-table + forked loader, vanilla byte-identical" pattern (see
MONSTER_DATA.md "Species ID geography"). Every species-indexed table and its
overshoot/fork status is catalogued in MONSTER_DATA.md.

> **Caveat (POC vs fundamental):** the *mechanism* is fundamental, but `HighLine2Ptrs`
> currently holds ONE entry (id 224 → `$60BC`, **Dracky's description as a
> placeholder**). Each additional new species needs its own description pointer added
> here, or it will overshoot the 1-entry high-table and freeze again. A bespoke
> Gorbunok description string (font-glyph encoded like the name) is deferred; the
> editor will generate these high-tables from a species definition.

---

## Battle-message id space is FULL — custom pool at `$4c:$7326`  [S49, 2026-06-29]

The mode-0 battle-message table (`subtable=[$4c:$4009]=$4019`; `string=[$4019+id*2]`)
maps all 256 ids to live message data; **exactly one slot (`$FD`) was empty**
(it pointed at an empty `$F0` at `$5F6C`). So a custom skill that needs *bespoke*
announce/result text cannot just claim a fresh id. Free **text bytes** are not the
constraint — bank `$4c` has ~3290 free bytes at **`$7326`** (after the last message
at `$7325`), the **custom message pool**. MagicBurn uses it: `CustomMsg_E0_MagicBurn`
(56 B) at `$7326`, with `$FD`'s pointer (`$4c:$4213`) repointed there
(patches/bank_04c.asm). A 2nd+ bespoke message needs either a verified-unused id, a
forked render-from-pointer path, or fixing the custom-id skill-name insert so
name-inserting templates can be reused instead. Encoder/charset: this doc + the
round-trip in the build. Full context: BATTLE_SKILL_SYSTEM.md §13.1.

### The custom-message render FORK — `$FD` → per-skill pool string  [S50/S2e, 2026-06-30, DONE]
Since only `$FD` was free, it is now a general **custom-message escape** (not a single-skill
slot). `LoadB4c_42d1` (`$4c:$42d1`) is forked byte-neutrally to `LoadB4c_Fork` (`$4c:$735e`):
when the message id is `$FD`, it resolves the string from `CustomMsgPtrTable` indexed by the
current skill id (`[$db8a]-$DE`), by feeding a private mode-table base (`CustomMsgModeTable dw
CustomMsgPtrTable`) to the SAME two-level resolver (`CallTextEngine $00:$05b6`, mode 0). Stock
ids stay byte-identical; a stock skill emitting `$FD` (id < $DE) falls back to vanilla
`$4019[$FD]`. This is the "forked render-from-pointer path" (BATTLE_SKILL_SYSTEM §13.4 open
follow-up b) — now implemented. MagicBurn (`$E0`) and Tame (`$E1`) both use it (idx = id-$DE).
Add a skill = one `CustomMsgPtrTable` entry + one pool string. `patches/bank_04c.asm`.
**S111:** `CustomMsgPtrTable` (33 rows, $DE-$FE) and the pool strings are compiler regions
(`gd_custom_msg_ptrs`, `gd_custom_msg_a` = MagicBurn's 56-B slot at `$7326`,
`gd_custom_msgs`); a skill's own line = `gamedata.skills.<id>.announce`, template `$FD`.
