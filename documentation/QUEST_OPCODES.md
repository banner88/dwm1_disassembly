# Quest-Driving Opcodes: $1F, $2C, $2D — Bank $04 Handler Analysis

## Summary

These three opcodes were initially labeled vaguely. Handler code analysis reveals their actual functions:

| Opcode | Old Name | **Actual Function** | Params | Script Uses |
|--------|----------|---------------------|--------|-------------|
| $1F | LargeEventHandler | **ArenaBattleSetup** | 0 | 0 (engine-only) |
| $2C | EventDispatch | **CheckInvFull** | 1 (branch addr) | 45 |
| $2D | CheckStep | **MonsterSlotDialogue** | 1 (slot index) | 3 |

**Decompiler names need updating:** `event_dispatch` → `check_inv_full`, `check_step` → `monster_slot_dialogue`, `large_event_handler` → `arena_battle_setup`.

---

## $1F — ArenaBattleSetup (Handler: $04:$5D5B)

### What it does
Calculates the 3-monster enemy team for arena battles based on current arena state:
- `enemy_base = wArenaGroup * 3 + wColiseumBattle`
- Each of the 3 enemy IDs = `$00E0 + enemy_base * 3 + offset`
- Writes enemy IDs to $DA03-$DA08 (3 pairs)
- Special case: `wArenaGroup == 9` → hardcoded boss team ($01E1, $01E2, $01E3)
- Loads NPC sprite data to $D7CA-$D7D1 from table at $5E22

### Usage
**Zero script uses.** This opcode is called exclusively by game engine code during arena battle initialization, never from NPC scripts. Its 0-param count confirms it reads all state from WRAM variables.

### Key RAM
| Address | Name | Purpose |
|---------|------|---------|
| wArenaGroup | Arena rank group (0-9, where 9 = boss) |
| wColiseumBattle | Battle number within current round |
| $DA03-$DA08 | 3 enemy stat IDs (16-bit each) |
| $DA02 | Battle mode ($02 = arena) |

---

## $2C — CheckInvFull (Handler: $04:$6064)

### What it does
1. Reads 1 param (branch target address) and advances script counter
2. Iterates `wInventory` (20 slots at $D980), counting non-zero/non-$FF entries
3. If count < 20 (NOT full): continues to next script command (skips branch)
4. If count == 20 (inventory full): branches to the param address via ScriptBranch

### Handler Code Logic
```
label4_6064:
    ; Advance script counter (read 1 param)
    inc [wScriptCounter]
    
    ; Count filled inventory slots
    HL = wInventory
    B = $14 (20 slots)
    C = 0 (count)
    for each slot:
        if [HL] == 0 or [HL] == $FF: stop counting
        else: C++
    
    if C < $14:  → Jump_004_55f5 (continue script, inventory has room)
    if C >= $14: → MapTypeDispatch + ScriptBranch (inventory full, branch)
```

### Usage Pattern — 45 uses

**Castle/main areas (5 uses):** NPCs offering gifts with full-inventory fallback
```
Castle_Script05:
    say $083B           ; NPC dialogue
    check_inv_full $521F ; if full → branch to $521F
    say $083C           ; gift given message
    give_item $0017     ; give item ID $17
    end
.addr_521F:
    say $083D           ; "Your items are full!" message
    end
```

**Post-game Maps $57-$5C (40 uses):** Identical pattern across 6 maps × ~6 NPCs
Each NPC follows: check RAM state → show dialogue → `check_inv_full` → give item → clear state

### Map Distribution
| Map | Uses | Context |
|-----|------|---------|
| Castle | 2 | Gift NPCs |
| Bazaar | 1 | Shop reward |
| Stable | 1 | Breeding reward |
| ArenaRooms | 1 | Arena prize |
| Map_0D | 1 | Side area |
| Maps $57-$5C | 38 | Post-game gift NPCs (6 maps × ~6 NPCs) |

---

## $2D — MonsterSlotDialogue (Handler: $04:$6093)

### What it does
1. Reads 1 param (monster slot index: 0, 1, or 2)
2. Reads `$CA8E + param` to get monster buffer index
3. If value is $FF (empty slot): returns silently
4. Looks up monster species from party buffer at $CACA
5. Calls Bank $03 entry 1 to get species family
6. Indexes into family text table at $04:$60F4
7. Uses Bank $01 entry 7 for additional lookup
8. Queues the resulting text ID for display

### Handler Code Logic
```
label4_6093:
    ; Read param (slot index)
    inc [wScriptCounter]
    call MapTypeDispatch → C = param value
    
    ; Look up monster in slot
    A = [$CA8E + C]
    if A == $FF: return (empty slot)
    
    ; Get species from party buffer
    HL = $CACA
    call GetMonsterDataPtr → species at [HL]
    [wTempSpeciesId] = species
    
    ; Get family from species (Bank $03)
    rst $10 → Bank $03 entry 1
    family = [$DA33]
    
    ; Look up family text table
    text_table_ptr = [$60F4 + family * 2]
    
    ; Get slot-specific text from family table
    rst $10 → Bank $01 entry 7
    text_id = [text_table_ptr + result * 2]
    
    ; Queue text for display
    [wScriptQueuedTextId] = text_id
    set bit 1 of [wScriptStateFlags]
```

### Usage — 3 total
All in ArenaLobby, displaying per-monster-species dialogue:
```
ArenaLobby_Script02:  check_step $0000  ; Party slot 0
ArenaLobby_Script03:  check_step $0001  ; Party slot 1
ArenaLobby_Script04:  check_step $0002  ; Party slot 2
```

These are the 3 NPCs representing your monster party in the arena lobby. When talked to, they show dialogue specific to their monster family (Slime family says one thing, Dragon family says another, etc.).

### Data Table at $04:$60F4
Contains pointers to per-family text arrays. Each family has a sub-table of text IDs indexed by a secondary lookup. The table at $60F4 is misassembled as instructions in the current bank_004.asm — it needs annotation as data.

---

## Verification Needed

To fully confirm these analyses, the following SameBoy breakpoint tests would be definitive:

1. **$2C confirmation:** Set breakpoint at $04:$6064, trigger by talking to an NPC who gives items (e.g., Castle_Script05). Verify `wInventory` scan and branch behavior with full vs not-full inventory.

2. **$2D confirmation:** Set breakpoint at $04:$6093, talk to the 3 monsters in arena lobby. Verify C register contains 0/1/2 and that $CA8E is the party monster buffer.

3. **$1F confirmation:** Set breakpoint at $04:$5D5B, enter an arena battle. Verify `wArenaGroup` and `wColiseumBattle` values match expected enemy team.

---
*Analyzed June 2026 from Bank $04 disassembly (bank_004.asm lines 3567-4194).*
*Handler code cross-referenced with PARAM_COUNTS and all 48 script uses.*
