# DWM1 Romhack — Session Handoff

## Project State Summary

Building a custom romhack of Dragon Warrior Monsters 1 (GBC). GUI editor (`editor.py`) writes patches to `edits.json`, built by `build.py` into a patched ROM. Major systems decoded: room routing, NPC spawning, exit transitions, text connections.

## Key Files

### Editor & Build
- `/mnt/user-data/outputs/editor.py` — Main GUI editor (Streamlit), latest version
- `/mnt/user-data/uploads/build.py` — ROM patcher
- `/mnt/user-data/uploads/rom.py` — ROM reader class
- `/mnt/user-data/outputs/npc_names.json` — Persistent sprite/NPC naming file (96 sprites named)

### Documentation
- `/mnt/user-data/outputs/SAMEBOY_GUIDE.md` — SameBoy debugging commands (verified working)
- `/mnt/user-data/uploads/ROUTING_DISCOVERIES.md` — Room transition technical reference (from prior session)
- `/mnt/user-data/uploads/ROUTING_HANDOFF.md` — Routing architecture overview (from prior session)
- `/mnt/user-data/uploads/GRAPHICS_HANDOFF.md` — Graphics/tile system docs
- `/mnt/user-data/uploads/known_NOTES.md` — Map type IDs
- `/mnt/user-data/uploads/known_RAM_map.md` — RAM addresses
- `/mnt/user-data/uploads/known_ROM_map.md` — ROM structure

### Analysis Tools (in tools/ directory)
- `dump_all_npcs.py` — Parse all rooms' NPC spawn data → `extracted/npc_catalog.json`
- `dump_all_exits.py` — Parse all exit transitions → `extracted/all_exits.json` (270 exits found)
- `match_npc_text.py` — Cross-reference NPC script IDs with text pointer tables
- `check_exit_byte5.py` — Classify exits as safe/unsafe for destination changes
- `analyze_screens.py` — Screen count analysis (BROKEN — heuristic fails, all rooms show 1)
- `dump_medalman.py`, `dump_bank.py`, `dump_all_text.py` — Earlier analysis tools

### Extracted Data
- `extracted/npc_catalog.json` — 772 NPC entries across 60 rooms
- `extracted/sprite_reference.json` — 96 unique sprites with usage counts
- `extracted/all_exits.json` — 270 exit transitions with full data
- `extracted/npc_text_mapping.json` — Room → text table mappings (partial, some wrong)
- `extracted/npc_with_text.json` — NPCs with dialogue previews

---

## COMPLETED: NPC System

### NPC Entry Format (5 bytes, fully confirmed by patching tests)
```
[type] [sprite_id] [X] [Y] [script_id]
```

**Confirmed by tests:**
- byte 2 = X: changing from 2→5 moved MedalMan 3 tiles RIGHT ✓
- byte 3 = Y: changing from 3→6 moved MedalMan 3 tiles DOWN ✓
- byte 4 = script: changing crashed on talk (invalid script reference) ✓
- byte 1 = sprite: visual appearance of NPC

### Type Byte (byte 0) — High Nibble = Movement
| High nibble | Behavior |
|---|---|
| 0x0_ | Standing still, talkable |
| 0x1_ | Walking randomly |
| 0x2_ | Fixed facing direction |
| 0x3_ | Walking patrol path |
| 0x4_ | Static decoration/object |
| 0x5_ | Off-screen trigger (sprite 0x21 at X=10+) |
| 0x6_ | Animated decoration |
| 0x7_ | Off-screen marker |

Low nibble likely encodes facing direction or sub-behavior variant.

### NPC Editor Tab (👤 NPCs)
- Room selector with custom names from `npc_names.json`
- Game state variant selector grouped by `interact_ptr` (not step_id — fixes duplicate display)
- Cross-state NPC tracker: shows which NPCs appear across variants (✓same pos / ⚡moves)
- Per-NPC editing: sprite, X, Y, type with save/revert buttons
- Save button correctly handles revert-to-original (deletes stale edits)
- Naming UI with dropdowns: sprite naming (current room sprites first), NPC labeling, room name override
- Sprite Reference expander
- Global NPC revert in Revert tab

### All 96 Sprites Named
Complete sprite characterization saved in `npc_names.json`. Includes human NPCs (King, Queen, Jester, MedalMan, etc.), monster sprites (Healer, FangSlime, Watabou, etc.), battle/scene sprites (PlayerTerry, party monsters), and special sprites (WalkableGate, Meat, animations).

---

## COMPLETED: Room Routing System

### Entry Editor — FULLY WORKING
**Key discovery: Screen byte (byte 2) = 0x00 is universally safe for ALL entry destinations.**

