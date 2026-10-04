# Bank $04 — NPC Script Engine Architecture

## Overview

Bank $04 is the heart of DWM1's NPC interaction system. It contains a **complete scripting virtual machine** with 102 opcodes ($00-$65; S96 — the long-quoted "100" missed $64/$65) that drives all NPC dialogue, cutscenes, story events, and in-game scripted sequences.

Every time the player talks to an NPC, enters a room with a scripted event, or triggers a cutscene, bank $04's script engine executes a program stored in one of four script data banks ($0C/$0D/$0E/$0F).

## Entry Points (via `rst $10`, H=$04)

| Entry | Address | Name | Purpose |
|-------|---------|------|---------|
| 0 | $400F | NPCSpriteLoad | Load NPC sprites into OAM via $0D91 |
| 1 | $4016 | NPCSpriteLoadAlt | NPC sprite load variant via Call_004_40cd |
| 2 | $4081 | NPCInteractDispatch | Route NPC interactions by $FFC7 |
| 3 | $40A7 | NPCInteractDispatchB | Interaction routing variant |
| **4** | **$4167** | **NPCFrameUpdate** | **Per-frame NPC state machine (MAIN)** |
| **5** | **$55EC** | **ScriptInit** | **Initialize & execute NPC script** |
| **6** | **$56FA** | **TextQueueCheck** | **Dispatch queued text to ROM0** |

Entries 4, 5, and 6 are the core of the system.

## Architecture: The Script VM

### Script Data Flow

```
Player talks to NPC → Game sets $D8DC (NPC number), $D8D3 (map type)
  → Entry 5 (ScriptInit) called
    → Resets script counter ($D8D5/$D8D6 = 0)
    → Calls ScriptDataRead (Call_004_71ef)
      → Dispatches to bank $0C/$0D/$0E/$0F entry 0 based on $D8D3
        → Script bank reads counter, returns next BC pair
    → Dispatch:
      BC == $FFFF → Script ended, clear all state
      B != $FF   → BC is a 16-bit text ID → queued to $D8D9/$D8DA
      B == $FF   → C is an opcode → dispatched via rst $00 to command table
```

### Per-Frame Execution (Entry 4)

Entry 4 runs every frame and manages the script state machine:

```
NPCFrameUpdate ($4167):
  1. Guard: wGameState, $C850 busy, $C825 UI busy → return if any set
  2. Check $D8D7 bit 0 (script active) → return if not running
  3. Check $D8D7 bit 1 (text queued) → return if waiting for text display
  4. Handle pending operations:
     - Bit 4/6: NPC position updates (Call_004_43ec)
     - Bit 2: Delay countdown ($D8DB)
     - Bit 3: NPC walk-toward (Jump_004_41e0 → Jump_004_42cd)
  5. If nothing pending: call ScriptExecContinue → next command
```

### Script Counter

The script counter at $D8D5/$D8D6 (16-bit) tracks position within the script data. Each time a command is read, the counter is incremented. Branch commands modify the counter to jump forward or backward.

## Script State Flags ($D8D7)

S118 rewrite (handler code + PyBoy; the old rows for bits 3/4/6 were guesses):

| Bit | Meaning | Set by | Cleared by |
|-----|---------|--------|------------|
| 0 | Script is active | MarkScriptActive ($5613) | Script end ($FFFF); a room change ($0F/$3B/$43/$4F/$58) clears the whole byte |
| 1 | Text ID queued | TextIDQueue ($56EC) | TextQueueCheck ($5700) |
| 2 | Delay active ($09): `$D8DB` counts down once every 8 frames (only when `[$C8A4] & 7 == 0`) | ScriptCmd09_Delay | Entry 4 |
| 3 | A walk the script WAITS for ($0A/$0B/$10/$11): actor `$D8DC` moves by `$D8DD`/`$D8DF` px, 1 px on 3 frames of 4 (skips `[$C8A4] & 3 == 1`), facing follows unless bit 5 | those ops | Entry 4 when both deltas reach 0 |
| 4 | Movement programs queued ($1A/$1B/$1C: buffers `$D8E9 + 8n`) | those ops | `MoveProgramsAll` when every buffer is idle |
| 5 | Lock facing: walks / programs do not turn the actors | $1D | $1E |
| 6 | **walk_fast** ($22): `MoveProgramsAll` runs a SECOND time per frame = double speed (32 px: 44 → 22 frames) | $22 | with bit 4, when every buffer is idle |

`$D8D8` (secondary flags, S118): bit 0 = the next text box opens at the BOTTOM
($3C), bit 1 = at the TOP ($3D) — read and cleared by bank $06's box placer
(bank $06, just before `jr_006_686e`; otherwise the box goes opposite the player); bit 2 = long delay
($4D): `$D8DB` counts down every Entry-4 call.

## Script Data Banks

`Call_004_71ef` (ScriptDataRead) dispatches to script data banks based on $D8D3 (map type copy):

| $D8D3 Range | Bank | Rooms Covered |
|-------------|------|---------------|
| < $06 | $0C | Castle ($00), GreatTree ($01), Bazaar ($02), GateHub ($03), Farm ($04), Stable ($05) |
| $06–$1F | $0D | Arena ($06/$07), special rooms ($08-$1F) |
| $20–$3F | $0E | Gate entrance rooms ($23-$2E), boss rooms ($30-$3F) |
| ≥ $40 | $0F | Labyrinth ($42), arena battles, post-game content |

Each bank's entry 0 uses the script counter ($D8D5/$D8D6) to look up the next command in its internal script data tables.

### Custom-room divert hook on the bank-$0F path (and the gate-freeze fix)

The crossbank custom-room system hooks the `≥ $40 → bank $0F` dispatch
(`DispatchBank0F` at `$04:$720d` → handler `DispatchBank0F_Ext` in padding at
`$7fd8`) so that **custom-room** scripts are diverted to bank `$60` instead of bank
`$0F`. Gate world reaches this path with `wScriptMapType = $70` (hardcoded by the
gate-world room-entry path in bank `$01`); labyrinth/arena/post-game use `$40–$6A`.

⚠️ **The divert must key off `wMapID`, NOT `wScriptMapType`.** A custom room is the
only thing with `wMapID ≥ CUSTOM_ROOM_START ($6B)`; a gate keeps a normal `wMapID`
(e.g. `$0D`) even though its *script* map-type is `$70`. The original hook tested
`wScriptMapType ≥ $6B`, which wrongly captured gate world (`$70`) and diverted live
gate scripts into bank `$60` → garbage → **gate-entry freeze** (idle loop at ROM0
`$02e2`, `$C88E` never set). It also looped `$720d↔$7fd8` for `$40–$6A`.

**Current (fixed) flow:** `DispatchBank0F_Ext` is a same-size redirect
(`ld hl,$6006; rst $10; ret`) to **bank `$60` entry 6 `GateAwareDispatch`**, which
reads `wMapID`: `< $6B` → real bank-`$0F` dispatch (`ld hl,$0f00; rst $10`); `≥ $6B`
→ `CustomScriptRead`. See `documentation/GATE_FREEZE_FIX.md`. (Latent regression since
`3d94ad9`; loop variant added in `d564e7e`.)

## Text System Integration

When the script emits a text ID (B != $FF in the BC pair):

```
Script emits BC as text ID
  → TextIDQueue ($56EC): stores C→$D8D9, B→$D8DA, sets $D8D7 bit 1
  → Entry 4 sees bit 1 set → returns (waits for text display)
  → Entry 6 (TextQueueCheck) called:
    → Loads text ID from $D8D9/$D8DA into HL
    → Calls ROM0 $0AD9 (TextDispatchCascade)
      → Routes by text ID range to handler banks $42-$4E
        → Handler bank calls into text data banks ($18,$1A,$1B,$1F,$21,$22,$3F)
  → Text displayed → $D8D7 bit 1 cleared
  → Entry 4 resumes script execution next frame
```

This means the script VM pauses for one or more frames while text is being displayed, then resumes automatically.

## Parameter counts — handler-derived, ALL 102 opcodes (S96)

