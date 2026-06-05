# ROUTING HANDOFF — Next Session

## What Was Accomplished

Room routing for DWM1 (GBC) has been fully reverse-engineered and proven working:
- **24 patchable entry transitions** cataloged with exact ROM addresses
- **22 patchable exit transitions** cataloged with exact ROM addresses  
- **Bidirectional routing proven working** — tested Library↔Shrine and Arena↔Bazaar swaps
- **Spawn position patching proven** — bytes 3-4 of entry/exit data control spawn coordinates
- **Safe patching rules established** — only change bytes 0, 3, 4 of entries to avoid corrupting adjacent packed data

## Key Files

| File | Purpose |
|---|---|
| `ROUTING_DISCOVERIES.md` | Complete technical reference (addresses, formats, code paths) |
| `tools/hl_calc.py` | Calculator for SameBoy debugging (PC + HL → flat address) |
| `tools/find_all_transitions.py` | Scans ROM for transition candidates, outputs JSON/CSV |
| `extracted/all_transitions.json` | Scanned transition data |
| `extracted/transitions.csv` | Spreadsheet-friendly transition catalog |

## Bidirectional Routing Recipe

To redirect entrance A to load room B, with correct return:

```json
{
  "raw_bytes": {
    "[ENTRY_ADDR]": "[NEW_MAP_TYPE]",
    "[ENTRY_ADDR+3]": "[DEST_SPAWN_BYTE3]",
    "[ENTRY_ADDR+4]": "[DEST_SPAWN_BYTE4]",
    "[DEST_EXIT_ADDR+2]": "[RETURN_SPAWN_BYTE2] [RETURN_SPAWN_BYTE3]"
  }
}
```

Where:
- `ENTRY_ADDR` = flat address of the entrance being redirected
- `NEW_MAP_TYPE` = destination map_type (1 byte)
- Spawn bytes 3-4 from the destination's NORMAL entry data
- `DEST_EXIT_ADDR` = the destination room's exit transition address
- Return spawn bytes from the SOURCE room's normal exit data

**DO NOT change byte 5+ of entries** — this corrupts adjacent packed data.

**DO NOT write 12-byte blocks** — entries are ~7 bytes, tightly packed.

## GUI Implementation Plan

### Room Routing Editor Tab
Add to `editor.py` a "Room Routing" tab with:

1. **Dropdown: Source transition** — list all 24 entry transitions by name
2. **Dropdown: Destination** — list all working map_types (0x01-0x59, excluding known breakers)
3. **Auto-populate spawn bytes** from the destination's normal entry data (bytes 3-4)
4. **Exit redirect checkbox** — if checked, also patch the destination's exit to return near the source
5. **Preview** — show current→new routing before applying
6. **Apply** — write to edits.json raw_bytes

### Data Structure for GUI
```python
ENTRY_TRANSITIONS = {
    "GreatTree scr5 → Library": {
        "entry_addr": 0x02CFE8,
        "original_map_type": 0x12,
        "original_data": "12 00 04 05 07 04 05",
        "spawn_byte3": 0x05,
        "spawn_byte4": 0x07,
    },
    # ... all 24 entries
}

EXIT_TRANSITIONS = {
    "Library": {
        "exit_addr": 0x02E070,
        "original_map_type": 0x01,
        "original_data": "01 00 88 05 03 06",
        "spawn_byte2": 0x88,
        "spawn_byte3": 0x05,
    },
    # ... all 22 exits
}
```

## Still Needs Investigation

### Uncaptured Exits
The following room exits have NOT been captured via SameBoy:
- All boss rooms except Healer boss (0x30-0x4F range)
- Goopy rooms on GreatTree screen 8
- Secret Passage exits
- Various late-game gate rooms

**To capture:** `breakpoint $0B:$45AB`, enter room, `continue`, leave room, `registers`, `examine/12 $[HL-1]`.