Entry data format: `[map_type] [gate_flag] [screen] [X] [Y] [byte5+]`
- 24 patchable entry transitions cataloged
- Patching bytes 0 (map_type), 1 (gate flag), 2 (screen), 3 (X), 4 (Y)
- Screen byte auto-defaults to 0x00 when destination changes
- Gate flag checkbox (checked by default, clear for normal rooms)
- All destinations work with screen=0x00 (boss rooms, coliseum, gate floors, etc.)

### Exit Editor — WORKING with destination-specific spawn values
**Key discovery: Exit screen/X/Y must use the DESTINATION room's own entry values.**

The screen byte indexes a lookup table at $2DE7 that produces pixel offsets:
```
Table at $2DE7 (16 entries, 2 bytes each):
Index 0: (0,0)   Index 1: (10,0)  Index 2: (20,0)  Index 3: (30,0)
Index 4: (0,8)   Index 5: (10,8)  Index 6: (20,8)  Index 7: (30,8)
Index 8: (0,16)  Index 9: (10,16) Index A: (20,16) Index B: (30,16)
Index C: (0,24)  Index D: (10,24) Index E: (20,24) Index F: (30,24)
```
Screen byte lower nibble selects the table entry. Bit 7 adds 8 to Y.
X/Y values are SWAP'd (nibble-swapped = multiply by 16) before adding to base.

**Why some exits crash when destination changes:**
The original screen byte (e.g., 0x88 for Library→GreatTree) produces large pixel offsets that are valid for GreatTree (large room) but out-of-bounds for small rooms like Starry Shrine → crash during map rendering.

**Fix:** When redirecting an exit to a non-GreatTree room, use DEST_SPAWN_DEFAULTS — the destination room's own entry screen/X/Y values. These are proven valid because the vanilla game uses them.

**Exit data format (7 bytes per entry):**
```
[trigger_X] [trigger_Y] [map_type] [gate_flag] [screen] [spawn_X] [spawn_Y]
```
The flat addresses in EXIT_TRANSITIONS point to byte 2 (map_type), not byte 0 (trigger_X).

### 270 Exit Transitions Discovered
Automated scanner (`dump_all_exits.py`) found every room-to-room transition in the game. Output includes ready-to-paste Python code for EXIT_TRANSITIONS and DEST_SPAWN_DEFAULTS.

### Verified Room Labels (MAP_TYPE_NAMES)
All boss rooms verified against boss table byte 4:
- 0x3A=Boss:Wisdom(SkyDragon), 0x3B=Boss:Joy(FunkyBird), 0x3C=Boss:Anger(BattleRex)
- 0x3D=Boss:Arena Left(Digster), 0x3E=Boss:Happiness(Jamirus), 0x3F=Boss:Temptation(Servant)
- 0x41=Boss:Medal(Lipsy), 0x43=Boss:Judgment(Akubar), 0x44=Boss:Library(Orochi)
- 0x45=Boss:Reflection(Durran), plus all others verified correct

New rooms identified:
- 0x13=Library Gate Room, 0x19=Goopy Room 1 (GreatTree scr8), 0x1A=Goopy Room 2
- 0x2F=Intro Bedroom (2-screen, crashes on redirect)
- 0x50=Gate Floor:Item Shop, 0x51=Gate Floor:Priest, 0x52=Gate Floor:Coliseum
- 0x5A/5B/5C=Gate Floor treasure rooms, 0x5E=Arena Setup Room
- 0x0B, 0x0E, 0x11, 0x14, 0x15, 0x17, 0x1B, 0x1C, 0x35, 0x40, 0x4E, 0x60-64 = sub-rooms/maze variants (partially characterized)

### Active Redirections Display
Shows all entry + exit edits at top of Routing tab with inline Screen/X/Y editing, Update and Revert buttons.

---

## COMPLETED: SameBoy Debugging Guide

### Teleport Method (Verified Working)
```
breakpoint $0B:$45AB
; walk through any door
; breakpoint fires, A register = destination map_type
print a = $NN          ; override destination (hex with $)
continue
```

### Memory Write Syntax
SameBoy has NO `write` command. Use `print` with assignment operator:
```
print [$C96D] = $09    ; write 0x09 to RAM address $C96D
print a = $09          ; write to A register
```

### Key Addresses
- `$C968` = current map_type
- `$C969` = in_gate flag
- `$C96D` = destination map_type (written by $45AB)
- `$C96E` = gate flag
- `$C96F-$C972` = spawn position (processed by $45AB-$4606)
- `$D9XX` = per-room step state variables
- `$FFD5` = player column, `$FFD6` = player row

### Rooms That Crash on SameBoy Teleport
0x2F (Intro Bedroom), 0x13/0x19/0x1A (need routing editor redirect instead)

---

## COMPLETED: NPC Text Matching (Partial)

