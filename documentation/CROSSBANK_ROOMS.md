# Cross-Bank Room Expansion Plan

## Problem
Bank $0B is 100% full — 0 bytes free code, 1 byte free data. All room data at $4B43-$7FFF (13,500 bytes).

## Solution Implemented: SharedPtrChase Refactoring ✅

Four room-data reader functions contained **44 identical bytes** of pointer-chase code at $4244/$427A/$44A7/$4533. Consolidated into a single `SharedPtrChase` function.

**Result:** 119 bytes freed at $4ACC-$4B42. Build MD5: `b90957482011c8083a068781033715b7`.

### Implementation Details
- Bank $0B split into two SECTION directives: Code ($4000) and Data ($4B43)
- SharedPtrChase at end of code section, 4 call sites
- 3 misassembled `jr` instructions in end-of-code data converted to `db` directives
- Data section verified byte-identical to original ROM

### The 4 Refactored Functions
| Function | Returns | Purpose |
|----------|---------|---------|
| ReadStepBlock | step_id+tileset (bytes 0-1) | Tile loading |
| ReadInteractPtr | interact_ptr (bytes 2-3) | NPC loading |
| RoomEntry9_SpecialRooms | exit_ptr (bytes 4-5) | Special exit check |
| RoomEntry6_ExitChecker | exit_ptr (bytes 4-5) | Normal exit check |

## Next Step: Overflow Bank Hook

With 119 freed bytes, add a WRAM override to SharedPtrChase:

```asm
SharedPtrChase:
    ld a, [wRoomOverrideActive]  ; WRAM flag
    or a
    jr z, .normalPath
    ld hl, wRoomDataBuffer       ; read from WRAM shadow copy
    jr .common
.normalPath:
    ld hl, RoomPtrTable          ; original ROM path
.common:
    ; ... rest of pointer chase ...
```

A ROM0 trampoline (~40 bytes at $3FE8) copies room data from overflow bank to WRAM before room init.

## Available Resources
- **119 bytes** free in Bank $0B code section ($4ACC-$4B42)
- **24 empty banks** for overflow: $60, $62, $64, $67-$77, $79-$7A, $7C, $7E-$7F
- **200 bytes** free in Bank $00 for ROM0 trampoline
- Room data sizes: 141B (ArenaLobby) to 897B (Castle), avg 625B
- One 16KB bank holds ~26 rooms. Total capacity: 600+ custom rooms.

---
*Verified June 2026. SharedPtrChase refactoring tested and byte-verified.*
