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

## DTE (Dual-Tile Encoding) — $65-$7F

Single bytes expanding to common 2-character pairs:

| Code | Pair | Code | Pair | Code | Pair |
|------|------|------|------|------|------|
| $65 | ll | $6E | he | $77 | ou |
| $66 | 'l | $6F | be | $78 | te |
| $67 | 't | $70 | or | $79 | nd |
| $68 | 's | $71 | an | $7A | to |
| $69 | 'r | $72 | in | $7B | it |
| $6A | 'm | $73 | er | $7C | es |
| $6B | n' | $74 | re | $7D | at |
| $6C | 'v | $75 | on | $7E | en |
| $6D | th | $76 | st | $7F | al |

## Control Codes ($E0+)

| Code | Name | Purpose |
|------|------|---------|
| $E7 | **CHOICE** | **YES/NO box + continuation flags. NOT "END".** Sets $C83C, $C83A=$FF. Script checks result via opcode $15. |
| $E8 | PAUSE | Brief pause |
| $E9 | NUM | Insert number from variable |
| $EA | BOX | Text box init (2 param bytes: $9F $A3 = standard NPC box) |
| $EB | BOX2 | Alternate text box init (same params as $EA) |
| $EC | NAME | Insert NPC/character name |
| $ED | MONSTER | Insert monster name |
| $EE | NEWLINE | Line break — **MUST be preceded by $EF** or overwrites line 1 |
| $EF | PAGE | Advance rendering position. Use `$EF $EE` together for line breaks |
| $F0 | SECTION | End text section. Stops rendering (unless bit 4 of $C825 set) |
| $F6 | HERO | Insert player's name |
| $F7 | CLEAR | Clear text box contents |
| $F9 | CONTINUE | Set continuation flag (bit 4 $C825), update base pointer |
| $FA | WAIT | Wait for A button press |
| $FF | CHOICE2 | YES/NO box only, does NOT set continuation flags |

**Text strings terminate with `$F7 $F0` (CLEAR + SECTION), NOT `$E7`.**

### Standard NPC Text Format (verified)
```
$EA $9F $A3 line1_text $EF $EE line2_text $F7 $F0
```

### YES/NO Choice (two-part system, verified)
Text ends with `$EF $EE $E7 $F0`. Script then checks `$C83C` via opcode `$15`:
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

Total: **2067 text IDs**. All decoded in `extracted/text_id_map.json`.

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

- `extracted/text_id_map.json` — 2067 text IDs → decoded English, exact bank/index
- `extracted/decoded_text.json` — 1374 text strings organized by handler bank


## Bank $56 Text Control Code Jump Table

Located at `$56:$44CD` (after `sub $E0` / `rst $00` at `$44CB`).
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
| 0 | `$400B` | detail line 1 — name template (`$F6` insert) | 256 |
| 1 | `$420B` | detail line 2 — **per-species description** | **215** (0–214) |
| 2–6 | `$43CE…` | small routine targets (not per-species tables) | n/a |
| 7 | `$442D` | large blob | — |

**Bank `$41` `$4007` mode bases line up with the named tables in `DATA_STRUCTURES.md`:**
mode 5 → `MonsterNamePtrTable` (`$4339`, 256), mode 6 → `SkillNamePtrTable`
(`$4539`, 256), mode 7 → `FamilyCodePtrTable` (`$4739`, **215**). Modes 0–4 are
the fixed-size dispatch tables (misc/item/spell, etc.).

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
