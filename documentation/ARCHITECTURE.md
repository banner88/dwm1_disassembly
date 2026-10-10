# DWM1 ROM Architecture — Quick Reference

## Bank Map

| Bank | Role |
|------|------|
| $00 | ROM0 (always mapped): RST handlers, PRNG, math, text render, BGM, event flags |
| $01 | Encounters, party management, NPC talk handler, gate data |
| $03 | Link/serial, monster info table ($4461) |
| $04 | NPC script engine (102 opcodes $00-$65; arity table S96: BANK04_SCRIPT_ENGINE) |
| $0B | Room system: loading, exits, NPCs, transitions, pointer table $4B43 |
| $0C-$0F | Script data banks: 518 NPC scripts across all map types ($0C=129, $0D=168, $0E=130, $0F=91). Identical code $4000-$41B9, data from $41BA. Master table indexed by absolute map_type. $0C=types<$06, $0D=$06-$1F, $0E=$20-$3F, $0F≥$40. Generator: `gen_script_banks.py` |
| $13 | Level-up processing, stat growth tables |
| $14 | Enemy stats table ($4C1D), boss redirect table ($4897) |
| $16 | Breeding system: special table ($4B30), family table ($4974) |
| $17 | Palette system |
| $41 | Name/text tables: monster names, skill names, family codes, items, personalities, game text (fully annotated) |
| $42-$4E | Text handler banks (text ID routing, text data); each forwards the upper part of its id range to an OVERFLOW text bank — $18 $1A $1B $1F $21 $22 $3F $4F (S108, measured: TEXT_SYSTEM "Text id resolution") |
| $50 | BATTLE MODE manager (wGameMode==2; S68): $D9EC 18-phase battle machine (BattlePhaseTable $5F3A), nested $D9F4 sub-machine (11 states), BattleExitHandler $640A (win→script-resume / loss penalty) |
| $51 | Event sub-handlers, room transitions |
| $52 | Battle system: 115 named skill handlers, SkillFunctionTable at $4011, family checks, math helpers |
| $54 | Post-battle join logic ($55BB), EXP distribution, level-up processing |
| $56 | Text rendering engine, parallel text dispatch cascade |

## Top-level game mode (wGameMode $C88A) — S68

ROM0 runs two parallel dispatch tables on `$C88A`: `$00:$030F` = mode INIT
(called from the main loop at `$02B0` when `$C88E` mode-change latch fires),
`$00:$050F` = per-frame TICK. Sub-modes `$C88B-$C88D`; `$C8AD-$C8B0` saves
the 4-byte mode block for overlay modes. Mode rows (init entry / tick entry):

| Mode | Bank:entries | Role |
|------|--------------|------|
| 0 | $15:0 / $15:1 | Title / new-game / link menus |
| 1 | $01:0 / $01:1 | FIELD (script VM ticks here via bank $04) |
| 2 | $50:0 / $50:1 | BATTLE (BattleInit / per-frame driver) |
| 3 | $02:1 / $02:2 | the ENDING's night scenes (S125, PyBoy: after the Starry Night win — flag `$00E4` + `$D940` = 2 reach it — the special night Farm: the starry sky pan + the night palettes drawn by bank $02 over the ordinary blue-sky room data; ROADMAP E5) |
| 4 | $5F:0 / $5F:1 | map-script/cutscene engine |
| 5 | $5F:8 / $5F:9 | map-script/cutscene engine (2nd) |
| 6 | $18:0 / $18:1 | bank $18 mode (link teardown target) |
| 7 | $55:$0D / $55:$0E | overlay (START saves mode block to $C8AD) |
| 8 | $59:0 / $59:1 | bank $59 mode |
| 9 | $59:2 / $59:3 | bank $59 mode |
| 10 | $59:4 / $59:5 | bank $59 mode |
| 11 | $56:3 / — | bank $56 mode |
| 12 | $56:7 / — | bank $56 mode (SELECT+? saves mode block) |

