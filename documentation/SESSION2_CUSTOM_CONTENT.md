# Session 2: Supplementary Reference

> All corrections merged into: TEXT_SYSTEM.md, KEY_LESSONS.md, DATA_STRUCTURES.md, BANK04_SCRIPT_ENGINE.md.
> This file contains only supplementary detail not in other docs.

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

## Opcode $2A (GiveItem) — Working Logic, Broken Flow

Handler at `$04:$5FDB` correctly scans `wInventory` for first `$00`/`$FF` slot
and writes item. Original uses `ret` not `jp ScriptExecContinue`, freezing scripts.

**Fix (proven):** Redirect jump table entry to wrapper in padding:
```asm
GiveItemWrapper:
    call label4_5fdb         ; original handler (ret returns here)
    jp Jump_004_55f5         ; ScriptExecContinue
```
Zero insertion. Use with `$FF2C` (CheckInvFull) before `$FF2A` for full pattern.

## BGM Offset Table (from known_RAM_map.md)

| Offset | Music |
|--------|-------|
| $02 | No music | $09 | GreatTree | $0C-$1B | Gate music 1-6 |
| $1E | Arena | $21 | Ending | $24 | Main Menu |
| $27 | Battle | $2B | Battle vs Mireille | $31 | Starry Shrine |
| $37-$44 | Fanfares 1-4 | $47 | Level Up | $4B-$4D | Monster Encounter |
| $4F | Game Over | $5D | Intro | $9D | Test BGM |

Stored at `wCurrPlayingBGM` ($C8B5). Set via script opcode $41.