### Double Door Entries
Double doors (Arena, Castle entrance) have separate addresses per tile. Known:
- Arena left tile: `0x02CFD8`
- Arena right tile: likely `0x02CFDF` (needs confirmation)
- Castle doors: need both tiles captured

### Non-Patchable Transitions
These use computed code paths ($524B, $52E8, $52F3, $5A16, $46C1):
- Castle ↔ GreatTree exterior double doors (RAM-based $524B/$52E8)
- Entering Bazaar from screen 6 ($52F3 computed)
- Vine shortcuts and farm holes ($5A16 register-based)
- Gate floor transitions ($46C1 RAM-based)

To make these patchable would require tracing the code that sets up the RAM values and finding the ROM source data.

### Screen/Tilemap System
Room sizes (1-screen vs multi-screen scrolling) are NOT yet understood. Key unknowns:
- The `bytes_01` field in step entries (values like 0x2A01, 0x2A09) — likely tilemap references
- How scrolling boundaries are defined
- How multi-screen rooms (GreatTree 8 screens, Library 2 screens) are structured

### Spawn Position Format
Bytes 3-4 of transition data control spawn. Full format of bytes 2-5:
- Byte 2: often has bit 7 set for exits (0x80, 0x84, 0x88, 0x8C, 0x8D, 0x89). For entries, typically 0x00-0x09. Might encode scroll position or screen offset.
- Byte 3: spawn coordinate (small values 0x02-0x09)
- Byte 4: spawn coordinate (small values 0x01-0x07)
- Byte 5: often 0xFF or another value — DO NOT MODIFY (affects adjacent entry parsing)

## Creating New Rooms — Roadmap

### Level 1: Reskin Existing Room (Medium)
1. Find an unused map_type (e.g., 0x0F "Unknown", 0x4F "Boss: Unused Gate")
2. Redirect an entrance to load this map_type
3. Use tile_inspector to modify its tileset graphics
4. Patch its exit transition to return somewhere useful

### Level 2: New Teleport Point (Hard)
1. Find the interaction data pointer for the target room (bytes 4-5 of step entry)
2. Locate free space in Bank 0B (use `find_free_space.py`)
3. Copy existing interaction data to free space, add new entry
4. Repoint the step entry's bytes 4-5 to the new location
5. Add transition data block for the new entrance

### Level 3: Genuinely New Room (Very Hard)
1. All of Level 2, plus:
2. Create new entry in map pointer table at `$4B43`
3. Create step entries with exit/NPC pointers
4. Create tilemap data (requires decoding `bytes_01` format)
5. Either reuse an existing tileset or create a new one (LZ77 compressed)

### Free Space
Bank 0B may have free regions near the end ($7F00+). The ROM is 2MB with potentially large unused regions in later banks. Use `find_free_space.py` to locate candidates.

## Working Map_Types for Redirection

Tested from Library entrance — these load without crashing:
```
0x01 GreatTree    0x02 Bazaar       0x03 Gate Hub      0x04 Farm
0x07 Arena Rooms  0x09 Starry Shrine 0x12 Library       0x18 Well
0x53 Forest Maze  0x57 Maze 1        0x58 Maze 2        0x59 Maze 3
```

These CRASH when loaded with Library-style parameters:
```
0x00 Castle    0x05 Stable    0x06 Arena Lobby  0x0A Secret Passage
0x0D Old Man   0x10 Copycat   0x16 MedalMan     0x23 Room of Beginning
0x30+ Bosses   0x42 Labyrinth 0x52 Coliseum     0x5D Arena Battle
```

Crashing destinations may work with correct initialization bytes (bytes 2+ of entry data). Needs per-destination testing.

## IPS Patch Export

Not yet implemented but trivial — `edits.json` raw_bytes entries map directly to IPS records:
```
IPS format: "PATCH" + [3-byte offset][2-byte size][data bytes]... + "EOF"
```

A skeleton exists in `find_transitions.py` but needs completion and testing.