Battle entry/exit: request latch `wGameState.6` → bank `$13` `$C905`
transition machine (`$13:$73F5` = the ROM's only `res 6`) → mode 2;
`BattleExitHandler $50:$640A` → mode 1 + `$C8EA.7` (script resume). Role
names beyond banks 01/50/13 are best-effort; entries are ROM-verified.

## Empty ROM Banks (23 banks = 368KB in the VANILLA ROM)

`$60, $64, $67, $69-$77, $79-$7A, $7C, $7E-$7F`

> **All 23 are patch-owned since S121** (S133: this note said 8). The canonical
> current-allocation table lives in PROJECT_STATE.md "Bank allocation"; new space
> = banks $80-$FF (below, ROADMAP ARC CAP1).

## Free Space in Used Banks

| Bank | Address | Bytes | Notes |
|------|---------|-------|-------|
| $00 | $3FE8 | 24 | Confirmed safe (FF fill at bank end) |
| $01 | $7FD5 | 42 | FF fill $7FD5-$7FFE; $7FFF=$01 (NOT free) |
| $0B | — | ~2 | Essentially FULL |
| $51 | $7B34 | 1,228 | 00 fill — large, investigate safety |
| $54 | $7FC0 | 64 | 00 fill (24B used by join patch) |

**Patched build, S133 (end-of-bank fill, the example overlay `7d136455…`, patched):** ROM0 8 B,
$01 1, $04 1, $06 1, **$0B 1**, $50 1, **$16 732**, **$17 3,937** (the custom rooms' palettes +
render tables grow here), $60 8,756 (example project; the user's 11-room POC left 3,502).

## RST Dispatch Mechanisms

- `rst $00` — Jump table dispatch: A indexes into table immediately after RST
- `rst $08` — ROM0 call dispatch: calls function in bank $00
- `rst $10` — Cross-bank call: H=bank, L=entry index → switches bank and calls entry.
  It saves the CALLER's bank by reading `[$4000]` (each bank's own-number byte), writes H to
  `$2100` (MBC5 ROMB0, 8 bits), and on return pops that byte back into `$2100` (bytes
  `$0020-$0037`: `add hl,hl / ld h,0 / ld bc,$4001 / add hl,bc / call $0008 / pop af / ld
  [$2100],a / … / ld [$6100],a / ret`, read S133). Only A (and F) is clobbered on the way
  back: BC / DE / HL return as the CALLEE left them (the caller's BC is lost — it is $4001 on
  the way in; bank $60 `CustomScriptRead` returns its word in BC this way). The entry index
  wraps at 128.

## ROM banks $80-$FF (S133 — the 4 MB audit, ROADMAP ARC CAP1)

The ROM is MBC5, 2 MB (`$0148` = `$06`). A 4 MB ROM (256 banks) needs no engine change:

- **Measured (scratch builds, PyBoy):** `SECTION "…", ROMX[$4000], BANK[$80]`…`[$FF]` link with
  RGBDS 0.6.1; `rgbfix -p 255` pads to 4,194,304 B and rewrites `$0148` := `$07` and both
  checksums by itself (`patches/bank_000.asm` `HeaderROMSize db $06` only draws a warning).
  PyBoy boots the 4 MB ROM to the bedroom; `$2100` := `$80` / `$FF` maps those banks; a
  `rst $10` into a bank $80 routine, placed on bank $73 `CF2WarpCommitDrain` (every room
  commit), ran 3 times in 3 warps, read `$80` at `[$4000]`, returned, and every room loaded
  and walked.
- **Read (both trees):** the only bank-switch writes are 23 ROM0 `ld [$2100], a` sites, each
  writing a full 8-bit value from H (`rst $10`), the stacked `[$4000]`, `$C824` (text),
  HRAM `$FFE8` / the audio table's bank column, or D (the gfx-ID high byte); **no code tests
  bit 7 of a bank number**, nothing writes ROMB1 (`$3000-$3FFF`), and since S69 no RAMB write
  is derived from a ROM bank number (the 19 quadrant writers go to the MBC5-ignored `$6100`;
  even the old `swap / rra / and $03` kept only 2 bits).
- **The rule for every new bank: byte `$4000` = its own number.** `rst $10`,
  `AudioSaveBankState` (the frame driver's music bank swap) and the text engine (`$C824`,
  `ReadNextTextByte`) save "the current bank" by READING `[$4000]` and switch back to that
  value — a bank whose first byte is not its number returns to the wrong bank as soon as code
  runs from it or music plays while it is mapped. (15 vanilla / empty banks do not follow
  the convention — `$20` `$40` `$61-$63` `$65` `$66` `$68` `$78` `$7B` `$7D` and the
  empty `$79` / `$7A` / `$7C` / `$7F`; nothing far-calls them.)
- **The "step validation checks tileset_bank < $80" is NOT engine code** — bank $0B
  `ReadStepBlock` and bank $60 `CustomReadStep` pass the bank straight to
  `DecompressTileLayout`; the `< $80` tests live only in Python dump tools
  (`tools/dump_room_data.py`, `decompress_tiles.py`, `render_rooms.py`, `analyze_bank17.py`)
  — DOC_AUDIT S133.
- **As built S134 (ARC CAP1; built, NOT yet user-tested): every patched build is 4 MB.**
  `patches/game.asm` INCLUDEs `bank_ext.asm` (compiler-generated, `emitters.emit_bank_ext`):
  one `SECTION "ROM Bank $0xx", ROMX[$4000], BANK[$xx]` + `db $xx` per bank $80-$FF (a
  compiler place bank is INCLUDEd in its place — ARC CAP2); `HeaderROMSize` `$07`. The
  example build differs from the 2 MB S129 pin ONLY at `$0148` / `$014D` / `$014E-F`; banks
  $80-$FF are the self-ID byte over zero fill. `tools/validate_custom_data.py check_banks`
  (verify check 6 and every editor build) refuses a ROM that is not 4 MB, whose header is
  not `$07`, or where a bank $80-$FF — or a bank $01-$7F the build CHANGED and filled — does
  not start with its own number.
- **Plumbing that did need changing (S134):** `patches/game.asm` INCLUDE lines for the new banks;
  `tools/verify_integrity.py` `PATCH_NEW_FILES` and `editor2/core/builder.py` (they stage /
  clean a hard-coded list); the compiler's bank meters (`validators.TEMPLATE_SIZE` /
  `bank_usage`, `app/space_meter.py`); `randomizer/romdata.py` refuses a non-2 MB ROM (fine
  for vanilla input). 8 MB would need 9-bit bank numbers through every far call — not planned.

## LZ stream banks (S135 — ROADMAP ARC CAP2a)

Room layouts, attribute (colour) maps and BG tilesets are all LZ streams read by ONE ROM0
routine, `DecompressTileLayout` ($1627; annotated both trees S135), through two front ends:
`WaitLCDTransfer` → `LoadSpriteFrame` (layouts → `$C300`/`$C500`, attr maps → `$C200`, plain
writes) and `WaitDMATransfer` → `TextScrollWindow` (tilesets → VRAM `$9000`). Both save the
caller's bank by reading `[$4000]` and take the `$DA78` lock.

- **In:** D = bank (written to `$2100`, 8 bits — any bank $01-$FF), E = entry, HL = destination.
  **Stream pointer = the word at `$4001 + 2E` of bank D** → ≤ 256 streams a bank. Header 3 bytes
  `[declen lo, declen hi, marker]`, then literals / `[marker, lo, hi4:len4]` copies (PROJECT_STATE
  "LZ graphics streams"). The body is read with `inc de`: **a stream never crosses `$7FFF`.**
- **Interrupts stay on** during a decode; the frame driver's audio swap (`SaveBankAndAudioState`)
  saves "the current bank" by reading `[$4000]` — the DATA bank at that moment — so a stream bank
  must start with its own number (the ROM banks $80-$FF rule above).
- **Every reference carries its bank:** a room step entry `[step_id, bank]` (bank $0B
  `ReadStepBlock`, bank $60 `CustomReadStep`, gate floors bank $16 `MazeScreenTable` rows), a bank
  $17 render row `[attr_entry, attr_bank, pal_ptr]` (vanilla attr bank $3C, gates $3D), a `$26DD`
  record `[gfx_id, gfx_bank, …]` (ROM0 for map ids < $70, bank $71 `Custom26DDTable` above). Readers
  traced S135: bank $0B room entries 0-3, bank $07 / $16 via `rst $10` $0B08, bank $17 entries 0/1
  (callers in banks $0B / $07 / $15), the tileset reloads after menus / screen effects (banks $07 /
  $09 / $12 / $15) and bank $77 `BreedClose`. None caches or compares a bank number.