**Source of truth: `extracted/script_param_counts.json`, produced by
`tools/script_param_counts.py` (verify_integrity check 5 selftest).** Every
handler consumes a parameter word by INCREMENTING the 16-bit script counter
(`ld a,[wScriptCounter] / add $01 / … / adc $00 / ld [$D8D6],a`) — usually
followed by `call MapTypeDispatch` to read it, but a handler may skip a word
without reading it, so counting reads under-counts (the tool's first pass
did). The tracer walks each handler over the ROM bytes (jr/jp both edges,
bank-$04 calls inlined) and stops at the three tails:

* `jp ScriptExecContinue` (`$04:$55F5`) — counter+1, fetch the next op;
* `jp ScriptReturnProcess` (`$04:$7212`) — BRANCH: counter += (BC−HL)/2,
  BC = the last parameter read (an absolute script address);
* `ret` — the op yields; Entry 4 continues next frame (ScriptExecContinue).

Every opcode has exactly ONE arity (no path-dependent counts). Handlers that
write the counter without a branch tail (`$19`, `$46`, `$4C`, `$65`)
decrement it to re-run themselves next frame (wait loops). The table below
agrees with every handler/PyBoy-verified row (scriptgen `OPS`, the S92
`$27`/`$21` overrides) and CORRECTS 36 rows of
`tools/decompile_script.py` PARAM_COUNTS (+2 missing opcodes) — that table is
what `extract_room.py` used through S95 (DOC_AUDIT S96). Consistency proof:
with these counts every script of all 98 vanilla rooms decodes with every
branch target on an op boundary (test_canvas "all clones").
Caveat: cross-bank calls (`rst $10`) are opaque to the tracer; the all-rooms
decode proof is what rules out a hidden increment there.

| Op | Handler | Params | Tail(s) | Kind | vs decompiler |
|----|---------|--------|---------|------|---------------|
| $00 | $5711 | 2 | branch/continue | **branch** (last param = target) |  |
| $01 | $5740 | 2 | branch/continue | **branch** (last param = target) |  |
| $02 | $576F | 1 | continue |  |  |
| $03 | $5788 | 1 | continue |  |  |
| $04 | $57A1 | 2 | ret |  |  |
| $05 | $57EB | 1 | ret |  |  |
| $06 | $5819 | 0 | ret |  |  |
| $07 | $5824 | 0 | ret |  | decompile_script said 1 |
| $08 | $5842 | 0 | ret |  |  |
| $09 | $5843 | 1 | ret |  |  |
| $0A | $5860 | 2 | ret |  |  |
| $0B | $5898 | 2 | ret |  |  |
| $0C | $58D0 | 2 | continue |  | decompile_script said 3 |
| $0D | $5968 | 3 | continue |  |  |
| $0E | $59D2 | 2 | branch/continue | **branch** (last param = target) |  |
| $0F | $5A02 | 3 | ret |  |  |
| $10 | $5A6F | 2 | ret |  |  |
| $11 | $5AC5 | 2 | ret |  | decompile_script said 4 |
| $12 | $5B1B | 2 | continue |  |  |
| $13 | $5B49 | 2 | continue |  |  |
| $14 | $5B79 | 1 | branch | **branch** (last param = target) |  |
| $15 | $5B8F | 3 | branch/continue | **branch** (last param = target) |  |
| $16 | $5BD4 | 0 | ret |  |  |
| $17 | $5BDB | 0 | ret |  | decompile_script said 1 |
| $18 | $5C14 | 1 | ret |  | decompile_script said 0 |
| $19 | $5C6D | 0 | continue/ret | self-repeat (counter−1, waits) |  |
| $1A | $5C86 | 2 | continue |  |  |
| $1B | $5CCF | 2 | continue |  |  |
| $1C | $5D1A | 1 | continue |  |  |
| $1D | $5D4B | 0 | continue |  |  |
| $1E | $5D53 | 0 | continue |  |  |
| $1F | $5D5B | 0 | ret |  |  |
| $20 | $5E5E | 0 | ret |  | decompile_script said 1 |
| $21 | $5E6D | 1 | continue |  | decompile_script said 2 |
| $22 | $5E87 | 0 | continue |  |  |
| $23 | $5E8F | 2 | branch/continue | **branch** (last param = target) | decompile_script said 0 |
| $24 | $5F13 | **1** (S118) | ret |  | the word is read by the SCRIPT BANK's entry 1 (`ScriptBank0CDrawTiles`, rst $10): opaque to the S96 tracer — now followed (`cross_bank`) |
| $25 | $5F36 | 0 | continue |  |  |
| $26 | $5F52 | 0 | ret |  |  |
| $27 | $5F5C | 0 | continue |  | decompile_script said 1 |
| $28 | $5F67 | 1 | branch/continue | **branch** (last param = target) |  |
| $29 | $5F9A | 1 | ret |  |  |
| $2A | $5FDB | 1 | ret |  |  |
| $2B | $6002 | 1 | branch/continue | **branch** (last param = target) |  |
| $2C | $6064 | 1 | branch/continue | **branch** (last param = target) |  |
| $2D | $6093 | 1 | ret |  |  |
| $2E | $61E0 | 1 | continue |  |  |
| $2F | $623A | 1 | continue |  | decompile_script said 2 |
| $30 | $6253 | 2 | branch/continue | **branch** (last param = target) | decompile_script said 1 |
| $31 | $62AB | 1 | branch/continue | **branch** (last param = target) | decompile_script said 2 |
| $32 | $62DD | 2 | branch/continue | **branch** (last param = target) | decompile_script said 1 |
| $33 | $6332 | 1 | continue |  | decompile_script said 2 |
| $34 | $634F | 2 | branch/continue | **branch** (last param = target) | decompile_script said 0 |
| $35 | $63BB | 0 | continue |  |  |
| $36 | $63C6 | 0 | ret |  | decompile_script said 1 |
| $37 | $6401 | 1 | continue |  | decompile_script said 2 |
| $38 | $643F | 2 | branch/continue | **branch** (last param = target) | decompile_script said 1 |
| $39 | $64A7 | 1 | continue |  | decompile_script said 0 |
| $3A | $64C2 | 0 | ret |  | decompile_script said 3 |
| $3B | $65AB | 3 | ret |  | decompile_script said 0 |
| $3C | $6618 | 0 | continue |  |  |
| $3D | $6620 | 0 | continue |  |  |
| $3E | $6628 | 0 | ret |  |  |
| $3F | $6632 | 0 | continue |  | decompile_script said 2. S120: `load_lead_name` — the first party monster's SPECIES name (mode 5) into $C180 = text `$F9 $00`; the compiler emits it before every text with `{lead}` (PROJECT_COMPILER §2.3) |
| $40 | $6646 | 2 | branch/continue | **branch** (last param = target) | decompile_script said 1 |
| $41 | $669D | 1 | continue |  | decompile_script said 2 |
| $42 | $66BD | 2 | continue |  | decompile_script said 0 |
| $43 | $6723 | 0 | ret |  |  |
| $44 | $676F | 0 | ret |  |  |
| $45 | $67B1 | 0 | continue |  |  |
| $46 | $67FD | 0 | continue/ret | self-repeat (counter−1, waits) | decompile_script said 1 |
| $47 | $6822 | 1 | continue |  |  |
| $48 | $684D | 1 | continue |  |  |
| $49 | $6866 | 1 | continue |  |  |
| $4A | $687F | 1 | continue |  | decompile_script said 0 |
| $4B | $6898 | 0 | continue |  |  |
| $4C | $68A1 | 0 | continue/ret | self-repeat (counter−1, waits) | decompile_script said 1 |
| $4D | $68BA | 1 | ret |  | decompile_script said 0 |
| $4E | $68D7 | 0 | continue |  |  |
| $4F | $690B | 0 | ret |  |  |
| $50 | $6957 | 0 | continue |  |  |
| $51 | $696C | 0 | continue |  |  |
| $52 | $69A9 | 0 | ret |  |  |
| $53 | $6A61 | 0 | continue |  |  |
| $54 | $6ACE | 0 | continue |  |  |
| $55 | $6AFA | 0 | continue |  |  |
| $56 | $6B3A | 0 | continue |  |  |
| $57 | $6B73 | 0 | continue |  |  |
| $58 | $6BA0 | 0 | ret |  | decompile_script said 1 |
| $59 | $6BDF | 1 | continue |  |  |
| $5A | $6D56 | 1 | ret |  | decompile_script said 0 |
| $5B | $6D84 | 0 | ret |  |  |
| $5C | $6D93 | 0 | continue |  |  |
| $5D | $6F64 | 0 | continue/ret |  | decompile_script said 2 |
| $5E | $6F89 | 0 | continue |  | decompile_script said 1 |
| $5F | $6F9B | 2 | branch/continue | **branch** (last param = target) | decompile_script said 0 |
| $60 | $6FFB | 1 | branch/continue | **branch** (last param = target) | decompile_script said 0 |
| $61 | $7038 | **1** (S118) | ret |  | read by the script bank's entry 2 (`ScriptBank0CDrawAttrs`) — see $24 |
| $62 | $705B | 0 | ret |  | decompile_script said 1 |
| $63 | $707F | 0 | ret |  |  |
| $64 | $70D5 | 1 | branch/continue | **branch** (last param = target) | missing from decompile_script |
| $65 | $71D2 | 0 | continue/ret | self-repeat (counter−1, waits) | missing from decompile_script |

