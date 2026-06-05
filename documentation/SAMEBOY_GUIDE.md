# SameBoy Room Characterization Guide

## Teleport Method (Verified Working)

**Setup (once per session):**
```
breakpoint $0B:$45AB
```

**Each teleport:**
1. Walk through ANY door/stairs
2. Breakpoint fires. You see `LD [$c96d], a` — register A holds the destination
3. Check current destination: `registers` (look at A in the AF register)
4. Override destination:
```
print a = $09
continue
```
5. You're in the target room (may spawn in a wall — just walk out)

For gate rooms, the gate flag is written at `$45AF`. After changing A and continuing, the breakpoint may fire again for the gate flag — just `continue` past it.

**Example — teleport to Starry Shrine (0x09):**
```
breakpoint $0B:$45AB
; walk through Library door
; breakpoint fires:
registers              ; AF shows $12xx (Library)
print a = $09          ; change to Starry Shrine
continue               ; room loads
; if breakpoint fires again (gate flag write), just:
continue
```

## Check Current State

```
examine $C968          ; current map_type
examine $C969          ; gate flag (00=normal, 01=gate)
examine $D9E9          ; general step variable
```

## Category A: Unknown Rooms

For each, walk through any door, override A at the breakpoint:

| Room | Command | Question |
|---|---|---|
| 0x13 | `print a = $13` | Has bookshelf NPC — what room? |
| 0x19 | `print a = $19` | Has fighting NPC — what room? |
| 0x1A | `print a = $1A` | Multiple NPCs — what room? |
| 0x2F | `print a = $2F` | Many NPCs — cutscene room? |

## Category B: Boss Rooms — Test ONE First

**Test Healer boss room (0x30).**

Before defeating Healer:
```
; walk through any door, breakpoint fires:
print a = $30
continue
```
Note: is boss NPC visible?

After defeating Healer, repeat. Does it show a gate instead?
If yes → all boss rooms use step variants, skip individual characterization.

**All boss rooms (only if step variants NOT confirmed):**
0x30 Beginning, 0x31 Villager, 0x32 Talisman, 0x33 Memories, 0x34 Bewilder,
0x36 Peace, 0x37 Bravery, 0x38 Well, 0x39 Strength, 0x3A Anger,
0x3B Farm, 0x3C Arena Left, 0x3D Joy, 0x3E Wisdom, 0x3F Medal,
0x41 Happiness, 0x43 Temptation, 0x44 Labyrinth, 0x45 Judgment,
0x46 Ambition, 0x47 Demolition, 0x48 Mastermind, 0x49 Control,
0x4A Extinction, 0x4B Sleep, 0x4C Bazaar Edge, 0x4D Arena Right, 0x4F Unused

## Category C: Gate Entrance Rooms

Each has Watabou (sprite 0x0B). Teleport, talk to Watabou, note dialogue:

| Room | Command | Gate Room Name |
|---|---|---|
| 0x23 | `print a = $23` | Room of Beginning |
| 0x24 | `print a = $24` | Villager/Talisman |
| 0x25 | `print a = $25` | Memories/Bewilder |
| 0x26 | `print a = $26` | Peace/Bravery |
| 0x27 | `print a = $27` | Strength/Anger |
| 0x28 | `print a = $28` | Joy/Wisdom |
| 0x29 | `print a = $29` | Happiness/Temptation |
| 0x2A | `print a = $2A` | Labyrinth/Judgment |
| 0x2B | `print a = $2B` | Reflection |
| 0x2C | `print a = $2C` | Ambition/Demolition |
| 0x2D | `print a = $2D` | Mastermind/Control |
| 0x2E | `print a = $2E` | Extinction/Sleep |

## Category D: Castle Step Identification

Check which step you're in at different story points:
```
; enter Castle normally, then Ctrl+C to break:
examine $D92A          ; Castle step value
```

Do this at major milestones: start of game, after first gate, after arena unlock, tree growth events, post-tournament.

## Quick Reference

```
; === SETUP (once) ===
breakpoint $0B:$45AB

; === TELEPORT ===
; walk through any door, then:
print a = $NN          ; target map_type
continue
; if breakpoint fires again, just: continue

; === CHECK STATE ===
examine $C968          ; confirm map_type
examine $D9E9          ; step variable
```

## Recording Template

```
Map_type: 0x__
Name: ___
NPCs visible: __ count
  NPC 1: [description] at approx position
  NPC 2: [description]
Talked to NPC 1: "first line..."
Notes: ___
```