- **What is pinned is the TABLES, not the data:** vanilla step tables in bank $0B, custom ones in
  bank $60, gate rows in bank $16, attr / palette tables in bank $17 (`pal_ptr` is read while bank
  $17 is mapped — palettes cannot move without code; S137 (CAP2c) added that code for custom rooms:
  "Room colours in the place banks" below).
- **Patched builds (S135):** the compiler's `Project.stream_plan()` places the project's streams
  first fit — layouts / attr maps in bank $64, tilesets in $67, then overflow banks $80, $81, …
  (any kind mixed; `patches/bank_0xx.asm`). Measured: `tools/census_stream_banks.py` (346 streams
  decoded from the built ROM; PyBoy screens == the editor preview) and the S135 test ROM's 16 halls
  on the user's save.
- **The bank $17 walk checks nothing** (`label17_409e`): a `dw $0000` screen word is followed into
  ROM0 `$0000` — a custom room's undefined screen inside its size crashed that way (game mode `$FE`
  + hang, PyBoy S135); the compiler never emits `$0000` for such a screen now.

## Place banks (S136 — ROADMAP ARC CAP2b; built S136, USER-CONFIRMED)

Everything bank $60 held per custom room — the script table + scripts, tile patches (ops `$24` /
`$61`), the screen sub-table, step entries, NPC / exit lists, state rules, monster cast — is that
PLACE's block, and a block lives in one HOME BANK; the project's text lives in 256-id SECTIONS
(section = text id >> 8 − `$0A`), each in one bank. Bank $60 is the first home; the rest are
PLACE BANKS $80+ (compiler `editor2/core/places.py`, first fit after the stream banks).

- **The engine still calls only bank $60** (`ld hl, $60xx / rst $10` in banks $04 / $06 / $0B /
  $17 / $77 untouched). Its entries 0 (step), 1 (NPC list, custom rooms), 2 (exit list), 4 (script
  word), 5 (text), 8 (state rules + cast), 9 / 10 (tile patches) are FORWARDERS
  (`editor2/core/templates/bank_060_head.asm`): `PlaceOf` looks the place up in `PlaceDirectory`
  (per place: home bank, index there) on EVERY call — no cached bank, so the map-id writes outside
  the room commit (gate insert, boss floor, save load, new game, Play here) need nothing — writes the
  index to **`wPlaceIdx` ($D50A)** and `PlaceGo` calls the home bank's entry of the same number
  (`rst $10`, or a local jump through `PlaceEntries` when the home is $60). Text: `TextSectionBanks`
  [`$C822`] → that bank's entry 5. Keys: entries 0/1/2/8 = `wMapID`; entries 4/9/10 = the running
  script's TYPE `wScriptMapType` (what the old reader indexed — a script that warps out keeps reading
  its own room); type `$FF` = the custom skills' scripts, which stay in bank $60. Out of range (a
  vanilla id, a type past the last place, the transient `$70` with < 6 places): BC = `$FFFF`, the
  dummy step `$2A01`, an empty list, the patch op's word stepped over.
- **Every home bank carries the same reader block** (`templates/place_readers.asm`, 944 B, pinned):
  in bank $60 with no label suffix, in place bank `$xx` at `$4001` with suffix `_Pxx` — so its
  `PlaceEntries_Pxx` IS the bank's `rst $10` table. The readers index their bank's tables
  (`PlaceRoomTable`, `PlaceScriptTable`, `PlaceRuleTable`, `PlaceCastTable`, `PlaceSourceTable`,
  `PlaceTextRows` biased by `PLACE_TEXT_FIRST`) with `[wPlaceIdx]`, never `wMapID − $6B`.
- **Why it is sound (read + measured):** the far-call return keeps BC / DE / HL (RST Dispatch
  above), so the script word (BC) and its address (HL — the branch tail computes counter +=
  (target − HL) / 2, BANK04_SCRIPT_ENGINE "Parameter counts") come back through two nested calls;
  branch targets are absolute addresses in the script's own bank, so a place's scripts must sit in
  one bank (they do — a block is never split). Text: `CallTextEngine` runs in the home bank, which
  `SaveBankAndSwitch` stores in `$C824`; every later byte read switches to `$C824` (8 bits). The
  per-call cost: one directory read + one extra far call per script word / list copy.
- **Measured:** `tools/census_place_banks.py` (stub calls: every step, list, cast, script word and
  text of a project vs the ROM bytes at its labels — the user's project 4,829 checks, the S136
  demo 8,926 over 5 banks, a generated spill 20,975 over 8 banks: 0 mismatched); PyBoy on the
  user's save: talks, YES / NO, an entry scene with a tile patch, a talk battle, doors both ways, a
  save + reload — in rooms of bank $60 and of place bank $81, texts from $82-$84; an A/B by warps of
  every screen of the user's 11 rooms (S135 vs S136 build): every script word, text and list
  identical (branch words compared by label — their addresses moved).

### Room colours in the place banks (S137 — ROADMAP ARC CAP2c; built S137, USER-CONFIRMED)