`$64` BranchIfPartyHealthy (target): for each party slot < `$CA8D`, not KO
(`$CB0B`=0), HP full (`$CB13`==`$CB11`), MP full (`$CB17`==`$CB15`) → branch;
any failure → continue (the Priest gate floor `$51`). `$65` WaitDD80: re-runs
until `[$DD80] & [$DD9A] == $FF` (intro bedroom `$2F`). Annotated in
disassembly/bank_004.asm (catalog + `ScriptCmd64_BranchIfPartyHealthy`,
`ScriptCmd65_WaitDD80`, `ScriptReadTargetAndBranch`, `ScriptContinueNoBranch`).

**Script data bank per map type** (MapTypeDispatch; master table at `$41BA`
in EVERY script bank, indexed by the FULL map type, rows outside the bank's
range are filler): `< $06` → `$0C`, `< $20` → `$0D`, `< $40` → `$0E`,
else `$0F`. Per-map pointer lists are packed back to back — a map's list
ends where the next in-range map's list begins.

## Script Command Reference (102 opcodes, $00–$65) — S118 rewrite

Names = the editor's (`editor2/core/script_ops.py`, used by the Cutscenes tab; the
compiler keeps its own `scriptgen.OPS` names, e.g. `trigger_battle3` = $5A). Handlers
are labelled `ScriptCmdNN_Name` in bank_004.asm (both trees, S118). The tables below
this one (S101 corrections, the evaluator family) add detail; where an older table
disagrees, this one is the measured / handler-read truth (DOC_AUDIT S118).

| Op | Name (params) | Kind | What it does |
|----|---------------|------|--------------|
| $00 | `if_flag_clear`(flag, target) | flow | Go to target when the event flag is CLEAR (else carry on). |
| $01 | `if_flag_set`(flag, target) | flow | Go to target when the event flag is SET. |
| $02 | `clear_flag`(flag) | state | Clear an event flag. |
| $03 | `set_flag`(flag) | state | Set an event flag. |
| $04 | `open_screen`(kind, text) | screen | Open a game screen of bank $09 (0 / 12 = the shop, 4 = the arena class menu, …) speaking with the text id; plays sound $59 unless kind is 9 or 10. |
| $05 | `battle`(enemy) | battle | Fight one enemy (enemy-stats row). A win resumes the script; a loss sends you to the Castle. |
| $06 | `close_text`() | text | Close the open text box. |
| $07 | `init_dialog`() | text | Open dialog mode (needed before text in a script that did not start by talking to someone). |
| $08 | `nop`() | flow | Nothing (one tick). |
| $09 | `delay`(ticks) | wait | Wait. Counts down once every 8 frames (field mode; PyBoy S118). |
| $0A | `walk_x_wait`(actor, pixels) | actor | One actor walks left/right by pixels; the script waits for it. 3 px per 4 frames. |
| $0B | `walk_y_wait`(actor, pixels) | actor | One actor walks up/down by pixels; the script waits for it. |
| $0C | `face`(actor, direction) | actor | Turn an actor: 0 down, 1 left, 2 up, 3 right (0 = the player). |
| $0D | `npc_write`(actor, field, value) | actor | Write one byte of an actor's RAM slot. Field 0 is the type byte: $00 = shown, $40 = hidden (bit 6). Actor 0: the field word is an ADDRESS ($FF90 = the player's flags; $40 hides the player). |
| $0E | `branch_screen`(screen, target) | flow | Go to target when the current screen is this one. |
| $0F | `map_transition`(map, x, y) | world | Change room: map (low byte; high byte = the gate flag) and the arrival in absolute pixels. Ends the script. |
| $10 | `walk_to_x`(actor, x) | actor | One actor walks to an absolute pixel X; the script waits. |
| $11 | `walk_to_y`(actor, y) | actor | One actor walks to an absolute pixel Y; the script waits. |
| $12 | `write_ram`(address, value) | state | Write a byte to RAM (step counters, story variables …). |
| $13 | `write_ram2`(address, value) | state | Write a 16-bit word to RAM. |
| $14 | `goto`(target) | flow | Go to target. |
| $15 | `check_and_branch`(address, value, target) | flow | Go to target when the RAM byte equals value (YES/NO answers are $C83C: 0 = YES). |
| $16 | `refresh_sprites`() | screen | Redraw the sprites and the screen position (one tick). |
| $17 | `bedroom_tile_swap`() | screen | Intro bedroom only (screens 4/5): swap tiles $9380<->$9360 and $9600<->$9620 (the night look). |
| $18 | `give_monster`(enemy) | party | A monster built from the enemy row joins (party if fewer than 3). |
| $19 | `wait_movement`() | wait | Wait until every queued movement / animation has finished. |
| $1A | `npc_walk_x`(actor, pixels) | actor | Queue a left/right walk for an actor (actors walk together; use wait_movement). 3 px per 4 frames, double with walk_fast. |
| $1B | `npc_walk_y`(actor, pixels) | actor | Queue an up/down walk (after a queued X walk of the same actor). |
| $1C | `trigger_anim`(program_actor) | actor | Run movement program $PP on actor $NN (word $PPNN): jumps, hops, flights, appearing / vanishing … (PROGRAMS). Use wait_movement. |
| $1D | `lock_movement`() | actor | Walks and programs no longer turn the actors (walk backwards). |
| $1E | `unlock_movement`() | actor | Walks turn the actors again. |
| $1F | `arena_setup`() | battle | Set the arena team from wArenaGroup / wColiseumBattle. |
| $20 | `start_battle`() | battle | Start the battle already set up ($DA02-$DA08). |
| $21 | `sound`(sound) | sound | Play a sound effect. |
| $22 | `walk_fast`() | actor | The next queued walks run at double speed (until they finish). |
| $23 | `if_slot_skill_a`(slot, target) | flow | Go to target when party monster slot knows one of skills $00-$05/$44/$5C-$5F (its name to $C180). |
| $24 | `draw_tiles`(data) | screen | Draw a tile patch (data = address in this script bank) onto the visible background. |
| $25 | `remove_monster`() | party | Remove the monster picked by the last party check ($D8E1). |
| $26 | `reload_room`() | world | Reload the room. |
| $27 | `refresh_party`() | party | Re-count the party (bank $01 entries 9 + 3). |
| $28 | `if_storage_full`(target) | flow | Go to target when all 20 monster slots are taken. |
| $29 | `add_monster`(enemy) | party | Add a monster (enemy row) to the farm. |
| $2A | `give_item`(item) | item | Give an item. |
| $2B | `if_monster_pedigree`(target) | flow | Go to target when a stored monster of level 10+ matches the 8 bytes at $04:$605C. |
| $2C | `check_inv_full`(target) | flow | Go to target when the bag (20) is full. |
| $2D | `monster_slot_dialogue`(slot) | text | Say the family line of party monster slot (arena lobby). |
| $2E | `pick_from_table`(row) | state | $D9E0 := table $04:$620D[row*5 + $D9DF - 1]. |
| $2F | `inc_ram`(address) | state | Add 1 to a RAM byte. |
| $30 | `if_slot_stat_100`(slot, target) | flow | Go to target when party slot's $CB19 word >= 100. |
| $31 | `if_seen_100`(target) | flow | Go to target when 100+ species are marked in the library. |
| $32 | `if_slot_species_af`(slot, target) | flow | Go to target when party slot is species $AF. |
| $33 | `compare_gold`(amount) | state | Compare the gold with amount. |
| $34 | `if_slot_skill_b`(slot, target) | flow | Go to target when party slot knows skill $0F/$10/$11/$45/$5A. |
| $35 | `refresh_party2`() | party | Re-count the party. |
| $36 | `mimic_battle`() | battle | Fight the Mimic of the current arena tier. |
| $37 | `give_stored_item`(index) | item | Give the item stored at $D9CF + index (name to $C180). |
| $38 | `if_slot_skill_c`(slot, target) | flow | Go to target when party slot knows skill $84-$87. |
| $39 | `load_text`(text) | text | Resolve a text id (TextBankDispatch) without showing it. |
| $3A | `to_breeding_scene`() | world | Go to the breeding ceremony (map $08) with the chosen monster. |
| $3B | `warp_fade`(map, x, y) | world | Change room with the wavy fade (the boss-win exit). |
| $3C | `text_box_bottom`() | text | The next text box opens at the BOTTOM of the screen (one box; $D8D8 bit 0, read by bank $06). |
| $3D | `text_box_top`() | text | The next text box opens at the TOP of the screen ($D8D8 bit 1). |
| $3E | `change_game_mode`() | screen | Fade out and switch to the game mode in $C88B (e.g. a naming screen) — $C88E is the main loop's mode request. |
| $3F | `load_lead_name`() | text | Put the first party monster's name in $C180 for the next text. |
| $40 | `if_party_has_species`(species, target) | flow | Go to target when a monster of that species is in the party. |
| $41 | `set_bgm`(song) | sound | Play a song (the current one is kept for restore_bgm). |
| $42 | `save_return_point`(text, actor) | world | Remember this room and the player's spot / facing for a return (the text and actor are used by $44 on the way back). |
| $43 | `return_to_saved_point`() | world | Go back to the room / spot saved by save_return_point. |
| $44 | `back_from_return`() | text | After the return: face as saved, turn the saved actor to the player and say the saved text + 9. |
| $45 | `restore_party_snapshot`() | party | Restore the party list from the $CAB9 snapshot. |
| $46 | `wait_dungeon_flags`() | wait | Wait until $DDB4/$DDCE/$DDE8/$DE02 are all $FF. |
| $47 | `face_up`(actor) | actor | Actor faces up (0 = the player). |
| $48 | `face_down`(actor) | actor | Actor faces down. |
| $49 | `face_left`(actor) | actor | Actor faces left. |
| $4A | `face_right`(actor) | actor | Actor faces right. |
| $4B | `restore_bgm`() | sound | Play the song set_bgm replaced. |
| $4C | `wait_dpad`() | wait | Wait until the player presses a direction on the D-pad. |
| $4D | `long_delay`(frames) | wait | Wait, counting every script tick ($D8D8 bit 2). |
| $4E | `save_position`() | world | Remember this room and the player's spot / facing. |
| $4F | `return_to_saved_position`() | world | Go back to the room / spot saved by save_position. |
| $50 | `face_saved`() | actor | The player faces as saved; NPC 2 faces the player. |
| $51 | `library_tier`() | state | Count the library entries -> tier 0-11 in $D8E1 (number to $C180). |
| $52 | `random_battle`() | battle | Fight 3 random monsters scaled to the party's levels. |
| $53 | `npc1_face_player`() | actor | NPC 1 turns toward the player. |
| $54 | `give_random_item`() | item | Give a random item 1-37. |
| $55 | `take_random_item`() | item | Take a random item from the bag (count to $D8E1). |
| $56 | `gold_value`() | state | Gold / 10 to $D8E1 (and the number to $C180); adds it back. |
| $57 | `give_random_item2`() | item | Give a random item $13-$17. |
| $58 | `floor_skip`() | world | Gate floors: jump about 20 floors deeper. |
| $59 | `train_slot`(slot) | party | Raise party slot's weakest stat by 20. |
| $5A | `trigger_battle3`(enemy) | battle | Boss fight with one enemy ($DA09 = 3). A win resumes the script. |
| $5B | `boss_battle`() | battle | Boss fight with the preset enemies ($DA02-$DA08). |
| $5C | `coliseum_init`() | battle | Roll the three Coliseum teams and the prize. |
| $5D | `give_coliseum_prize`() | item | Give the Coliseum prize item. |
| $5E | `reset_ceremony`() | state | $D951 := 7 and clear $C0D8 x 40. |
| $5F | `if_slot_level_below`(slot, target) | flow | Go to target when party slot's level is below its maximum. |
| $60 | `if_gold_short`(target) | flow | Go to target when gold < (lead monster level + 1) x 10; else pay it. |
| $61 | `draw_attrs`(data) | screen | Draw a background patch's colours (VRAM bank 1) from data in this script bank. |
| $62 | `blank_screen`() | screen | Fill tile $DA with $FF and the whole background map with it. |
| $63 | `draw_buffer`() | screen | Copy the 20x16 $C300 buffer onto the visible background. |
| $64 | `if_party_healthy`(target) | flow | Go to target when every party monster is at full HP and MP. |
| $65 | `wait_dd80`() | wait | Wait until [$DD80] & [$DD9A] == $FF. |

