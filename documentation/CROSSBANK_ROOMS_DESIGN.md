# Cross-Bank Room System Design

## The Problem
Bank 0x0B has the room pointer table AND all room data, with zero free space.
The pointer table uses bank-local pointers (0x4000-0x7FFF), so all data must
be in whichever bank is currently mapped at that address range.

## The Solution: WRAM-Resident Room Loader

### How GBC Memory Works
```
0x0000-0x3FFF  Bank 0 (ALWAYS mapped, never changes)
0x4000-0x7FFF  Switchable bank (currently bank 0x0B for rooms)
0xC000-0xDFFF  WRAM (always accessible, read/write)
```

### The Room Loader Chain ($0B:$4274-$42AB)
```
Step 1: Read pointer table → room_ptr        ($427A-$4289, 16 bytes)
Step 2: Index by screen → step_block_ptr     ($428A-$4296, 13 bytes)
Step 3: Read RAM flag → step entry           ($4297-$42A5, 15 bytes)
Step 4: Read interact_ptr from step          ($42A6-$42AB,  6 bytes)
                                              Total: 50 bytes
```

After Step 1 gets the room_ptr, Steps 2-4 follow bank-local pointers.
If we switch to a different bank, Steps 2-4 read from the NEW bank.
But the CODE for Steps 2-4 is also in the switchable bank — it vanishes!

### The Fix: Copy Steps 2-4 to WRAM

```
BOOT TIME:
  Copy 33 bytes ($428A-$42AB) → WRAM at $CF00

RUNTIME (patched Step 1):
  1. Read pointer table entry as normal
  2. Check: is the high byte a "redirect marker" (e.g., 0x00)?
     - Valid room ptrs are 0x4C13-0x7D24 (high byte 0x4C-0x7D)
     - A high byte of 0x00 is impossible for real data
  3. If normal: proceed to WRAM copy of Steps 2-4 (same bank)
  4. If redirect: low byte = target bank number
     a. Switch ROM bank register ($2000) to target bank
     b. Set HL = $4000 (room data at start of target bank)
     c. Jump to WRAM copy of Steps 2-4
  5. WRAM code follows pointers in the NEW bank
  6. After return, caller continues in bank 0x0B
     (the ROM bank gets restored by the game's normal bank management)
```

### What We Need

| Component | Size | Location |
|-----------|------|----------|
| Boot init: copy to WRAM | ~10 bytes | Bank 0x00 (run once) |
| WRAM-resident loader | 33 bytes | WRAM $CF00 |
| Dispatch logic (check marker) | ~20 bytes | Bank 0x00 or bank 0x0B |
| Patch at $428A | 3 bytes | Bank 0x0B (replace with `jp $CF00` or `call $00xx`) |
| Room data for new rooms | ~50-100 bytes each | Bank 0x68 (258KB free!) |
| Pointer table entries | 2 bytes each | Existing alias slots |

### Pointer Table Entry Format

**Normal room (existing):**
```
ptr_table[map_type] = room_data_ptr  (e.g., 0x4C13)
  High byte: 0x4C-0x7D (valid bank-local address)
```

**Cross-bank room (new):**
```
ptr_table[map_type] = 0x00 | target_bank  (e.g., 0x0068 for bank 0x68)
  High byte: 0x00 (impossible for real data → redirect marker)
  Low byte: bank number
```

Room data lives at a fixed offset in the target bank (e.g., always at $4000).
Multiple rooms per bank using a secondary index, or one bank per room.

### Room Data Layout in Target Bank

At $4000 in the target bank, place the EXACT same structure as a normal room:
```
$4000: screen_ptr_block  (4 slots × 2 bytes per screen)
$4008: step_block        (RAM flag ptr + step entries)
$4016: interact_block    (NPC data + 0xFF terminator)
$40xx: exit_block        (exit triggers + 0xFF terminator)
```

All internal pointers (step_block_ptr, interact_ptr, exit_ptr) are bank-local
addresses within the target bank. They "just work" because the bank is mapped.

### Risks & Mitigations

1. **Bank restoration**: The game must restore bank 0x0B after the room loader
   returns. Check if the game has a "current bank" variable that auto-restores.
   Most GBC games do this via a bank stack or shadow register.

2. **Gate path**: The gate loading path ($42AC+) also needs the same treatment
   if we want cross-bank gate rooms. Can be done later.

3. **Other code referencing room data**: If other functions (besides the room
   loader) read room data directly, they also need bank-switch handling.
   The exit handler at $45AB reads exit blocks — it may need similar treatment.

### Implementation Order

1. **Run investigate_tail.py** → determine if 732 bytes at end of bank 0x0B
   can be reclaimed. If yes, that's instant space for ~15 rooms WITHOUT
   any bank-switch complexity.

2. **If tail is movable**: relocate tail data to another bank, free up 732 bytes
   in bank 0x0B, write new room data there. Simple and safe.

3. **If tail is not movable**: implement the WRAM-resident loader approach.
   This is a one-time investment that unlocks unlimited rooms.

4. **Either way**: add room-building UI to editor.py that generates the binary
   room data (screen ptrs + step blocks + interact blocks + exit blocks).