Until S136 a custom room's RENDER ROWS (per screen and state: attr map entry + bank, palette
pointer) and its PALETTES lived in bank $17 (`CustomAttrPtrTable` → `RoomAttr_<mid>` →
`ScrAttr_<mid>_<k>`, compiler regions `room_render_tables` / `room_palettes_a`), because the two
bank $17 walks that read them (entry 0 `label17_401d`, the palette; entry 1 `label17_409e`, the
attr map) read every word — and `LoadPal_46a1` the palette's bytes — with bank $17 mapped. Bank
$17 had ≈3.3 KB free for them: ~118-125 B a room, full at ≈35-40 rooms (measured S137 on the
user's project and the S136 demo — and no meter watched it).
- **Now part of the place's block** (`emitters.render_lines`, `places.room_block`): `RoomAttr_<mid>`
  (16 dw), `ScrAttr_<mid>_<k>` = `dw step counter, db n_states`, then per state `db attr_entry,
  attr_bank / dw pal_ptr`, and `RPal_<mid>_<n>` = the 32 B (slots 0-3 — the only slots the game
  loads for a custom room) of each project palette the room uses (a copy per room; the S96
  free-colour-1 marker in colour 3 bit 15 kept). A BORROWED vanilla palette is not copied: its
  `pal_ptr` is the bank $17 address with **bit 15 set** (free: ROMX addresses are `$4000-$7FFF`).
  Per bank, `PlaceRenderTable[wPlaceIdx]` (`$0000` = a placeholder room).
- **The walk reads WRAM.** Bank $17 `CustomAttrCheck` (entered by both walks with HL = the vanilla
  `AttrPtrTable`; it returns the table base in HL and the index in A) now, for a map id ≥ `$6B`,
  far-calls **bank $60 entry 13 `PlaceFwdRender`** → `PlaceOf` → the home bank's reader **entry 13
  `CustomRenderCopy`** (place_readers.asm), which runs the state rules first (the job of
  StateRulesHook17, S97-S136 — gone), walks the place's table, clamps the counter to the last state,
  and builds a fake one-room table in WRAM: `wRenderTable` ($D50B) = `wRenderScr` − 2·wScreenIndex,
  `wRenderScr` = `wRenderRow`, `wRenderRow` = `dw wRenderZero` + the row (pal_ptr = `wRenderPal`
  after a 32 B copy, or the borrowed bank $17 address), `wRenderZero` = 0, `wRenderPal`
  ($D516-$D535). It returns HL = `wRenderTable`; `CustomAttrCheck` returns A = 0 — the UNCHANGED
  vanilla walk then lands on the row, and `LoadPal_46a1` copies the palette from WRAM (or from bank
  $17 for a borrow). HL = 0 (no place — a stale save past the last place; a placeholder; a screen
  word `$0000`) → the Castle fallback a placeholder room has always had, instead of S135's ROM0
  `$0000` walk.
- **Stateless, like CAP2b:** rebuilt on every call (both walks call it; menus, battles, service
  screens and the fades reload through entry 0 again), so nothing needs refreshing when the map id
  changes outside the commit. `rst $10` clobbers BC on the way in and A/F on the way back — the
  walk sets B/C/D/E itself after `CustomAttrCheck`, so only HL / A matter (KEY_LESSONS S136).
- **Measured:** `tools/census_place_banks.py` render checks END TO END through bank $17 (stub calls of
  bank $17 entries 1 and 0: the attr map at `$C200` == the project's stream, palette slots 0-3 of
  `$C797` == the project palette / the original ROM's borrowed bytes under the engine's forcing;
  every state reached by its counter or by its rule's flags) — example 13 + the S137 demo 147
  screen-states over banks $60 / $81, 0 mismatched; PyBoy: the S137 demo's 64 screen-states == the
  editor preview, painter talk → state 1 colours and back, colours restored after the field menu, a
  talk battle and the library screen in halls of bank $60 and $81, stairs $60 → $81, a JOURNAL save
  + reload in a painted place-bank hall; the user's 33 screens S136 vs S137 build: palette buffer and
  picture identical.

### Stale places at CONTINUE (S138 — ROADMAP ARC CAP2e; built S138, USER-CONFIRMED 2026-10-10)

A save records the map id it was made in (`wMapID` $C968 in the `$C8EA-$D9E9` image); a later
build of the project may have NO place there — the room was deleted (the compiler fills the gap
with a PLACEHOLDER; the next new room takes the number back) or the id is past the last room.
Bank $60 (S136) and bank $17 (S137) already fell back to the dummy step / the Castle colours;
bank $71 entry 0 did not, and CONTINUE hung (KEY_LESSONS S137). Since S138:
- **The CONTINUE loader** (bank $15 `ContinueLoadSave`, the CONTINUE screen's step 0:
  `SRAMAccess_21B2` + bank $17 entry 0) far-calls **bank $71 entry 10 `ContinueCheck`** in the
  bytes where the original game jumped over a DEAD block (`ContinueGateSaveRelocate`: a gate save
  continued a second time was warped to the Castle and healed — unreachable in the shipped game).
  For a stale id outside a gate it arms the same warp the engine's other "send home" paths use:
  bank $71 `HubWarp`, reason `HUB_CONTINUE` 7 (the project's hub room + `wHubReason`, else the
  Castle at ($E8, $58) with no `$D92B` arrival code), `wIsPlayerChangingMaps` 1, `$C8EA` 1 (not the
  loader's `$80` — no script resumes), `wScriptStateFlags` 0, the party healed at the Castle. The
  field's first transition then goes home: the stale room is never loaded (PyBoy: no room record
  read for it).
- **Every per-room reader is bounded** (defence in depth — a stale id can still be reached by a
  poke or a future path): `StalePlace` (a custom id ≥ `ROOMFLAGS_TABLE_LEN` or with
  `CustomRoomFlagsTable` bit 7, a placeholder) → entry 0 reads the Castle's record (map 0), entry
  5 returns `$81` (no saving there); entries 1 / 3 and banks $60 / $17 / $6C / $76 already fell
  back. `tools/census_stale_places.py` measures all of them.
- **Not caught (by design):** a save in a room whose NUMBER now belongs to another room (delete +
  new room) loads into the new room — the id is a real place. Places by name / regions = ARC
  CAP3 / CAP4.

### Animation banks (S139 — ROADMAP ARC CAP2d; built S139, USER-CONFIRMED)

A custom room's OWN animated tiles (S102, `custom.rooms[].tile_anims`) are played by bank $6C:
bank $71 entry 3 `CustomAnimSource` (called by the rewritten bank $01 `PerRoomVRAMDispatch`
every field frame, custom rooms only, after the vanilla guards) far-calls bank $6C entry 0. The
player copies each due step's frame with a General-Purpose DMA whose SOURCE is read from the
address space as mapped at that moment — so the frames must sit in the bank the player runs in.
Until S139 that was bank $6C alone: every room's frames in one 16 KB bank (a drifting 4-tile
strip is 2 KB per row; the bank filled at ~15-80 animated rooms, by style).
- **Bank $6C entry 0 `CustomTileAnimate` is a forwarder** (`templates/bank_06c_head.asm`):
  `wMapID − $6B` < `TILEANIM_ROOMS` → `TileAnimDirectory` row = (bank, index); bank 0 = no own
  animations (return); bank $6C → a local `jp` to `TileAnimPlay` with E = index; else `ld h, bank
  / ld l, 0 / rst $10` → that bank's entry 0 `TileAnimPlay_A<bank>`. E reaches it unchanged:
  `RST_10` / `RST_08` touch A, BC, HL only on the way in (RST Dispatch above). Looked up on every
  call, nothing cached (like the place banks); a vanilla id or an id past the directory returns
  at once (the S138 stale bound holds).
- **Every animation bank = self-ID + `dw TileAnimPlay_A<bank>` at `$4001` + the pinned player**
  (`templates/tileanim_player.asm`, 273 B: `TileAnimPlay{A}` / `TileAnimRestart{A}` /
  `TileAnimCopy{A}` — the S102 code, unchanged except that the group list comes from
  `TileAnimRoomTable{A}[E]` instead of `TileAnimRoomTable[wMapID − $6B]`) + its rooms' records,
  sequences and a 16-aligned frame section. The player's state (`wTileAnimRoom`,
  `wTileAnimState`, …) is shared by every bank — one room is on screen; a room change restarts
  the timers by map id as before.
