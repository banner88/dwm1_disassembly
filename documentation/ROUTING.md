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


---

# Appendix: First-5-Minutes Boot/Intro Trace

## Goal
Map every NPC interaction and cutscene in the game's opening to our
labeled Castle/GreatTree scripts. This tells us exactly which
Castle_ScriptXX = which NPC, and which opcodes fire during cutscenes.

## Setup (do once)

Load `game.gbc` in SameBoy. Open the debugger (Ctrl+C or however you
access it). Enter these commands:

```
breakpoint $04:$55EC
```

This is **ScriptInit** — fires every time an NPC script starts executing.
That's all we need. One breakpoint.

## How To Record Each Interaction

When the breakpoint fires, type:

```
examine $D8D3
examine $D8D4
examine $D8D5
```

**Record these three values:**
- `$D8D3` = map_type ($00 = Castle, $01 = GreatTree)
- `$D8D4` = **script_id** — this maps directly to `Castle_ScriptXX` or
  `GreatTree_ScriptXX` in our labeled assembly
- `$D8D5` = script counter (should be $00 at script start)

Then type `continue` to resume.

**Write down what just happened in-game** before hitting continue. Example:
```
Talked to dresser in bedroom → D8D3=00, D8D4=0D (= Castle_Script13)
```

## Walkthrough — What to Do In-Game

### Phase 1: Terry's Bedroom (game start)
Start a **new game**, name the character whatever.

1. You start in the bedroom. **Examine every object** — the bookshelf,
   the dresser, the bed, the stuffed animal, the window. Each one should
   trigger the breakpoint. Record D8D3/D8D4 for each.

2. Talk to Milayou (the girl NPC). Record.

3. Go to bed (whatever triggers the Warubou scene). The cutscene may
   fire MULTIPLE breakpoints as NPCs appear/talk. Record ALL of them
   in sequence.

### Phase 2: After Warubou
4. After the cutscene, you're back in the bedroom. Examine the objects
   again if possible — script_id might differ now (story flags changed).

5. Leave the bedroom, go downstairs. Talk to every NPC on each floor:
   - Parents
   - Guards
   - Any other castle NPCs

### Phase 3: GreatTree
6. Exit to GreatTree. D8D3 should change to $01.
   Talk to NPCs you encounter:
   - The King
   - The old man near the gate
   - Anyone in the stable area (Pulio?)

7. Go to the farm area (top of tree). Talk to Pulio.

### Phase 4: First Gate
8. Enter your first gate. Note the map_type change.
   Any NPC interactions in the gate entrance room — record.

## What I Especially Need

### Critical Data
- **Warubou cutscene**: How many breakpoints fire? What script_ids?
  This is the biggest scripted sequence in the opening.
- **Before vs after flags**: When you examine the bookshelf BEFORE and
  AFTER the Warubou scene, does script_id change? Or same script_id
  but different branch taken?

### Nice to Have (if easy)
After the Warubou cutscene, check event flags:
```
examine $D99B
examine $D99C
examine $D99D
examine $D99E
examine $D99F
examine $D9A0
examine $D9A1
```
These show which story flags got set. Compare to the flag values
in the BranchIfFlagSet conditions ($0003, $0008, $001D, $0022, etc.)

## Recording Template

Copy-paste this for each interaction:

```
Action: [what you did]
D8D3: [value]  (map_type)
D8D4: [value]  (script_id → Castle_ScriptXX or GreatTree_ScriptXX)
D8D5: [value]  (counter, usually 00)
Notes: [anything unusual — multiple breakpoints, cutscene, etc.]
```

For the Warubou cutscene specifically, record EVERY breakpoint hit:
```
Warubou cutscene:
  Hit 1: D8D3=__, D8D4=__  (first NPC action)
  Hit 2: D8D3=__, D8D4=__  (next)
  Hit 3: D8D3=__, D8D4=__  (etc.)
  ...
```

## What This Data Unlocks

With script_id → NPC mappings, I can:
1. Annotate every Castle_ScriptXX with "this is the bookshelf",
   "this is the guard at the stairs", etc.
2. Decode which event flag checks correspond to which story beats
3. Build the script decompiler with real human-readable output
4. Determine what the ~30 unknown CmdXX opcodes do by seeing them
   fire during the Warubou cutscene

This is the fastest path to the custom event editor.

(Merged from FIRST_5MIN_TRACE.md, 2026-06-13.)
