# First 5 Minutes Script Trace — SameBoy Instructions

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