- **Compiler:** `editor2/core/tileanim.py` plan (PROJECT_COMPILER §2.48): first fit in map id
  order, $6C then banks $80+ after the stream and place banks; a room's animations are never
  split; a room bigger than one bank is a build error.
- **Measured:** `tools/census_tile_anims.py` — the ROM tables through the directory == the model;
  stub calls of bank $6C entry 0 for every map id reach exactly the room's bank with its index;
  in the game every animated slot shows only its authored frames (S139 demo: 14 rooms over $6C
  and $82-$86). Negative control: the HBlank wait removed in the animation banks' copies only →
  6,387 bad tile-frames, all in rooms of $82+, the $6C rooms clean (so the census sees which
  copy of the player ran). No frame dropped (600 field-loop passes / 600 frames in every cave);
  the user's rooms in bank $6C play the same step sequence as the S138 build.

### Regions (S140 — ROADMAP ARC CAP3a; built S140, USER-CONFIRMED 2026-10-10)

`wMapID` is one byte and the custom place ids are `$6B-$EA` (`$EB-$FE` are free for the engine's
own use below, `$FF` ends an exit list): 128 places. A project with more puts them in REGIONS —
a custom place is (`wMapRegion`, `wMapID`). In project.json the region is the high byte of the
mapID (`$16B` = region 1's `$6B`); region 0 = the ids written before S140, later regions are
handed out by the editor (`Document.next_free_mapid`). Vanilla ids ignore the region.
- **The place number** (NEW pinned `editor2/core/templates/place_number.asm`, pasted into banks
  $60 / $6C / $71 / $76 as `PlaceNum<bank>` / `PlaceNumIn<bank>`: E = id, D = region → CF clear +
  HL = P; keeps BC): `RegionTable<bank>` = `db n_regions`, per region `db count, dw base` (each
  region's places dense from `$6B`); `GlobalPlaceIds<bank>` = the GLOBAL places (the arena
  copies: the engine knows them by bare map id at nine ROM0-routed sites, S128) — found in any
  region, as region 0's P. Every per-place table (bank $60 `PlaceDirectory`, bank $6C
  `TileAnimDirectory`, bank $71 `Custom26DDTable` / `RoomEncTable` / `CustomAnimSrcTable` /
  `CustomRoomFlagsTable` / the place song rows, bank $76 `EncRoomTable`) is indexed by P — the
  tables stay where they were (S135 had planned a place header / far copy instead). One region:
  P = `id − $6B`, the same as before. Bank $71 costs 15 B a place → ≈950 places before it binds.
- **The region changes at three points only.** (1) The room commit, bank $73 entry 0
  `RegionCommit`, right after `wInGateworld := wWarpFlag`: a LINK id `$EB + k` (an exit row
  written `$FD <region> <row>` — `CopyExitListToBuffer`, `templates/place_readers.asm`, puts the
  link id at row+2 and [region, real id] into `wExitLinks[k]`) becomes (region, real id); else a
  pending `wWarpRegion` (= region + 1) is entered — set by bank $71 `HubWarp` (the hub row's
  region byte) and by script warps (the compiler puts `write_ram wWarpRegion, region + 1` before
  op `$0F` / `$3B` and writes the real id into the warp word); else the region stays (a plain
  door inside a region, any vanilla room). Nothing re-copies the exit list between the exit
  firing and the commit (S133), and the pre-commit readers only classify the destination — a
  link id classifies as a custom room. (2) Bank $73 entry 22 `RegionEnterE` (E = region): the
  gate insert (bank $71 entry 4, the row's region at +6) and the boss floor (the bank $16
  `jr_016_5be1` S115 nops → bank $71 entry 11 `BossRegionEnter`, `GateBossRegionTable` by gate).
  (3) A load: SRAM bank 3 magic "X2" + `$A002` = `wMapRegion` (an "X1" save = region 0; a stale
  CONTINUE resets it to 0 before `HubWarp`).
- **`RegionEnter` on a change:** zeroes `wCustomStepRegional..$CFFF` (every region's step
  counters share one area, region 0's included; the reserved / explicit counters and the global
  places' sit below it — the compiler's per-region overlay, `Project.step_counter_overlay`; one
  region = the S65 layout) and drops the two caches that compare `wMapID` alone
  (`wNpcColourMap`, `wTileAnimRoom` := `$FF`).
- **Who must know the region:** an exit row into another region, or into any place from a vanilla
  or global room (whose region is whatever the player brought), carries the prefix
  (`Project.exit_prefix`); vanilla door redirects always do. `GateBossWin` (bank $76) counts a
  custom boss room only in its own region (bank $71 entry 12 `BossRegionOf`). Room songs: 107
  vanilla rows by id + one row per place; `MusicRuleTable` keys are words (a room = its vanilla id
  or `$100 + P`). ROM0 `$26DD` rows `$6B-$6F` are vanilla filler again — every place reads
  `Custom26DDTable[P]` (gate-world ids `$6B-$6F` still read the ROM0 gate table).