## Script opcodes as measured (S118) — movement, timing, text boxes, tile patches

Decoded for the editor's Cutscenes tab (ROADMAP P3.8 part A): every handler read,
labelled (`ScriptCmdNN_*`, `MoveProgNN_*`, `PlayerProgNN_*` in bank_004.asm, both
trees) and the visible effects MEASURED in PyBoy (GreatTree screen 0, an NPC and the
player; `tools/census_cutscenes.py --programs` re-measures).

**Actors.** Every movement op takes an actor n: **0 = the player** (HRAM `$92/$93` X,
`$95/$96` Y, `$8E` facing, `$90` flags — `$0D 0,$FF90,$40` hides him), **n ≥ 1 = NPC slot
n-1** (`$D7D2 + 32·(n-1)`: +0 type byte (bit 6 hidden), +6 facing, +$18 X, +$1A Y). NPC n
= the n-th NPC entry of the screen's step list (spots not counted). Facing 0 down,
1 left, 2 up, 3 right (`$0C`, `$47-$4A`, `$8E`).

**Two kinds of walk.** `$0A/$0B` (by pixels) and `$10/$11` (to an absolute pixel) move
ONE actor and the script WAITS (D8D7 bit 3). `$1A/$1B` QUEUE a walk in the actor's
movement buffer and go on at once — several actors walk together; `$19 wait_movement`
waits for all of them. Both move 1 px on 3 frames of every 4 (32 px = 44 frames);
`$22 walk_fast` doubles the next batch (the old name "begin_walk" and the claim that it
is REQUIRED were wrong — it only sets bit 6). A queued walk keeps running while the
script does other things (texts, delays, a waited walk of another actor).

