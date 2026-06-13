> **ARCHIVED:** Superseded by NEXT_CLAUDE_MESSAGE.md. Priorities 1 & 4 completed in Session 2.

> **NOTE:** The files described here are EDITOR PATCHES, not repo changes. The repo always builds to the original MD5. The editor applies these patches at build time.

# Session Handoff — Cross-Bank Room POC (June 2026)

## What This Session Accomplished

### Cross-Bank Room System: PROVEN WORKING

Custom rooms can now live in any free ROM bank ($60+) instead of the full bank $0B. This was the single biggest architectural blocker for the custom game editor.

**Tested and verified:**
- Single-screen room (MedalMan clone, mapID $6B)
- Multi-screen room (3-screen Castle clone, mapID $6C) with screen scrolling
- Correct tileset graphics, palette, tile collision, NPC display
- Entry/exit transitions between GreatTree, custom rooms, and between custom rooms
- No corruption of existing game rooms

### Implementation: Intercept + Redirect Pattern

Small patches in banks $00, $01, $0B, $17 detect custom mapIDs (≥ $6B) and redirect data reads to bank $60 via:
- `rst $10` calls (for functions returning DE/HL — bank $0B reader functions)
- `call ROM0Helper` same-size replacements (for functions needing A — all other banks)

**11 patch sites total across 4 banks. See CROSSBANK_ROOMS.md for complete list.**

### Files Modified
| File | Changes | Bytes Changed |
|------|---------|---------------|
| bank_060.asm | NEW: custom room overflow bank | N/A (new) |
| bank_000.asm | 2 ROM0 helpers + 1 collision patch | 20 bytes |
| bank_001.asm | 4 same-size call replacements | 12 bytes |
| bank_00b.asm | 6 intercept patches (code section) + 1 exit redirect (data) | ~100 code + 3 data |
| bank_017.asm | 2 same-size call replacements | 6 bytes |
| wram.asm | 3 new WRAM definitions | N/A (EQU only) |
| game.asm | bank $60 include changed | 1 line |

### Key Architecture Decisions

1. **Same-size replacements over byte insertion** — Banks $01 and $17 have raw embedded pointers in data sections. Inserting bytes breaks them. Same-size `call` replacements change exactly 3 bytes per site.

2. **ROM0 helpers over rst $10 for A-returns** — rst $10 clobbers A via `pop af`. ROM0 helpers preserve A.

3. **Per-room source mapID** — Different custom rooms can reuse different existing rooms' tilesets. Computed in ROM0 via conditional logic.

4. **$FFFF screen guard** — CustomPtrChase detects $FFFF sub-table entries and returns a safe DummyStepEntry with valid tileset data.

5. **WRAM copy buffers** — NPC and exit data copied from bank $60 to WRAM ($D378-$D477) so bank $0B code can read it after rst $10 returns and bank is restored.

---

## What Still Needs Work

### Priority 1: NPC Scripts for Custom Rooms
Custom room NPCs with script_id ≠ $FF crash because bank $0F's master table has no entries for mapID ≥ $6B. Options:
- Extend bank $0F's master table with entries for custom mapIDs
- Add intercept in bank $04's MapTypeDispatch to route custom mapIDs to bank $60's script data
- Use gen_script_banks.py to add script entries

### Priority 2: Custom Tilesets
Currently custom rooms must reuse an existing room's tileset. For truly new room visuals:
- Add entries to the $26DD tileset table in bank $00
- Create new compressed tile layouts in a tileset bank
- Create corresponding palette/attribute data in bank $17's AttrPtrTable

### Priority 3: MapIDClampForPalette Scaling
Current implementation uses hardcoded conditionals for 2 rooms. For many rooms:
- Option A: ROM0 lookup table (limited by ROM0 free space — only 1 byte left)
- Option B: Move to bank $60 with WRAM caching, but ensure WRAM is set before Entry 0 runs
- Option C: Expand ROM0 free space by finding more padding bytes

### Priority 4: Text/Dialogue
The text ID system has a hard 16-bit limit. Need to survey how many IDs are used vs available before adding NPC dialogue.

### Priority 5: Step Progression
CustomPtrChase always uses step 0. For rooms that change based on game progress, need step counter management in the custom room data.

---

## Build Instructions

```bash
cd disassembly
export PATH="$HOME/.local/bin:$PATH"  # if RGBDS installed locally
make
# Output: game.gbc
# Original MD5: b90957482011c8083a068781033715b7
```

**NEVER run `make clean` or `git stash`** — these can destroy work.

---

## Critical Documentation

Read these in order:
1. **KEY_LESSONS.md** — Every bug encountered and why. Read BEFORE touching any code.
2. **CROSSBANK_ROOMS.md** — Complete implementation reference with data flow diagrams.
3. **ROOM_DATA_FORMAT.md** — Original room data structure (bank $0B).
4. **DATA_STRUCTURES.md** — All game data tables and their formats.
