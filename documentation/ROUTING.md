# Room Routing & Transitions

## Core Mechanism

ALL room transitions that change map_type go through one code path:

1. Destination map_type written to `$C96D` at `$0B:$45AB`
2. Gate flag written to `$C96E` at `$0B:$45AF`
3. `$C96D` copied to `$C968` (active map_type) at `$0B:$401E`
4. `$C96E` copied to `$C969` (in_gate flag) at `$0B:$4024`
5. Room loading at `$0B:$4088` reads spawn table at `$26DD + map_type × 8`

Transition data block format:

```
Byte 0:   destination map_type
Byte 1:   gate flag (0x00 = normal, 0x01 = entering gate)
Bytes 2-4+: spawn/position data (bytes 3-4 are primary spawn coordinates)
```

Entry size is ~7 bytes, tightly packed. **Only overwrite bytes 0, 3, 4** when redirecting.

## Five Code Paths for $C96D Writes

1. **Exit transitions** (`$0B:$4568`): Walk-on triggers from exit data table. Most common.
2. **Warp/teleport** (`$0B:$45A5`): Script-triggered teleports via bank $04.
3. **Gate entry**: Gate hub → gate world transitions.
4. **Arena**: Special handling for arena room transitions.
5. **Story events**: Event-driven room changes via bank $50 state machine.

## Exit Data Format

Exit data table (from step entries) contains 5-byte entries:
- `$90 FF X Y dest_map_type` — walk-on coordinate triggers
- `$8F ...` — arrival/spawn points (skipped by exit checker)
- `$82/$80 ...` — skipped
- Non-bit-7 byte or `$FF` — terminates search

The `$90` exit byte 4 is the destination map_type directly (not a room_id).

## Bidirectional Routing Recipe

To redirect entrance A → room B with correct return:

```
1. At ENTRY_ADDR:     write NEW_MAP_TYPE (byte 0)
2. At ENTRY_ADDR+3:   write DEST_SPAWN_BYTE3
3. At ENTRY_ADDR+4:   write DEST_SPAWN_BYTE4
4. At DEST_EXIT_ADDR+2: write RETURN_SPAWN bytes
```

**DO NOT change byte 5+** — corrupts adjacent packed data.

## Patchable vs Non-Patchable Transitions

### Confirmed Patchable Entry Transitions
Any transition that reads from the exit data table at `$0B:$4568` can be redirected
by changing the destination map_type in the ROM data. Most room-to-room doors use this.

### Non-Patchable Transitions
Some transitions are hardcoded in the state machine (bank $50/$51) or use special
initialization. These need code patches to redirect:
- Castle → GreatTree initial sequence
- Gate return transitions
- Arena battle room setup

## Working Map_Types for Redirection

Tested and working:
```
0x01 GreatTree    0x02 Bazaar       0x03 Gate Hub      0x04 Farm
0x07 Arena Rooms  0x09 Starry Shrine 0x12 Library       0x18 Well
0x53 Forest Maze  0x57 Maze 1        0x58 Maze 2        0x59 Maze 3
```

Crash with wrong init parameters (may work with correct byte 2+ values):
```
0x00 Castle    0x05 Stable    0x06 Arena Lobby  0x0A Secret Passage
0x0D Old Man   0x10 Copycat   0x16 MedalMan     0x23 Room of Beginning
0x30+ Bosses   0x42 Labyrinth 0x52 Coliseum     0x5D Arena Battle
```

## Key ROM Addresses

| Address | Purpose |
|---------|---------|
| `$0B:$4568` | Exit checker — reads exit data, writes `$C96D` |
| `$0B:$45AB` | Transition executor — destination map_type write |
| `$0B:$4088` | Room loading — reads `$26DD` spawn table |
| `$00:$26DD` | Spawn table — `map_type × 8` to get room init data |
| `$0B:$4B43` | Room data pointer table — indexed by `wMapID` |

## Key RAM Variables

| Address | Purpose |
|---------|---------|
| `$C925` | Current screen index |
| `$C939` | Current floor number |
| `$C968` | Active map_type |
| `$C969` | In-gate flag |
| `$C96D` | Pending destination map_type |
| `$C96E` | Pending gate flag |