**Movement buffers** `$D8E9 + 8·n` (n = actor; 8 buffers): `[active, step, program,
actor, dx lo, dx hi, dy lo, dy hi]`. `$1A` writes `[1, -, 0, n, dx]`, `$1B` the dy half
(X runs first, then Y), `$1C $PPNN` writes `[1, 0, PP, NN]` — program PP on actor NN.
`MoveProgramsAll` (`$43EC`) runs `PlayerMoveProgram` for buffer 0 and `NpcMoveProgram`
for buffers 1-7 every Entry-4 call. Most programs replay a table of per-frame Y steps
(`MoveProgCurveStep`, `$80` ends); $15-$18 read `$D8E3` (length / curve set) and
`$D8E4` (curve) — set them with `write_ram2 $D8E3` first. Programs, measured
(dx, dy = the actor's position change when the program ends; f = frames):

| Program | NPC (actors 1-8) | Player (actor 0) |
|---|---|---|
| $00 | walk (the queued dx / dy) — (+0, +0) px, 0 f | walk (the queued dx / dy) — (+0, +0) px, 0 f |
| $01 | hop — (+0, +0) px, 13 f | hop — (+0, +0) px, 13 f |
| $02 | jump up 2 tiles — (+0, -32) px, 23 f | — |
| $03 | — | spin and float up 3 tiles — (+0, -48) px, 63 f |
| $04 | jump — (+0, +0) px, 17 f | jump — (+0, +0) px, 17 f |
| $05 | leap 5 tiles right — (+80, -8) px, 40 f (X low byte only) | — |
| $06 | — | pause 64 frames (followers catch up) — (+0, +0) px, 64 f |
| $07 | — | leap 4 tiles left — (-64, +0) px, 32 f |
| $08 | appear (flicker in) — (+0, +0) px, 255 f | — |
| $09 | spin jump — (+0, +0) px, 17 f | — |
| $0A | jump up and stay (38 px) — (+0, -38) px, 16 f | — |
| $0B | double jump up (58 px) — (+0, -58) px, 37 f | — |
| $0C | run off left, sinking — (-114, +46) px, 57 f (X low byte only) | — |
| $0D | vanish (flicker out) — (+0, +0) px, 255 f | — |
| $0E | float up 1 tile — (+0, -16) px, 66 f | — |
| $0F | leap up 4 tiles — (+0, -64) px, 35 f | — |
| $10 | hop, then drop 4 tiles — (+0, +64) px, 35 f | — |
| $11 | drop 4 tiles — (+0, +64) px, 22 f | — |
| $12 | hop, then drop 2 tiles — (+0, +32) px, 27 f | — |
| $13 | rise high, hang, settle 40 px up — (+0, -40) px, 66 f | — |
| $14 | appear spinning (slow flicker) — (+0, +0) px, 0 f | — |
| $15 | fly in down-left ($D8E3/$D8E4) — (-48, +43) px, 24 f | — |
| $16 | fly in down-right ($D8E3/$D8E4) — (+48, +43) px, 24 f | — |
| $17 | fly off up-left ($D8E3 curve) — (-48, -44) px, 26 f | — |
| $18 | fly off up-right ($D8E3 curve) — (+48, -44) px, 26 f | — |
| $19 | leap 5 tiles left — (-80, +8) px, 41 f (X low byte only) | — |
| $1A | — | spin jump — (+0, +0) px, 17 f |

(A program number not listed does nothing for that kind of actor — e.g. $03 for an NPC.)
$08 / $14 set the type byte to $00 (shown, facing down, standing — the entry's own
facing / behaviour bits are lost); $0D ends hidden ($40). $05 / $0C / $19 step only the
LOW byte of X (`inc/dec [hl]` without carry) — X wraps inside its 256-px page.

**Timing.** Entry 4 runs once per frame in the field; `$09 delay n` counts once every 8
frames (`$C8A4 & 7 == 0`), `$4D long_delay n` once per Entry-4 call. A step that does not
yield (flags, faces, `npc_write`, queuing) runs in the same tick as the next one — the
live counter only ever rests on the yielding steps (texts, waits, delays, waited walks).

**Waits for input.** `$4C wait_dpad` re-runs itself until a D-pad direction is pressed
(the bedroom wake-up; was catalogued "RestoreBGM" — that is `$4B`). `$65` waits for
`$DD80 & $DD9A == $FF`, `$46` for `$DDB4/$DDCE/$DDE8/$DE02`.

**Text boxes.** `$07 init_dialog` opens dialog mode for scripts that did not start from
a talk; a text word queues the text (`$D8D9`); while it prints, the text pointer
`$C82D/$C82E` advances; when it stops the box waits for A (PyBoy S118 — the Playback
window's "auto text" presses A then). `$3C` / `$3D` put the NEXT box at the bottom /
top. `$06 close_text` closes the box.

**Tile patches ($24 / $61).** `$24 draw_tiles` and `$61 draw_attrs` far-call entry 1 / 2
of the map's SCRIPT bank (`ScriptBank0CDrawTiles` / `…DrawAttrs` and the $0D/$0E/$0F
twins), which read ONE MORE script word themselves: the address (in that bank) of a
patch `[dest offset, tiles…, $D8 next row, $D9 end]` drawn onto the visible BG
(Castle / Bazaar doors, treasure chests). The S96 tracer stopped at the rst $10 and
counted 0 params; `tools/script_param_counts.py` now follows the read (`cross_bank`).
Every decode was already consistent (the word decoded as a "text"), so no project or
ROM byte changes. In a CLONED room (bank $60) the far call still went to bank $0F's
entry, which reads bank $0F's tables — not the clone's: **MEASURED S119** (PyBoy, a copy
of the Castle: its chest patch is not drawn). **Fixed S119 (patched builds):** bank $04
calls bank $60 entries 9 / 10 (`CustomDrawTiles` / `CustomDrawAttrs`) instead, which draw
a bank $60 script's patch from bank $60 (`patch_data`, PROJECT_COMPILER §2.33) and far-call
bank $0F for every other script; the copy now draws the chest at the same BG cells as the
original. The patch offset = 8-px row · 32 + column from the visible top-left
(`$FFB7`/`$FFBB` & $F8); the tiles are also staged at `$C300 + offset` (rows of 32) and
the colours as nibbles at `$C200 + offset / 2` — so a text box closing over the patch
restores it (PyBoy S119). A patch lasts until the room is loaded again.

**Other names settled.** `$21` = play sound effect (was "TriggerBattle2" / "SkipScriptData2"),
`$13` = 16-bit RAM write, `$14` = goto, `$16` = redraw sprites (one tick), `$17` = the
intro bedroom's tile swap, `$18` = a monster JOINS (party if < 3, S56), `$20` = start the
preset battle, `$26` = reload the room, `$2F` = increment a RAM byte, `$3A` = go to the
breeding ceremony (map $08), `$3E` = switch game mode (`$C88B` → `$C88E`, e.g. the
ending), `$04 15` = the naming screen, `$42/$43/$44` and `$4E/$4F/$50` = save / return to
a room position, `$53` = NPC 1 faces the player, `$5E` = `$D951 := 7` (the breeding
ceremony state). Every row is in the table above.

**Playing a scene (the editor's Playback, `editor2/core/playback.py`).** From a cached
new-game state: stop any script (`$D8D7 = $D8D8 = 0`, buffers cleared), set the path's
flags / RAM (a test of the player's position `$FF92/$FF95/$FF97/$FF98` is NEVER poked —
the player is placed there instead: a stray HRAM write wedged the game, KEY_LESSONS
S118), warp with the exit mailbox, wait for the room (`$C96C` clear AND `$C850` clear),
then: a room-entry scene starts by itself; a talk / examine / step-on scene is started
the player's way (face the NPC / spot and press A, or walk on) after the room's entry
script has been kept quiet (its conditions chosen to end without showing anything);
otherwise the script is armed (`$D8D3/$D8D4`, counter `$FFFF`, `$D8D7 = 1`). A scene
whose conditions cannot be set (party / bag checks) is started at its first step, and so
is a scene every path to which passes a battle op (it plays after a WIN — the set-up does
not fight; 32 vanilla scenes: the boss rooms' exits, after Durran's fights in map $45). A name slot the
script's texts insert (`$F9 nn` → `$C180 + nn`, TEXT_SYSTEM) that holds no `$F0` gets a
placeholder name — only those slots (filling all four crashed the Castle).
**Room state (S118b, user report: "the wrong NPC jumps down").** NPC n = slot n-1 =
the n-th NPC of the screen's CURRENT step list, so the same script moves a different
person in another state (GreatTree screen 0: state 0 = the old man (sprite 8) then the
man by the cliff; state 2 = only the man by the cliff — "Oh boy! This looks dangerous!"
moves NPC 1 = the cliff man in the game). The scene's own conditions rarely test the
counter, so the set-up chooses: (1) the counter value the path tests (if the state lacks
the NPCs the scene acts on, a sibling test of the same counter that branches to the same
place — Castle screen 1 `$D92B` = 0 or 4); (2) else the value the game's own scripts
WRITE in the same straight run where they set the flags the scene needs (`$00` script 0
sets flag `$0009` and `$D92D := 2`; a run that sets a flag the scene needs CLEAR counts
against); (3) else the trigger's state; and always a state holding the highest NPC the
scene acts on before it changes the state itself. Checked by the census: every step that
acts on NPC n finds slot n-1 occupied (`missing_npcs`; slot empty = type byte `$FF` — a
big sprite's extra parts keep sprite byte `$FF` in an OCCUPIED slot). A cloned room keeps
its own counters (`wCustomStep_*`, PROJECT_COMPILER §2.6), so the vanilla scripts' writes
(`$D92D := …`) never reach it: a clone plays its first state unless its rules say
otherwise — the user's GreatTree clone moves the old man there, in the game too.
**Where the player starts (S118e, user: "Game intro where milayou and terry run around …
is completely wrong - both are in wrong positions").** The bedtime scene (`$2F` script 0
@7) is the one scene a NEW GAME plays: it is played from a cached state of a new game at
the moment the bedroom loads (`Engine.newgame_state`, made from power-on; recipe action
`newgame`) — PyBoy: Terry / Milayou / the script counter identical to an uninterrupted new
game at every sampled frame (before: Terry warped to the room's arrival (56, 200) instead
of the new game's spot, every relative walk off). 36 room-entry scenes had NO arrival (no
door, warp or gate leads there) and started the player at the SCREEN CENTRE: the boss
rooms now use the gate's arrival tile (`GateFloorDataTable` $16:$70A6 bytes 4-6,
`Catalogue.gate_arrivals`), and a screen reached only by walking across from the next
screen of the same room (the bedroom's east room — Warubou's scene; Farm screen 1 @17;
`$4E`) is entered by WALKING IN from that screen's edge (action `walkin`: arrive on the
neighbour, stop its own entry scene, hold the direction until the screen changes —
PyBoy: Terry comes in through the east room's west doorway). Still synthetic: `$45`
(Durran, one screen, no arrival data) and the talk / examine / step-on scenes' standing
cell (the game lets the player stand on any side).
**Entry scenes reached by another script's room change (S118d, user: the "Arena Rooms"
scene "moves a random NPC down, then the game resets and plays the logo").** Room `$07`
script 0 @12 needs `$D9E5 = 1`, which only the Farm's hole scripts (`$04` scripts 41 / 42)
write — together with `$C8ED := 15` — right before `$0F` to `$07` at (408, 216), screen 6,
whose state holds NPCs 4-7 (the falling party). Set up on screen 0 (4 NPCs) the scene
showed and walked empty slots and the game crash-reset (wGameMode 0, measured PyBoy).
`Catalogue.entry_caller`: the block (any room's script) that ends in a room change into the
scene's map and whose RAM writes give the values the scene tests (+1 each, −1 for a
different value) supplies the arrival (screen + pixel), its other RAM writes (not the
game-mode block `$C88A-$C88E` or the fade registers `$C89B-$C89D`) and its flags — 45 of
519 scenes. The census now flags a RESET (wGameMode 0 during the scene; it had counted the
crash as "ended") and the Playback log shows it in the window.
**Fly programs ($15-$18) measured per `$D8E3` / `$D8E4`** (`script_ops.FLY`, 216 rows,
`census_cutscenes.py --fly`): `$D8E3` = length (8 frames and 16 px across per unit),
`$D8E4` = the curve (dy e.g. `$D8E3` 3: curve 0 +53, 1 +16, 2 +30, 3 +43, 4-5 +53).
The model also follows plain RAM writes into the NPC slot table (`$12`/`$13` to `$D7D2 +
32·k + 0 / $18-$1B` — the Starry Shrine and the arena place their cast that way).
`tools/census_cutscenes.py` plays every vanilla scene this way and checks the editor's
position model at every wait (`extracted/cutscene_census.json`). **Census S118d** (the
original ROM, each map in a worker process): 519 scenes, 516 reached (442 by the game's
own trigger, 74 started at their first step), 419 ended, 86 handed over to a battle, 0
hung, 0 resets, 0 steps on an empty NPC slot; the position model 3,994 of 3,998 checks
exact (S118e, the new-game / gate-arrival / walk-in starts: 3,992 of 3,998 — `$04` @17's
walk-in, 2 checks) (S118b: 3,989 / 3,998 with `$07` @12 set up on the wrong screen — it reset the
game; the census did not see resets then); off, not yet explained: `$01` script 16 @142
(the player, 16 px in Y, 3 checks), `$04` script 19 @12 (1). Not reached (3): `$07`
script 5 @-125 (a branch target before the script start), `$09` @81, `$5D` @1064 (behind
the final battle). (S118: 514 reached, 22 off — the Castle King's prize scenes now play
in Castle state 4, the fly programs follow `$D8E3`/`$D8E4`.)

## Writing scenes (S119) — rules the cutscene editor's compiler follows (PyBoy-measured)

ROADMAP P3.8 part B; the compiler: `editor2/core/cutscene_build.py` (PROJECT_COMPILER
§2.33). Every rule below was measured in PyBoy on custom rooms of the user's project
(scratch builds), not read from the code alone.

* **Text needs `init_dialog` after any yielding step — in a talk script too.** The
  dialog mode the A press opens holds only while the script's first words run without
  yielding: `face; npc_walk_x; wait_movement; text` and `delay 2; text` in an NPC's talk
  script both left the text queued (`$D8D7` = 3) forever; examine and step-on scripts
  behave the same. `init_dialog` when the box is already open is harmless (a guard of
  flag tests before it, then init_dialog + text, works). A text followed directly by the
  end after an `init_dialog` stalled once: the compiler always `close_text`s before any
  other step and before the end.
* **`$10` / `$11` walk the player too** (actor 0: the handler reads `$FF92` / `$FF95`),
  to an absolute pixel, script waits — exact wherever he stands (a talk can start from
  any side). Queued `$1A`/`$1B` of the player are exact only when his start is known.
* **The flicker-in program `$08`** toggles type bit 6 for ~255 frames and ends with type
  `$00`; the facing at slot `+$06` is kept (the NPC appears facing its own way).
  `npc_write n,0,t` shows / hides instantly with the entry's own facing / behaviour.
* **Shake:** `$C8B1` = frames of up-down, `$C8B2` = frames of left-right; ROM0
  `ScreenShakeTick` (was "CheckSoundQueueState") counts them down and offsets rSCY / rSCX
  by -4..+3 px each frame; the script goes on while it shakes.
* **Shades `$C89B` (BG) / `$C89C` / `$C89D` (OBJ)**: normal `$D2 / $D2 / $E2`; the vanilla
  fade to black writes `$E7/$E7/$F7`, `$FB`×3, `$FF`×3 with `delay 2` between (Castle
  script 0 @1372); `$00` = every pixel takes its palette's colour 0 — white in the game's
  rooms, the palette's own first colour in a free-colour custom room (a "flash" there is
  not white).