- **Measured:** `tools/census_regions.py` (≥ 300 places in 4 regions, every table and the commit
  by stub calls, 0 mismatched); PyBoy on the user's save (the COMPASS LODGES: map id `$76` in four
  regions, doors / stairs / script warps across regions, a battle, a region-3 save + CONTINUE,
  vanilla rooms entered from region 3). PROJECT_COMPILER §2.49; CROSSBANK_ROOMS "S140 sites".

## Key RAM Regions

| Range | Purpose |
|-------|---------|
| $C800-$C8FF | System state, UI, battle temp |
| $C900-$C9FF | Room/map state, screen index, floor, gate |
| $CA51-$CA64 | Inventory (20 item slots, empty=$00) |
| $CAC1-$D6B0 | Party/storage monsters (20 × $95 bytes) |
| $D7D2+ | NPC RAM buffer (32 bytes per NPC slot — verified: parser at $0B:477E advances with `add $20`) |
| $D8D0-$D8DF | Script engine state |
| $D92A-$D99A | Room step counters (113 addresses — one per screen; value selects which NPC/exit set loads; see ROOM_DATA_FORMAT.md "Room State System") |
| $D99B+ | Event flag bitfield |
| $D9EC | Battle phase index (18 phases; bank $50 BattlePhaseTable; S68) |
| $D9F4 | Nested battle sub-machine index (0-10; battle-scoped, NOT the main game state — S68; label wEventStateMachineIndex is historical) |
| $DA00-$DA7F | Temp: enemy stats, monster info copy, breeding vars |

## SRAM Save Layout

SaveGameState (ROM0, bank_000.asm line 6577) copies game state to SRAM:

| WRAM source | SRAM dest | Size | Contents |
|-------------|-----------|------|----------|
| $FF8A | $A003 | 33 B | HRAM (timer) |
| $C8EA | $A024 | $1100 (4352 B) | Main game state (last byte: $D9E9) |
| $C300 | $BCC8 | $0200 | Tile layout buffer |
| $C200 | $BEC8 | $0100 | GBC attribute buffer |
| $CAC1 | $A1FB | 2980 B | Party (separate SavePartyToSRAM path — NOT a second copy: $A024 + ($CAC1−$C8EA) = $A1FB, i.e. a targeted partial update of the same save image) |
| (SRAM-resident, S60) | $A3BA | $0BE5 (17×$95) | **Farm slots 3-19 (CF3, S60)** — live IN the save image at $A1FB+s*$95; never WRAM-resident anymore (vanilla window $CC80-$D664 freed). GMDP forks slots ≥3 here; walkers hop the boundary via bank $73 entry 2. EAGER together with the whole roster image $A1C7-$AD9E, which the checksum EXCLUDES; the canonicalizer tail mirrors WRAM $CA8D-$CC7F→$A1C7-$A3B9. World state stays lazy. |
| (SRAM-resident, S71) | $B124 | $0BA4 (20×$95) | **Farm slots 20-39 (FX1, S71)** — the expansion that evicted the sleep pool from this exact hole. Real home $B124+(s-20)*$95; GMDP computed window [$D665,$E208] rebases −$2541 here; stride walkers mid-hop slot 19→20 (+$0385). EAGER like the rest of the roster; **checksum v3 excludes it** (seed $4638 + $A002×$1C5 + $AD9F×$385 + $BCC8×$338; heals vanilla/S60v1/S60v2 stored sums in place). One-time **"F2" reformat gate** at $BFC8-$BFC9 (reserved-tail carve, 54 B left): migrates any sleeping pool to bank 2 then zeroes this window — ORDER load-bearing, legacy sums computed pre-stamp (KEY_LESSONS S71). Staging pseudo-slot INDICES moved 20/21→40/41 (computed [$E209,$E332] −$0BA4 → $D665/$D6FA; addresses unchanged). |
| wGateDiveGate/Mask $DEBC-$DEBD (S100) | $BFCA-$BFCB | 2 B | **Gate dive state (S100)** — once-per-dive custom gate rooms (GATE_GENERATION §7.6). Written by bank $73 entry 5's main-image detector (explicit save, BEFORE the checksum pass — inside v3 segment 3), read back by entry 6's detector at load. Reserved-tail carve after the F2 gate: $BFCC-$BFFF (52 B) left. |
| (bank 2, S71) | b2 $A010 | $1744 (40×$95) | **Farm SLEEP pool (S55; → BANK 2 in FX1/S71)** — now a FULL 40-slot non-party mirror (whole-swap at any party size), records at bank2 $A010+c*$95, magic "P1" at bank2 $A000-1. Still gated by $CA41 bit 7; accessed ONLY via bank $73 entries 10 (record swap) / 11 (zero-init+magic) / 12 (census) + entry 4's migration/.sum2 — short RAMB≠0 windows, pin-safe (S69 ISR audit). Vanilla-eager (sleep force-saves); the sleep flag rewinds in the main image, gating stale copies exactly as vanilla. |