### Correct Matches (dialogue content verified)
| Room | Text Bank | Table Offset | Sample Dialogue |
|---|---|---|---|
| Bazaar | 3F | $4487 | "Oh my! So this is the GoldSlime!" |
| Farm | 3F | $44FD | "How're you doing?... Let's go home!" |
| Stable | 22 | $4023 | "Which class are you registering for?" |
| Arena Lobby | 21 | $403D | "So you became the master of GreatTree" |
| Arena Rooms | 22 | $410B | "How many monsters have you had?" |
| Well | 21 | $40DF | "Let me introduce him to you" (Durran) |
| Starry Shrine | 18 | $5667 | "A well won victory! I'm so happy!" |

### Wrong Matches (coincidental index overlap)
- Castle → matched item name table (AwakeSand, WorldLeaf)
- GreatTree → matched monster name table (ChopClown, Grendal)
- Gate rooms / boss rooms → matched generic "BadMeat is bad" table (bank 1B @ 4025)

Script_id is room-specific — the game dispatches to different text banks per room. Correct matching requires either SameBoy tracing or known dialogue content.

---

## PENDING / NEXT STEPS

### Immediate: Update Editor with Full Exit Data
The `dump_all_exits.py` output contains ready-to-paste Python code for:
1. **EXIT_TRANSITIONS** — expand from 22 to ~100+ unique exits (dedup game-state variants)
2. **DEST_SPAWN_DEFAULTS** — 48 destination rooms with proven screen/X/Y values
3. **ENTRY_TRANSITIONS** — GreatTree's exits ARE entries to other rooms; Gate Hub's exits ARE entries to gate rooms. Fill in missing entries.

### Immediate: Test NPC Editor
The NPC editor tab needs user testing:
- Verify variant grouping shows correct NPC counts per game state
- Test sprite swapping (change byte 1)
- Test movement type changes (change type byte high nibble, e.g., 0x00→0x10 for walk)
- Verify naming persists across editor restarts

### Future: Custom Doors
Exit data format fully decoded (7 bytes). Adding a new door requires:
1. Write 7-byte exit entry to free ROM space in Bank 0B
2. Update room's step block exit_ptr to point to new data
3. Optionally add visual door tile to room graphics

Main challenge: finding free ROM space in Bank 0B.

### Future: Castle Step Identification
Castle (0x00) has steps 0x01-0x07. Check `examine $D92A` at different save points to map which step = which story beat.

### Future: Boss Room Pre/Post-Defeat Variants
Enter Gate of Beginning naturally, defeat Healer, re-enter boss room. If gate replaces boss, step variants confirmed for all 28 boss rooms.

### Future: NPC Text Editing
For correctly matched rooms (Bazaar, Farm, Stable, Arena, Well, Shrine), NPC script_id directly indexes the text pointer table. Text can be edited in the existing Text tab. For other rooms, need SameBoy tracing to find correct text banks.

---

## Technical Reference

### $45AB Code Flow (Entry/Exit Data Processing)
```
$45AB: LD [$C96D], A        ; write dest map_type (byte 0)
$45AE: LD A, [HLI]          ; read gate flag (byte 1)
$45AF: LD [$C96E], A        ; write gate flag
$45B2: LD DE, $2DE7          ; load lookup table address
$45B5: LD A, [HLI]          ; read screen byte (byte 2)
$45B6: PUSH AF               ; save screen byte for later
$45B7-$45BF: index into table: DE = $2DE7 + (screen & 0x0F) * 2
$45C0-$45DB: process X spawn: table[offset] + byte3, SWAP, split nibbles, +8, write $C96F/$C970
$45DE-$45F3: process Y spawn: table[offset+1] + byte4, SWAP, split nibbles, +8
$45F4: POP AF                ; recover screen byte
$45F5: BIT A, 7              ; test bit 7
$45F7: JR Z, $4601           ; if clear, skip
$45F9-$4600: add extra $08 to Y position (multi-screen offset)
$4601-$4606: write Y position to $C971/$C972
$4609+: room transition logic (set flags, validate, copy $C96D→$C968)
$4627: CALL $2652             ; check if current room < $30 (returns Z for normal rooms)
$462A: JR Z, $465B            ; normal rooms jump to $465B
$465B-$4669: setup calls, then fall through to room loading
$4674+: check current map_type against special rooms (mazes, arenas)
```

### Room Data Structure
Map pointer table at Bank 0B, $4B43 → screen blocks (pointer pairs) → step blocks (2-byte RAM ptr + 6-byte step entries) → interaction blocks (mixed 5-byte entries) + exit blocks (7-byte entries)

### Gate Names and Boss Table
Both verified correct. Boss table at $14:$4897, floor array at $16:$70A6. Gate name tool and boss dump tool outputs match in-game behavior.