* **A battle inside a scene keeps the NPC slots** (positions, shown / hidden) as the scene
  left them (the cast member shown before the fight is still shown after a won battle).
* **The room-entry script runs at the FIRST arrival** (door, warp mailbox) — the S11/S53
  "not dependably at initial entry" is history (the `$01:$4C3E` site was reverted in
  S70v3; DOC_AUDIT S119).
* **A room load resets** what scenes did to NPC slots (a cast member is hidden again at
  its own cell) and to the BG (tile patches): the demo's fourth entry.
* `give_item` ($2A) is silent — the game's own scripts test `$2C` (bag full) first and
  say "[HERO] got …" themselves; the editor's Give step does the same.


## Script variables — what `$xxxx := v` means (S118f)

User (S118f): "Some of these steps are uninterpretable … I want everything interpretable".
The storyboard words every RAM write / test (`editor2/core/ram_names.py`): ROOM STATES
(`$D92A-$D99A`, named from the room table: "Room state of Castle screen 1 → state 6"),
NPC slot fields, the player's HRAM position, and the curated variables below (read from
the code S118f, cited; "script" = inferred from the script word streams only).

| Addr | Words | Meaning / values |
|---|---|---|
| `$C83C` | the YES/NO answer | 0 YES, 1 NO |
| `$C842` / `$C846` | buttons held / pressed this frame | scripts clear them so the player stops walking |
| `$C88A` / `$C88B` / `$C88E` | game mode / next mode / mode-change request | ARCHITECTURE "Top-level game mode" |
| `$C89B-$C89D` | BG / OBJ palettes (flashes, fades) | 0 = all white, $FF = all black |
| `$C8B1` / `$C8B2` | screen shake up-down / left-right | frames (BATTLE_SKILL_SYSTEM) |
| `$C8EC` | all field sprites hidden | code: non-zero → player, followers (bank_001:3786), NPCs (bank_006:2401), gate object (bank_001:5394) not drawn; room transitions set 1 (bank_006:5970), the engine clears it only when `$D92B` ∉ 1-5 (bank_006:5996) — early-story scripts unhide with 0 |
| `$C8ED` | hidden sprites | code (bank_001:3775-3876): bit 0 Terry, bits 1-3 followers 1-3; reset to 0 every frame without a script except the boss-win `$0E`. 15 = everyone, 14 = the monsters only |
| `$C8F2` (word) | the name the naming screen edits | code (bank_009:5701): `$CA42` = the HERO's name — text code `$F6` [HERO] prints those 8 bytes (bank $56, the handler before `jr_056_478a`); a new game holds the placeholder `$D3-$D6` (prints "TERRY0000" — the 4 tiles + `$00` × 4) until the Castle intro's naming screen (map `$00` script 0 pos 107-113: `$12` `$C8F4`=0, `$13` `$C8F2`=`$CA42`, `$04 15`), which offers those tiles and, accepted, stores them + `$F0` × 4 (S120b, PyBoy; the project's builds draw them "MILLY", TEXT_SYSTEM). (An S118f helper reading said "the new monster" — wrong, corrected the same round.) |
| `$C8F4` | the naming screen's default name | 0 = none |
| `$CAB4` | arena classes won | 1-8 after G…S (bank_009:4634-4709) |
| `$D8E1` | the last check's result | written by the party / bag / library checks |
| `$D8E3` (word) | the next fly-in / fly-off path | low = length, high = curve (`script_ops.FLY`) |
| `$D951` | breeding-shrine stage / return code | code: map `$08`'s step counter (bank_00b:4334): 2 naming the newborn (bank_004:4884), 6 from the intro bedroom, 7 the ceremony (bank_001:6859 → 8, bank_002:6045); ≥ `$F0` return codes: `$F0`/`$F1` → the Starry Shrine, `$F2` → Arena Lobby / Restaurant / Queen, `$FF` → the intro journey. Per-variant meanings from the writers, not watched |
| `$D952-$D954`, `$D974`/`$D975` | room states (Starry Shrine screens 1/4/5; intro bedroom 4/5) | `$D974` = 6 → intro finished (bank_015:639) |
| `$D9CB` | the room effect phase | code: cleared at field init (bank_001:1947); map `$08` palette pulse 0/1/2 (bank_001:5945); Arena Rooms: 1 = the entry sequence shown this visit |
| `$D9CF-$D9D6` | treasure chests 1-8 | code (bank_016:4920): `$FF` empty, 0 opened, else an item; `$37` gives chest n; the Coliseum reuses the bytes (bank_004:6171-6254) |
| `$D9DF` / `$D9E0` | the Goopy game round / pick | SIDEQUEST_MAP |
| `$D9E2` | arriving at the Farm by the Shrine warp | script only (Shrine s11 → 1, Farm s0 plays the warp-in, → 0) |
| `$D9E3` | the King's speech for the next Castle arrival | GATE_GENERATION §7.7 |
| `$D9E4` | the Well boss's tile event seen | script only (map `$38` s16) |
| `$D9E5` | the party is falling through a hole | script only (the hole scripts → 1, the next room's entry scene → 0) |
| `$D9E8` | player input locked (scripted scroll) | code: non-zero skips free walking (bank_006:3697), cleared by the scroll handler (bank_006:4367) |
| `$DA02-$DA07` | the battle set-up | count − 1, enemy rows (the storyboard names the monsters) |

**NPC slot `+$10` / `+$14`** (code, the animation player bank_002 `SeqStepper` on the
6-byte record at slot `+$10`): `+$10` = sequence running (writing 0 restarts the NPC's
animation at its first frame), `+$14` = the shown frame (0/1 down, 2/3 side, 4/5 up;
`$FF` draws nothing, bank_006:2466-2510); `+$11` row, `+$12` animation id, `+$13` step,
`+$15` frames left (ROOM_DATA_FORMAT "NPC RAM slot"). **`$04` screen types** (bank $09
`ScreenEffectTable09`): 2 the Vault, 3 Pulio's farm menu, 8 the Library, 9 the Monster
Namer, 10 MedalMan's exchange, 13 the list of Travelers' Gates (+ 0/12 shop, 4 arena
class menu, 5/6/7/11 bank $0A, 15 naming). **Flags** are worded by `Catalogue.flag_desc`:
known names, else "set in <room>: «the scene's first words»"; `$0007` = a monster taken
from the farm (Pulio, `$12:$4EBC`) into an empty party; `$0050-$0057` medal eggs.

### S101 corrections — the vanilla boss exit, traced (PyBoy + handler bytes; comments in bank_004.asm, both trees)
| Cmd | Params | Measured meaning (the names in the tables here are older guesses) |
|-----|--------|-----|
| $06 | 0 | close the text box (the vanilla boss script closes before the helper arrives) |
| $0D | 3 | `npc,0,0` REVEALS a hidden NPC (clears type bit 6) — "WriteNPCByte" writes the NPC buffer; the reveal is its use in boss rooms |
| $0E | 2 | `branch_screen k,@target`: branch when `wScreenIndex` == k (compiler name) |
| $1C | 1 | NPC ANIMATION `$SSNN` (script SS, NPC index NN = 1 + NPC-entry slot, spots not counted): $16 = FLY IN (S101 r2 correction: NOT a target tile — from the NPC's current pixel position, `$D8E3`·8 frames, +2 px right per frame, down along the curve `$D8E4` picks; `$0303` = +48/+43 px) — earlier text: fly to the SCREEN-LOCAL tile in `$D8E3`/`$D8E4` (write `(y<<8)\|x` with `write_ram2`), $04 = hop; wait with $19. Not "CompareRAM" |
| $19 | 0 | wait until the NPC movement ends |
| $3B | 3 | `warp_fade map, px, py` — the wavy fade + warp (vanilla boss win tail: `$0000,$00E8,$0058` = Castle screen 1 tile (4,5)); `$0F` is the plain warp |
| $47/$48/$49/$4A | 1 | face UP / DOWN / LEFT / RIGHT for NPC n (n = 0 is the player) — the helper's spin is `$4D 4` + these four. Were catalogued as npc_buffer_write / npc_hide / npc_show |
| $4D | 1 | long delay |
| $58 | 0 | `FloorSkip` (ScriptCmd58_FloorSkip) — used only by gate-world script 4 ($0F:$6ED0) |
| $5A / $5B | 1 / 0 | boss battle: $5A = one EID (DA09 = 3); $5B = the preset (`DA02` = count − 1, EIDs at `DA03/05/07`). The WIN resumes the script; a LOSS never returns |

The compiler's names (`editor2/core/scriptgen.py` OPS): `close_text`, `npc_write`, `branch_screen`,
`trigger_anim`, `wait_movement`, `warp_fade`, `face_up/down/left/right`, `long_delay`,
`trigger_battle3`, `boss_battle` (PROJECT_COMPILER §2.18).

## Key RAM Variables

| Address | Size | Name | Description |
|---------|------|------|-------------|
| $D7D2+ | 32×N | NPCBuffer | NPC RAM buffer, 32 bytes per NPC |
| $D8D3 | 1 | MapTypeCopy | Copy of current map type (selects script bank) |
| $D8D5-D8D6 | 2 | ScriptCounter | 16-bit position within script data |
| $D8D7 | 1 | ScriptState | 7-bit state flags (see table above) |
| $D8D8 | 1 | SecondaryState | Secondary state flags (bit 2 = secondary delay) |
| $D8D9-D8DA | 2 | QueuedTextID | 16-bit text ID queued for display |
| $D8DB | 1 | DelayCounter | Frame delay counter (decremented by entry 4) |
| $D8DC | 1 | NPCNumber | NPC number for pending interaction (1-based) |
| $D8DD-D8DE | 2 | NPCMoveX | X movement delta (signed 16-bit) |
| $D8DF-D8E0 | 2 | NPCMoveY | Y movement delta (signed 16-bit) |
| $D8E1 | 1 | ScriptTemp | EVALUATOR RESULT cell (S68): written by the 10-opcode evaluator family $23/$30/$32/$34/$38/$51/$55/$56/$59/$5F; read back by cond_branch $15. See "Evaluator opcodes" below |
| $D8E9+ | 8×8 | NPCMoveBuffers | 8 NPC movement tracking buffers |
| $C822-C823 | 2 | TextID | Active text ID (high/low) for ROM0 dispatch |
| $C8A4 | 1 | InteractType | Interaction type (AND 3: 1=talk, 2/3=walk-toward) |
| $C8EF | 1 | EffectType | Screen effect type |
| $C8F0-C8F1 | 2 | EffectParams | Screen effect parameters |
| $FFC7 | 1 | NPCInteractIndex | NPC interaction routing index |
| $FFD5-FFD6 | 2 | CachedNPCPtr | Cached pointer to current NPC buffer |

## NPC Buffer Layout ($D7D2)

Each NPC occupies 32 bytes. NPC index calculation at Jump_004_42cd:

```
HL = $D7D2 + (npc_number - 1) × 32
```

Known offsets within each 32-byte NPC buffer (the full S97 field map —
type byte, home tile, status bits, timer, phase, pixel position — lives in
ROOM_DATA_FORMAT "NPC RAM slot"; corrected S97, DOC_AUDIT S97):
| Offset | Description |
|--------|-------------|
| +$00 | Type byte: facing bits 4-5, hidden bit 6, behaviour bits 0-3 |
| +$05 | Status: bit 0 = walking (walk animation; was "interacting"), bit 5 = blocked by the player, bit 6 = talking (faces the player), bit 7 = hidden from the animation picker |
| +$06 | Facing direction (0 down, 1 left, 2 up, 3 right) |
| +$18-$19 | Pixel X (16-bit, tile·16+8) |
| +$1A-$1B | Pixel Y (16-bit) |

## Script Branch Mechanism

Jump_004_7212 (ScriptBranch) implements relative branching:

```
BC = target_position (from script data)
HL = reference_position (from some context)
offset = (BC - HL) / 2    (preserving sign via bit 7)
new_counter = counter + offset
→ jump to ScriptExecNext with new counter
```

This allows conditional and unconditional jumps within the script data.

## How Custom Scripts Work (Proven — Session 2)

Custom rooms (mapID ≥ $6B) use bank $60 for scripts, text, and room data:

1. **MapTypeDispatch → DispatchBank0F** (bank $04) hooked: the `≥ $40 → bank $0F` sub-path redirects to bank $60 **entry 6 (GateAwareDispatch)**, which routes by **`wMapID`**: `≥ $6B` → entry 4 (CustomScriptRead); `< $6B` → real bank $0F dispatch (gates/labyrinth). *(The original hook tested `wScriptMapType` and froze gate entry — fixed S20, see `GATE_FREEZE_FIX.md`.)*
2. **TextQueueCheck** (bank $04) patched: text IDs with high byte ≥ $0A intercepted before ROM0 cascade → routes to bank $60 entry 5 (CustomTextDisplay)
3. **Script data** in bank $60: same triple-index format as banks $0C-$0F
4. **Text data** in bank $60: two-level pointer table (required by SaveBankAndSwitch)
5. **NO ROM0 changes needed** — all routing via bank $04 patches

**Critical rules:**
- Script index 0 = room entry script (must be `dw $FFFF`). NPC scripts at index 1+.
- Text format: `$EA $9F $A3` prefix, `$EF $EE` for line breaks, `$F7 $F0` to end.
- YES/NO: text ends with `$E7 $F0`, script checks `$C83C` via opcode `$15`.
- Item give: opcode `$2A` (GiveItem) via jump table wrapper. Check full first with opcode `$2C`.
- **NEVER insert bytes in bank $04** — use same-size replacements or wrappers in padding.

See `patches/bank_004.asm` and `patches/bank_060.asm` for implementation.

## Battle opcodes and script resume (S68)

Opcode `$05` handler `$04:$57EB`: consumes the EID param → `$DA03/04`,
`$DA02=0`, `$DA09=1`, `set 6,[wGameState $C8EB]` (battle REQUEST latch),
resets `$C905` (the bank `$13` transition machine). The script VM's state
(`$D8D5/6` counter, `$D8D7` flags) survives the battle in WRAM; on a WIN,
`BattleExitHandler` (`$50:$640A`) restores field mode with `$C8EA.7` set,
which makes bank `$01` skip its script-state reset — **the script resumes
at the command after the battle opcode**. On a LOSS the engine warps to the
Castle and clears `$D8D7` (script killed). Full story-engine writeup:
SIDEQUEST_MAP "Story progression ENGINE + AUTHORING SPEC — DECODED S68".

## Evaluator opcodes (the $D8E1 family; S68 census of every writer)

All share the pattern: read game state → result to `$D8E1` (or act on a
slot param), for a following `cond_branch $15`. Slot-param opcodes bound
the slot against `$CA8D` (party count — also directly cond_branch'ed by
scripts: `[$CA8D]==1` = "only one monster in party" refusal gates).

| Op | Handler | Reads | Result |
|----|---------|-------|--------|
| $23 | $5E8F | per-monster field via slot → $CAEA-family | $D8E1 |
| $30 | $6253 | per-monster field via slot → $CB19-family | $D8E1 |
| $32 | $62DD | per-monster SPECIES via slot → $CACA-family | $D8E1 |
| $34 | $634F | species vs value list (Library tiers) | $D8E1 |
| $38 | $643F | per-monster field via slot → $CAEA-family | $D8E1 |
| $51 | $696C | count of SEEN library bits $CA94 (ids 0-$EF) → 12-tier compare table $04:$699D | $D8E1 |
| $55 | $6AFA | count of non-empty item slots $CA51 (×20) | $D8E1 |
| $56 | $6B3A | 24-bit gold $CA4B-4D ÷ 10 (magnitude test + digit display) | $D8E1 |
| $59 | $6BDF | party-list species via slot → $CB13-family | $D8E1 |
| $5F | $6F9B | per-monster field via slot → $CB0D-family | $D8E1 |

Position gates: scripts also cond_branch `hFF92` (player X low byte;
`$FF92/93` = X word, `$FF95/96` = Y word — e.g. Bazaar counter 215/216/217).

Opcode `$45` (`$04:$67B1`, S68): **restore party list from snapshot** —
copies the 7-byte block `$CAB9-$CABF` (count + 3 party ids + 3 follower
gfx) into `$CA8D-$CA93`, revalidates each id, re-canonicalizes (bank $01
entries 5/9/3). The snapshot WRITER is not yet traced (residual).

## Cross-References

- **EVENT_FLAGS.md** — Complete story flag mapping (11 major flags verified via SameBoy)
- **TEXT_ENCODING.md** — Text character encoding, DTE pairs, 2067 text IDs mapped
- **extracted/text_id_map.json** — Every text ID decoded to readable English
- **extracted/all_scripts.json** — All 209 NPC scripts with command sequences
- **extracted/event_flags.json** — Story timeline analysis

## Verified via SameBoy (completed)

All of the following have been traced and confirmed:
- `watch/w $D8D9` fires at `$04:$56F2` when text ID is queued
- Breakpoint `$04:$55EC` (ScriptInit) confirms $D8D4 = script_id at entry
- Breakpoint `$04:$5609` (ScriptExecNext) confirms BC dispatch logic
- `watch/w $D9A1/$D99E/$D99F/$D9B9` mapped all 11 major story flags
- DE register at $5609 confirmed per-NPC script data pointers

---

## Script Data Bank Annotations

All 4 script data banks ($0C/$0D/$0E/$0F) are now fully annotated with
`tools/gen_script_banks.py`. 530 NPC scripts with 1,626 labels:

- Pointer tables use label references (`Castle_ScriptPtrTable`, etc.)
- Script starts labeled (`Castle_Script09`, `BossBeginning_Script01`, etc.)
- Branch targets labeled (`Bank0C_ScriptAddr_5273`, etc.)
- Every `dw` word annotated: opcode names, text ID previews, RAM addresses
- Builds byte-identical (MD5 1ca6579359f21d8e27b446f865bf6b83)

See `DATA_STRUCTURES.md` for the full script data format reference.

---

*Discovered June 2026. Builds on TEXT_SYSTEM_ARCHITECTURE.md discoveries.*
*All annotations build byte-identical (MD5 1ca6579359f21d8e27b446f865bf6b83).*