Checksum (v3, FX1/S71): three segments $A002×$1C5 + $AD9F×$385 + $BCC8×$338 (seed $4638) → stored at $A000-$A001; excludes the eager roster image AND extended farm. Valid flag: $A002 (1 = save exists). Bank 1 = roster snapshot "R4" (dual-region: $A1BF ×95 chunks + $B124 ×94 chunks; R3 auto-upgrades). **S104 r4:** the R4 RESTORE copies $B124 ×93 chunks + 4 bytes ($B124-$BCC7) — the 94th chunk's other 28 bytes are the tile image $BCC8-$BCE3, which in bank 1 is the PREVIOUS save's (the commit runs before SaveGameState's tile block); restoring it broke checksum segment 3 (save lost after a reset). Bank 2 = sleep pool "P1". Bank 3 = the extended event flags "X1" (S117, below; $A002-$A00F and $A110+ free).

### SRAM banking as built S69 — 32 KB expansion via the RAMB PIN

**Status: BUILT S69, NOT yet user-tested.** The patched build declares 32 KB
SRAM (`HeaderRAMSize $0149 = $03`, banks 0-3) under a global **RAMB-pin
discipline**: RAMB is $00 at power-on (vanilla boot's three literal writes,
kept) and **no engine code ever changes it again** — the 19 ROM0
quadrant-convention writers (`… and $03 / ld [$4100],a` after every ROM-bank
switch: RST_18, the RST_28/30 return tail, `WriteBankSwitch4100` /
`WriteBankReg4100` / `TextSetBank` shared helpers, the tile/SGB/text
loaders, and all four audio-tick sites) are retargeted by one operand byte
each to `ld [$6100],a` — an MBC5-ignored address (vanilla itself writes
$6100 at boot; $6000-$7FFF is unmapped on MBC5). A/flags/timing identical,
so quadrant-1..3 callers that might observe the trampoline's Z flag see no
change. Every existing SRAM consumer (vanilla quadrant-0 save/sleep/trade
cluster, CF3's bank $73 entries, the CF3 walker dereferences in banks
$50/$51) therefore hits bank 0 — exactly the 8 KB cart's behavior — with
**zero changes to any consumer**.

**Why pin instead of per-entry RAMB=0 discipline (the S65 sketch):** the
vblank audio tick is RAMB-transparent *by quadrant convention, not by
value* — it saves the interrupted ROM bank (`ld a,[$4000]` / push af) and
on exit restores `RAMB := quadrant(interrupted bank)` (AudioPopSetDE).
So "establish RAMB=0 inside CF3's entry points" would NOT survive: any
vblank during a bank $73 farm scan would exit the ISR with RAMB=3. The
sound fixes were either di-bracketing every dereference window across 10+
banks, or removing the convention. The pin removes it; interrupts now
cannot move RAMB at all.

**Accessing banks 1-3 (the new +24 KB persistent headroom):** the ONLY
sanctioned path is `CF3SRAMBankedCopy` (bank $73 entry 9; mailbox
`wSRAMXferBank/Src/Dst/Len` at $DE8B-$DE91, patches/wram.asm). It copies
per byte inside `di` windows — RAMB≠0 exists only between di and the
restore-to-0 before ei, so the pin invariant (`RAMB==0` whenever IME is
on) holds at every interruptible point. Contract: call with interrupts
enabled; one side of the copy is the banked-SRAM side; SRAM↔SRAM
cross-bank is unsupported; SRAM is (re-)enabled and left enabled (CF3
policy); DE preserved, A/HL/BC per the usual rst $10 contract.
Byte-executed S69 (emitted-bytes interpreter): copies both directions,
bank isolation, len-0 no-op, DE preserved, zero invariant violations.

**Deliberately untouched RAMB writers:** boot's three `RAMB:=0` (they ARE
the pin's establishment); bank $40's `di`-bracketed 4×8 KB wipe (saves/
restores via the $FFA3 shadow, then `jp InitGameData` → boot re-zeros;
under 32 KB it now genuinely clears banks 1-3 when its $CBC6 gate fires —
its original engine-family intent); bank $20's streaming system
(`RAMB:=[$C68A]` with $FFA3 shadow) — $C68A has **no initializing writer**
in DWM1 (decrement-only, so provably 0 in any reachable execution), all
its exit paths write RAMB:=0, and under the pin its RAMB survives
interrupts *better* than under the convention. Residual, not a hazard.

**Old saves:** an 8 KB .sav loads padded (SameBoy honors the header).
**Bank 1 is now claimed (S69v2): the "R3" roster snapshot** — magic
$52,$33 at bank1 $A000-$A001, snapshot region $A1BF-$AD9E, written by the
explicit-save funnel and restored at load; it self-seeds on first load of
a pre-v3 save (see MONSTER_DATA "Persistence model (v3)"). Banks 2-3
remained uninitialized and unclaimed — any future consumer brings its own
format/magic (S71: bank 2 = the sleep pool "P1"; S117: bank 3 = the extended
flags "X1", below). The CF3 checksum covers bank-0 regions only, unaffected.
**Pin invariant, stated precisely (S69v2):** RAMB==0 except inside
CF3-owned banked-access windows — entry 9's per-byte di brackets, and the
entry 5/6 snapshot hooks' ~200-cycle chunk windows, which need no di/ei
because the ISR graph neither reads SRAM nor writes RAMB (audited S69:
vblank audio has zero SRAM literals; LCDC is display-only; timer is reti;
serial is inactive in save/load contexts and pin-safe regardless). Entry 9
remains the conservative any-context primitive for future code.

### SRAM bank 3 (S117) — the extended event flags "X1"

**Built S117, PyBoy-verified, NOT yet user-tested.** Bank 3 `$A000-$A001` = magic
`$58,$31` ("X1"), `$A010-$A10F` = a copy of `wExtFlags` ($D140-$D23F, flags
`$1000-$17FF`; EVENT_FLAGS "Extended flags (S117)"). Written by bank $73
`ExtFlagsCommit`, called from entry 5's main-save detector right before its
`CF3SnapCommit` tail (the explicit save); read by `ExtFlagsRestore`, called from entry
6's main-load detector after its zero-fill of $CC80-$D664 and before the
`CF3SnapRestore` tail — copied back only when the magic is present (a pre-S117 save
loads with every extended flag clear). Both write RAMB = 3 for a 256-byte loop and
restore RAMB = 0, the same no-di chunk window as the entry 5/6 snapshot hooks (pin
invariant above: the ISR graph neither reads SRAM nor writes RAMB). Outside the CF3
checksum (bank 0 only), like banks 1-2. Free in bank 3: `$A002-$A00F`, `$A110-$BFFF`.
**S140 (ARC CAP3a, USER-CONFIRMED 2026-10-10):** magic "X2" (`$58,$32`) = "X1" + `$A002` =
`wMapRegion` (the region the save stands in; "Regions (S140)" above); `ExtFlagsRestore` accepts
both ("X1" → region 0). Free in bank 3 now: `$A003-$A00F`, `$A110-$BFFF`.

**What remains open in E3** (see ROADMAP): (a2) new-game INIT data as an
authorable object; (b2) story-variable headroom schema on top of the new
banks (allocation map + init/versioning convention for banks 1-3).

#### The S65 audit that motivated the pin (historical, all instruction-verified)

Cartridge header: MBC5+RAM+BATTERY (`$0147=$1B`), RAM size `$0149=$02` =
**8 KB, one bank**. The map above occupies $A000-$BFC7; native persistent
headroom = the tail **$BFC8-$BFFF (56 B)** (carved since: $BFC8-9 the F2 gate S71, $BFCA-B the gate dive state S100 — $BFCC-$BFFF, 52 B, left). A romhack can declare 32 KB
(`$0149→$03`, banks 1-3 = +24 KB persistent) — MBC5 supports it, SameBoy
honors the header, old 8 KB .sav files load padded — **but the engine is
NOT expansion-ready as-is**. S65 audit findings (all instruction-verified):

* **RST_18 sets RAMB on every `rst $10`**: the dispatcher tail
  (`ROM0 $0018`: `swap a / rra / and $03 / ld [$4100],a`) writes
  `RAMB := rom_bank>>5` — quadrant convention $00-$1F→0, $20-$3F→1,
  $40-$5F→2, $60-$7F→3. Dead store on the 8 KB cart (only bank 0 exists);
  LIVE bank switching at 32 KB.
* **`$FFA3` is the RAMB shadow**; disciplined multi-bank SRAM code exists
  in vanilla: bank $40 `jr_040_41a5` region `di`s, then wipes $A000×$2000
  across RAMB 0/1/2… with save/restore via $FFA3 — proof the engine family
  carries genuine 32 KB SRAM infrastructure (gated on `$CBC6`). bank $20
  has 4 more $FFA3-shadowed `[$4100]` writers. All other `$4000-$5FFF`
  "write" hits repo-wide are data-as-code junk.
* **Vanilla's live SRAM users all run from quadrant 0** (banks $00/$01/$07/
  $0A/$12/$15/$18 — save, sleep pool, trade, image copy), so RST_18 leaves
  them on RAMB 0 correctly. **CF3 runs from bank $73 → RAMB=3** under
  expansion: every farm access would hit the wrong bank.
