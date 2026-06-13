# Bank $04 — NPC Script Engine Architecture

## Overview

Bank $04 is the heart of DWM1's NPC interaction system. It contains a **complete scripting virtual machine** with 100 opcodes that drives all NPC dialogue, cutscenes, story events, and in-game scripted sequences.

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

| Bit | Meaning | Set by | Cleared by |
|-----|---------|--------|------------|
| 0 | Script is active | ScriptExecNext ($5613) | Script end ($FFFF) |
| 1 | Text ID queued | TextIDQueue ($56EC) | TextQueueCheck ($5700) |
| 2 | Delay active | Cmd $09 SetDelay | Entry 4 countdown |
| 3 | NPC walk-toward | Cmd $0A/$0B movement | Entry 4 walk complete |
| 4 | NPC position update (A) | NPC movement cmds | Call_004_43ec |
| 5 | Movement lock | Cmd $1D LockMovement | Cmd $1E UnlockMovement |
| 6 | NPC position update (B) | NPC movement cmds | Call_004_43ec |

## Script Data Banks

`Call_004_71ef` (ScriptDataRead) dispatches to script data banks based on $D8D3 (map type copy):

| $D8D3 Range | Bank | Rooms Covered |
|-------------|------|---------------|
| < $06 | $0C | Castle ($00), GreatTree ($01), Bazaar ($02), GateHub ($03), Farm ($04), Stable ($05) |
| $06–$1F | $0D | Arena ($06/$07), special rooms ($08-$1F) |
| $20–$3F | $0E | Gate entrance rooms ($23-$2E), boss rooms ($30-$3F) |
| ≥ $40 | $0F | Labyrinth ($42), arena battles, post-game content |

Each bank's entry 0 uses the script counter ($D8D5/$D8D6) to look up the next command in its internal script data tables.

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

## Script Command Reference (100 opcodes, $00–$63)

### Flow Control
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $00 | $5711 | ConditionalBranchNZ | Read condition; if false (Z), read target and branch |
| $01 | $5740 | ConditionalBranchZ | Read condition; if true (Z), read target and branch |
| $08 | $5842 | NOP | No operation |
| $1D | $5D4B | LockMovement | Set $D8D7 bit 5 (suppress NPC facing updates) |
| $1E | $5D53 | UnlockMovement | Clear $D8D7 bit 5 (restore NPC facing) |

### RAM Operations
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $02 | $576F | ClearEventFlag | Clear bit in $D99B+ bitfield via Call_000_26a6 |
| $03 | $5788 | SetEventFlag | Set bit in $D99B+ bitfield via Call_000_26a0 |
| $0D | $5968 | WriteNPCByte | Write value to NPC buffer byte or RAM address |
| $1B | $5CCF | MultiRAMWrite | Write multiple values to RAM |
| $1C | $5D1A | CompareRAM | Compare RAM value, set condition flags |

### NPC Control
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $0A | $5860 | SetNPCMoveX | Set NPC number + X movement delta, trigger walk |
| $0B | $5898 | SetNPCMoveY | Set NPC number + Y movement delta, trigger walk |
| $0C | $58D0 | SetNPCFacing | Set NPC facing (0=down, 1=up, 2=right, 3=left) |
| $10 | $5A6F | NPCAnimStart | Begin NPC animation sequence |
| $11 | $5AC5 | NPCAnimSetup | Configure NPC animation parameters |
| $18 | $5C14 | NPCVisibility | Show/hide NPC |

### Timer/Delay
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $09 | $5843 | SetDelay | Set frame delay counter in $D8DB |
| $4D | $68BA | SetLongDelay | Extended delay variant |

### Screen Effects
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $04 | $57A1 | GameActionDispatch | **Bank $09 dispatch via $C8EF. 0=shop, others=gate events. NOT give-item.** |
| $19 | $5C6D | FadeEffect | Screen fade in/out |
| $0F | $5A02 | **MapTransitionFull** | **Write gate_id→$C96D, flag→$C96E, spawn XY→$C96F-$C972, set wIsPlayerChangingMaps=1. Format: $FF0F gate:flag spawnX spawnY (3 params). This is the real teleport opcode.** |

### Battle
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $05 | $57EB | TriggerBattle | Set enemy EID in $DA03, set wGameState bit 6 |
| $17 | $5BDB | SetupBossBattle | Configure boss battle parameters |
| $21 | $5E6D | TriggerBattle2 | Battle trigger variant |
| $38 | $643F | BattleSetup | Complex battle configuration |
| $54 | $6ACE | BattleConfig | Additional battle configuration |

### Sound/Music
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $15 | $5B8F | **CheckAndBranch** | **Compare [addr] to value, branch if match. Used for YES/NO ($C83C).** |
| $23 | $5E8F | PlaySE2 | Sound effect variant |
| $41 | $669D | SetBGM | Save current BGM, play new BGM |
| $4C | $68A1 | RestoreBGM | Restore BGM from $C8B6 |

### Monster/Inventory
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $28 | $5F67 | CheckStorageFull | Branch if all 20 monster slots occupied |
| $29 | $5F9A | AddMonster | Add monster to storage by enemy stats ID |
| $2A | $5FDB | **GiveItem** | **Scan first empty slot, write item. Needs wrapper (uses `ret` not `jp ScriptExecContinue`). Patched via jump table redirect.** |
| $2B | $6002 | CheckMonsterLevel | Check monster level thresholds |
| $2C | $6064 | **CheckInvFull** | **Branch if inventory full. 1 param = branch target. Verified working.** |

### Map/Room Transitions
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $0E | $59D2 | **BranchByScreen** | **Branch if wScreenIndex ($C925) == param. NOT a map transition (that is $0F). Format: $FF0E screen_id branch_target (2 params).** |
| $42 | $66BD | SetReturnMap | Store current map for return, set dest |
| $43 | $6723 | ExecuteReturn | Copy stored return map to transition vars |
| $4E | $68D7 | MapTransition3 | Map transition variant |

### Game State
| Cmd | Address | Name | Description |
|-----|---------|------|-------------|
| $06 | $5819 | IncrementCounter | Inc $C915 if wGameState bit 0 set |
| $07 | $5824 | InitDialogMode | Set wGameState bit 0, init counters |
| $13 | $5B49 | SetGameFlags | Configure game state flags |
| $14 | $5B79 | ClearGameFlags | Clear game state flags |
| $1F | $5D5B | EventTrigger | Complex event dispatch |
| $2D | $6093 | EventDispatch | Large event handler |

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
| $D8E1 | 1 | ScriptTemp | Temporary storage used by multiple commands |
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

Known offsets within each 32-byte NPC buffer:
| Offset | Description |
|--------|-------------|
| +$00 | Type/flags from ROM NPC data |
| +$05 | Status flags (bit 0 = interacting, bit 6 = cleared on interact) |
| +$06 | Facing direction (0-3) |
| +$18-$19 | Movement counter (16-bit, read at +$12 from status byte) |
| +$1A-$1B | Y movement counter (read at +$14 from status byte) |

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

1. **MapTypeDispatch** (bank $04) patched: `cp CUSTOM_ROOM_START` before existing cascade → routes to bank $60 entry 4 (CustomScriptRead)
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