* **The audio ISR dispatches into bank $74 every vblank while music plays**
  (`AudioMasterTableExt` row $9E) → RAMB flips to 3 mid-anything. Any SRAM
  access that isn't `di`-bracketed (CF3's hot paths are not; vanilla's
  save cluster is quiesced, the bank $40 wipe `di`s) can be torn.

**Consequently, expansion requires (E3 scope, one session):** RAMB=0
(re)establishment inside CF3's SRAM entry points (bank $73 entries 3/5/6/7/8
+ the GetMonsterDataPtr fork path) with interrupt discipline (di/ei bracket
or per-access set+access within uninterruptible windows), an accessor
convention for new banked state, and a boot RAMB=0 init audit (vanilla
already writes 0 at boot, bank_000 ~294-304). Do NOT flip `$0149` without
this — the failure mode is silent farm/save corruption.
**[SUPERSEDED S69 — do not build this sketch.** The per-entry approach is
insufficient: the ISR restores RAMB by quadrant recomputation of the
interrupted bank, clobbering any in-bank-$73 establishment, and the
$50/$51 walker dereferences were outside this sketch's surface. The built
design is the RAMB pin — see the as-built section above and DOC_AUDIT
S69.**]**

The main save range $C8EA-$D9E9 covers step counters ($D92A-$D99A), most event
flags ($D99B-$D9E9), inventory, gold, and the party records ($CAC1-$CC7F).
**The CF3-freed window $CC80-$D664 inside it is EXCLUDED from save AND
restore** (its SRAM image $A3BA-$AD9E is the live farm — CF3CopyToSRAM/
CF3CopyFromSRAM skip it both ways, bank $73 entries 5/6). S65 layout of the
window: `wCustomNPCBuffer` $CC80 / `wCustomExitBuffer` $CD00 / step-counter
region $CD80-$CFFF (compiler-owned, 640 B) / `wCustomPool` $D001-$D664
(transient reserve; carved since — FX1 wMonList/wPoolBounce, S97 r2 box-attr
saves; current map in known_RAM_map). Init guarantee: ClearAllWRAM (power-on) +
CF3NewGameClear (new game) + the S65 entry-6 tail-clear (after the
main-image restore copy) — gameplay always starts with the window zeroed.
**Flags at byte $D9EA+ (indices $0278+) are OUTSIDE the save range and will NOT
persist.** The custom scratch block at $DE74-$DE8A (wRoomRecScratch $DE7B,
wRoomEncFlag, Tame vars, wCustomRoomFlag, CF3 mailbox) is also outside the
save range — transient BY DESIGN (persistent room state = event flags +
entry scripts, user decision S55, reaffirmed S65).

### Flag byte collisions

Several named RAM variables share bytes with the event flag bitfield. The editor
must skip these flag index ranges when allocating custom flags:

| RAM addr | Flag indices | Variable |
|----------|-------------|----------|
| $D9CB | $0180-$0187 | (unverified name) |
| $D9CD | $0190-$0197 | Current Coliseum Battle |
| $D9CF-$D9D6 | $01A0-$01DF | Gate room reset counters |
| $D9E3 | $0240-$0247 | Story progression counter |
| $D9E6 | $0258-$025F | Breeding "rare breed" flag (never set — the mutation $16:$44DA is unreferenced, S113) |
| $D9E9 | $0270-$0277 | Current step in multi-step screens |

**Safe pool for custom flags (S57 audit, current): 32 flags = $0158-$0167
(bytes $D9C6-$D9C7) + $01E0-$01EF (bytes $D9D7-$D9D8).** The old claim of a
40-flag contiguous block $0158-$017F was pre-CF2: wPendingFarmExp took
$D9C8-$D9CA (= flags $0168-$017F) in S57 (DOC_AUDIT S69). Broader reuse of
the $0158-$0277 range requires excluding the collision rows above AND the
CF2 accumulator. Structural headroom beyond 32 flags = SRAM banks 1-3
(E3 pin, above) once a storage schema exists.
