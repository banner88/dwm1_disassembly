# Handoff Summary — Hand This To The Next LLM

Save this as `HANDOFF.md` in the repo root.

---

## DWM1 Romhack — Project Handoff (v2)

### Goal
Full romhack of **Dragon Warrior Monsters 1** (Game Boy Color): new storyline / dialogue, modified monster stats and balance, custom starter monster, modified encounter pools per gate, eventually add DWM2 monsters, modify breeding table, new tilemaps and rooms.

### Architecture (Critical to Understand)

```
data/DWM-original.gbc   ────┐
                            ├──[ tools/build_rom.py ]──> data/DWM-hacked.gbc
extracted/edits.json    ────┘                              │
                                                            │
                            ┌─[ PyBoy / SameBoy ]──── boot test
                            ▼
                       verification
```

- **`extracted/edits.json`** is the source of truth for all modifications
- Build pipeline reads original + edits, never mutates original
- Build fixes GBC header + global checksums automatically
- Edits are a JSON overlay with three sections:
  ```json
  {
    "monster_stats": { "8": { "level_cap": 99, "base_skills": [82, 9, 11] } },
    "text":          { "42:4142": "..." | {"text": "...", "ptr_location": "...", "allow_repoint": true} },
    "raw_bytes":     { "0xFLAT_OFFSET": "DE AD BE EF" }
  }
  ```

### File Structure
```
dwm-toolkit/
├── data/
│   ├── DWM-original.gbc       READ-ONLY reference
│   └── DWM-hacked.gbc         build output
├── dwm/
│   ├── __init__.py
│   ├── rom.py                 ROM class, bank addressing helpers
│   ├── text.py                Codec (encode/decode, TABLE, control codes)
│   └── build.py               Edit pipeline + checksum fixers
├── tools/
│   ├── __init__.py
│   ├── scan_text.py           Find all strings in ROM (v3)
│   ├── find_pointer_tables.py Find pointer tables
│   ├── dump_all_text.py       Organize text by table + orphans
│   ├── search_text.py         Substring search in decoded text
│   ├── search_bytes.py        Exact byte pattern search
│   ├── dump_bank.py           List strings in one bank
│   ├── view_string.py         Decode bytes around an offset
│   ├── dump_monsters.py       Dump 221 monster stat blocks
│   ├── dump_monster_names.py  Dump monster name table
│   ├── dump_encounters.py     Dump all gate encounter pools with monster names ← NEW
│   ├── find_free_space.py     Find unused ROM regions
│   ├── find_orphan_pointers.py LD HL/DE/BC pattern scan
│   ├── randomize.py           Generate randomized edits
│   ├── build_rom.py           Apply edits + boot verify
│   └── verify_edit.py         Sanity check edits in built ROM
├── extracted/                 (all generated; gitignore OK)
│   ├── monsters.json          221 monster stats
│   ├── monster_names.json     256 monster names
│   ├── text_blobs.json        4071 strings
│   ├── pointer_tables.json    117 tables
│   ├── all_text.json          organized text
│   ├── free_space.json        ~676KB free regions
│   ├── orphan_pointers.json   254 confident inline pointers
│   ├── encounters.json        Gate encounter pools with monster names ← NEW
│   └── edits.json             edit overlay (USER FACING)
├── gui/
│   └── editor.py              Streamlit editor
├── tests/
│   └── test_roundtrip.py      Codec sanity tests
└── DISCOVERIES.md             All verified RAM/ROM addresses from debugging ← NEW
```

### GBC Memory Map (Beginner Reference)

```
$0000–$3FFF  →  ROM Bank 0 (always mapped, game code)
$4000–$7FFF  →  ROM Bank N (switchable, most game data)
$8000–$9FFF  →  Video RAM (tile graphics)
$A000–$BFFF  →  Cartridge RAM (save data)
$C000–$CFFF  →  Work RAM Bank 0 (always mapped)
$D000–$DFFF  →  Work RAM Bank 1-7 (switchable)
$E000–$FFFF  →  Special registers, stack, etc.
```

Hex is base-16 counting: digits 0-9 then A=10, B=11, C=12, D=13, E=14, F=15. So $C000 comes before $D000 which comes before $DFFF.

**Flat ROM offset** from bank:address: `flat = bank × 0x4000 + (address − 0x4000)` for banks ≥ 1. Bank 0: `flat = address`.

### Text Codec (CRITICAL — read first)

`dwm/text.py` has:
- `TABLE` — single-byte → glyph (digits, A-Z, a-z, punctuation, contractions like `'l`, `'t`, `'s`)
- `encode(text) -> bytes` — turn human text into ROM bytes (always adds 0xF0 terminator)
- `decode(bytes) -> (text, n)` — reverse; unknown bytes shown as `{XX}` escapes
- The escape syntax `{XX}` in input/output represents any byte by hex

### Known Control Codes
| Code | Meaning |
|------|---------|
| `0xF0` | String terminator (end of dialogue) |
| `0xF6` | Player name substitution at runtime |
| `0xB6` | "and" glyph (1-byte ligature) |
| `0xA3` | Speaker name separator (e.g. `Pulio{A3}`, `Milayou{A3}`) |
| `0xEE` | Line break |
| `0xEF` | Wait for button + advance |
| `0xFA` `0xF7` | Page break (almost always together) |
| `0xEB` | Textbox open: "left character speaks" |
| `0xEA` | Textbox open: "right character speaks" |
| `0xEC` `0xED` | Other textbox variants (less common) |
| `0xF1` | In-line line break (item descriptions) |
| `0x9F` | Cursor/margin positioning |

---

## VERIFIED ROM DATA (Debugger-Confirmed)

### Starter Monster

The starter monster uses **enemy_stats_id 1** from the enemy stats table at `$14:$4C1D`. The game loads this during intro initialization (before the Pulio dialogue), copies it to the `$DA18` work buffer via the `$14:$4849` "Load Enemy stats" function, then copies it to the party slot at `$CACA`.

**Enemy Stats Entry Format (25 bytes):**
```
Offset  Size  Field
0       1     Monster species ID
1       1     Unknown
2       1     Unknown
3       1     Unknown
4       1     Level
5-6     2     HP (little-endian)
7-8     2     MP (LE)
9-10    2     ATK (LE)
11-12   2     DEF (LE)
13-14   2     AGL (LE)
15-16   2     INT (LE)
17      1     Unknown (personality?)
18      1     Unknown
19      1     Unknown
20      1     Unknown
21      1     Skill 1 (FF = none)
22      1     Skill 2
23      1     Skill 3
24      1     FF delimiter
```

**Starter monster ROM offsets (flat):**
| Offset | Field | Default | Example Edit |
|--------|-------|---------|-------------|
| 0x50C36 | Species ID | $08 (Slime) | `"2C"` → Divinegon |
| 0x50C3A | Level | $01 | `"05"` → Level 5 |
| 0x50C3B | HP (2 bytes) | `1E 00` (30) | `"E8 03"` → 1000 |
| 0x50C3F | ATK (2 bytes) | `0A 00` (10) | `"09 03"` → 777 |
| 0x50C41 | DEF (2 bytes) | `06 00` (6) | |
| 0x50C43 | AGL (2 bytes) | `05 00` (5) | |
| 0x50C45 | INT (2 bytes) | `01 00` (1) | |

**Example edits.json for a level 1 Divinegon with 777 ATK:**
```json
{
  "raw_bytes": {
    "0x50C36": "2C",
    "0x50C3F": "09 03"
  }
}
```

### Encounter System

**Verified by changing Gate of Beginning encounters — Gremlins appeared where Slimes used to be.**

#### Index Chain: Gate → Floor → Monster Pool

1. **Gate offset array** at `$01:$6A22` (32 bytes, flat `0x6A22`)
   - `pool_base = array[gate_id]`

2. **Floor threshold pointers** at `$01:$6A42` (32 × 2-byte LE pointers, flat `0x6A42`)
   - Each gate points to a threshold array terminated by $FF
   - Thresholds split floors into groups (e.g., `03 06 FF` = floors 1-3, 4-6, 7+)

3. **Encounter pool blocks** at `$01:$6AAE` (32 × 26 bytes, flat `0x6AAE`)
   - Pool index = `pool_base + floor_group_index`
   - Block address = `$6AAE + pool_index × 26`

#### 26-Byte Encounter Block Format

```
Offset  Size  Field
0       1     Encounter rate parameter (→ $C8A9)
1       1     Floor difficulty level
2-9     8     Secondary encounter data (not fully decoded)
10-11   2     Monster slot 1: enemy_stats_id (little-endian)
12-13   2     Monster slot 2: enemy_stats_id (LE)
14-15   2     Monster slot 3: enemy_stats_id (LE)
16-17   2     Monster slot 4: enemy_stats_id (LE, 0x0000 = empty)
18-19   2     Padding
20      1     Probability weight for slot 1
21      1     Probability weight for slot 2
22      1     Probability weight for slot 3
23      1     Probability weight for slot 4 (0 = empty)
24-25   2     Footer (always $00 $08)
```

**To change encounters:** Modify the enemy_stats_id at offsets 10/12/14/16 within the block.
- Block 0 flat offset: `0x6AAE`
- Block 0, monster slot 1: `0x6AAE + 10 = 0x6AB8`
- Block N, monster slot M: `0x6AAE + N*26 + 10 + M*2`

#### Enemy Stats ID → Species Mapping (First 8 verified)

| EID | Species ID | Monster Name |
|-----|-----------|-------------|
| 0 | $00 | DrakSlime |
| 1 | $08 | Slime (starter) |
| 2 | $08 | Slime (wild, different stats) |
| 3 | $35 | Anteater |
| 4 | $4E | Dracky |
| 5 | $62 | Stubsuck |
| 6 | $77 | GoHopper |
| 7 | $8B | Gremlin |

Full mapping: run `uv run python -m tools.dump_encounters` to generate `extracted/encounters.json`.

### Party Data (RAM)

Each party monster record is **149 bytes ($95)**. Starts at `$CAC0`.

| RAM Address | Field |
|-------------|-------|
| $CA8D | Party size (number of monsters, 0-3 active) |
| $CA8E | First party slot index |
| $CAC0 | Monster 1 record start |
| $CAC2 | Monster 1 nickname (8 bytes, $F0 padded) |
| $CACA | Monster 1 species ID |
| $CB0C | Monster 1 level |
| $CB0E | Monster 1 experience (3 bytes) |
| $CB10 | Monster 1 HP (2 bytes) |
| $CB18 | Monster 1 ATK (2 bytes) |
| $CB1A | Monster 1 DEF (2 bytes) |
| $CB1C | Monster 1 AGL (2 bytes) |
| $CB55 | Monster 2 record start ($CAC0 + $95) |
| $CBEA | Monster 3 record start ($CB55 + $95) |
| $CA4B | Gold (3 bytes) |
| $CA51 | Items (20 bytes) |

### Battle Work Buffers (RAM)

| Address | Field |
|---------|-------|
| $DA03 | Battle enemy 1 stats ID |
| $DA05 | Battle enemy 2 stats ID |
| $DA07 | Battle enemy 3 stats ID |
| $DA12–$DA13 | Current enemy_stats_id being loaded (2 bytes) |
| $DA18 | Enemy stats work buffer (25 bytes) |
| $DBAB–$DBAF | Enemy 1/2/3 current HP (2 bytes each) |
| $DBBB–$DBBF | Enemy 1/2/3 max HP (2 bytes each) |

### Game State (RAM)

| Address | Field |
|---------|-------|
| $C899–$C89A | PRNG state |
| $C8A9 | Floor encounter rate parameter |
| $C8B5 | BGM offset (see wiki for values) |
| $C925 | Current room/loading parameter |
| $C935 | Current gate |
| $C939 | Current floor |
| $C968 | Map type |
| $C969 | In-gate flag (0=no, 1=yes) |
| $C96D | Gate to warp to |
| $CA38 | Encounter pool index for current gate+floor |
| $CA39–$CA3A | Counter until next random encounter |

---

## ROM Map Summary

### Banks & Key Tables
| Flat Offset | Bank:Addr | Contents |
|-------------|-----------|----------|
| 0x0D461 | `03:4461` | Monster info table (221 × 43 bytes) |
| 0x4D1E6 | `13:41E6` | Experience table (32 curves × 99 levels × 3 bytes) |
| 0x50C1D | `14:4C1D` | Enemy stats array (25 bytes each) |
| 0x58874 | `16:4874` | Unevolved skill map (256 bytes) |
| 0x58B30 | `16:4B30` | Breeding table (format not decoded) |
| 0x5B0A6 | `16:70A6` | Gate boss floor array (32 × 8 bytes) |
| 0x06A22 | `01:6A22` | Gate → pool index mapping (32 bytes) |
| 0x06A42 | `01:6A42` | Floor threshold pointers (32 × 2-byte ptrs) |
| 0x06AAE | `01:6AAE` | Encounter pool data (32 × 26 bytes) |
| 0x06AB8 | `01:6AB8` | First encounter pool, first monster slot |
| 0x104339 | `41:4339` | Monster names pointer table (256 entries) |
| 0x1041BF | `41:41BF` | Gate names pointer table (16 entries) |
| 0x1044FB | `41:44FB` | Skill names pointer table (253 entries) |
| 0x1048E9 | `41:48E9` | Item names pointer table (43 entries) |
| 0x104997 | `41:4997` | Personality names pointer table (27 entries) |
| 0x2C274 | `B:4274` | Room loading function |
| 0x2CB43 | `B:4B43` | Map type → pointer table (~110 entries) |

### Key Functions
| Flat | Bank:Addr | Purpose |
|------|-----------|---------|
| 0x07AB | `00:07AB` | HandleTextCharacter |
| 0x0D78 | `00:0D78` | ReadNextTextByte (may not fire for all text types) |
| 0x12D0 | `00:12D0` | PRNG: wC899 × 5 + $1357 |
| 0x1DBE | `00:1DBE` | Mul8x8To16: HL = A × C |
| 0x1DE6 | `00:1DE6` | Mul16x8To24: E:HL = BC × A |
| 0x1E0D | `00:1E0D` | Div16x8To16: HL = HL // A; A = HL % A |
| 0x06891 | `01:6891` | Encounter monster selection |
| 0x06989 | `01:6989` | Weighted random pool picker |
| 0x069E1 | `01:69E1` | Load next dungeon floor |
| 0x50130 | `14:4130` | Copy monster data into party slot |
| 0x50849 | `14:4849` | Load Enemy stats from ROM table |
| 0x5AE14 | `16:6E14` | Set counter before next encounter |
| 0x5AF5F | `16:6F5F` | Determine if encounter triggers |
| 0x5AB76 | `16:5B76` | Load floor data for current gate |
| 0x5ABE1 | `16:5BE1` | Load gate boss floor |

### Monster Info Block Format (43 bytes at `03:4461 + id*43`)
```
00: family (0=Slime, 1=Dragon, 2=Beast, 3=Flying, 4=Plant, 5=Bug, 6=Devil, 7=Zombie, 8=Material, 9=Boss)
01: base level cap
02: exp_table index (0-31)
03: female pct (0=0%, 1=10%, 2=50%, 3=84%)
04-05: unknown
06-08: base skills (3 × 1 byte = 3 skill IDs)
09-0E: unknown
0F-29: resistances (27 bytes)
2A:    unknown
```

### Gate Boss Floor Array (at `$16:$70A6`, 32 × 8 bytes)
```
aa bb cc dd ee ff gg hh
aa-dd: floor parameters (encounter rate ranges, floor type indices)
ee:    boss room map_type (e.g., $30 = Boss Room Gate of Beginning)
ff-hh: boss room position/parameters
```

---

## Build Pipeline Behavior
- `MAX_STRING_LEN = 1024` (keep at 1024 or higher)
- In-place text edit: writes new bytes, pads trailing slack with `0xF0`
- Repointed text edit: allocates from `free_space.json` in same bank, patches pointer
- Checksum fixers MUST run after all edits
- Edits that can't fit + can't repoint are REJECTED with warning
- **Revert:** Delete the key from edits.json — build always starts from original ROM

### What Works End-to-End
- ✅ Monster stat editing (level cap, skills, resistances, family)
- ✅ Tabled text editing (NPC dialogue, item names, skill names, monster names)
- ✅ Confident-orphan text editing (254 strings)
- ✅ Build pipeline → boot verify (PyBoy headless)
- ✅ Streamlit GUI with natural-mode text editor
- ✅ Randomizer: light / medium / chaos modes with seed
- ✅ **Starter monster editing** (species, level, all stats via raw_bytes at 0x50C36) ← NEW
- ✅ **Encounter pool editing** (per-gate, per-floor monster swaps via raw_bytes) ← NEW
- ✅ **Encounter pool dumper** (tools/dump_encounters.py → extracted/encounters.json) ← NEW

### What's Partially Done
- ⚠️ Encounter pool format: monster IDs and weights decoded at offsets 10-23; bytes 2-9 (secondary pool data) not fully decoded
- ⚠️ Gate boss monsters: boss floor array location known ($16:$70A6), but boss enemy_stats_ids not yet extracted — requires watchpoint on $DA03 during a boss fight

### What Has Not Been Done
- ❌ Gate boss encounter editing (next priority — use watchpoint method)
- ❌ Breeding table format (location known at `16:4B30`, format not decoded)
- ❌ Encounter pool secondary data (bytes 2-9 of each 26-byte block)
- ❌ Full GUI for encounter/starter editing (architecture designed, not implemented)
- ❌ Map data format (tilemaps, room layouts)
- ❌ NPC placement tables
- ❌ Tile graphics
- ❌ Scripting engine opcodes
- ❌ DWM2 monster import

### Recommended Next Steps (Easy → Hard)
1. **Gate boss editing** (30 min debugger work). Enter boss room, `watch/w $DA03`, fight boss, backtrace to find enemy_stats_id source. Same method used for encounter pools.
2. **Full encounter editor GUI** (2-3 hours). Streamlit tabs: encounter editor (gate dropdown → monster dropdowns), starter editor (species + stats), revert buttons. Architecture in DISCOVERIES.md.
3. **Breeding table editor** (1-2 days). Parse `16:4B30` by inspection + comparison to known breeding combos.
4. **Experience curves editor** (½ day). `13:41E6`, 32×297 bytes, big-endian 24-bit integers per level.
5. **Encounter pool secondary data** (1-2 hours debugger). Decode bytes 2-9 of the 26-byte blocks — likely controls number of enemies, formation type, etc.
6. **Map/tile editing** (debugger required, multi-day). SameBoy watchpoints on VRAM during room transitions.

### SameBoy Debugger Quick Reference (VERIFIED WORKING)
```bash
# The command is "interrupt" not "pause"
interrupt                     # pause game
continue                      # resume (c also works)

# Inspect
registers                     # all CPU registers
examine/N ADDR                # N bytes at address (e.g., examine/25 $14:$4C36)
print EXPR                    # evaluate expression
disassemble/N ADDR            # N instructions from address

# Watch/break
watch/w ADDR                  # break on write to single address
watch/w ADDR to ADDR2 inclusive  # range watch (WARNING: if conditions broken on ranges)
watch/w ADDR if COND          # conditional (works on single address only)
unwatch                       # clear all watchpoints
breakpoint BANK:ADDR          # break on execution
delete                        # clear all breakpoints

# Navigate
step                          # one instruction (into calls)
next                          # one instruction (over calls)
backstep                      # rewind one instruction (alias: bs)
bt                            # backtrace / call stack

# Modify memory (for testing)
[ADDR] = VALUE                # write to RAM (e.g., [$CA8D] = 3)
```

**Key pitfalls discovered:**
1. `pause` is not a command — use `interrupt`
2. `backtrace` may fail — use `bt` alias
3. Conditional watchpoints on RANGES don't work (conditions are ignored). Use single-address watchpoints with conditions, or range watchpoints without conditions.
4. Stack writes ($DFF0+) fire constantly on range watchpoints — exclude that area or watch specific addresses.
5. $0D78 (ReadNextTextByte) breakpoint didn't fire for NPC dialogue — the text rendering path may differ from what the wiki documents.

### Workflow For Finding Unknown Data (The Method We Used)

This is the core loop — every unknown becomes known through this process:

1. **Hypothesis**: "The game must store X somewhere in RAM ($C000-$DFFF)"
2. **Trigger**: Find the gameplay moment where X changes (e.g., receiving a monster)
3. **Watch**: Set `watch/w` on likely RAM regions, or do before/after memory dumps
4. **Identify**: Find the RAM address where the value changed
5. **Trace**: Set `watch/w` on that specific address, trigger the event again
6. **Backtrace**: When it fires, use `registers`, `bt`, `disassemble` to find the ROM instruction
7. **Calculate**: Convert bank:address to flat ROM offset
8. **Edit**: Add to `raw_bytes` in edits.json
9. **Verify**: Build and test

### One-Sentence Summary For Context Window
> "We built a JSON-overlay-based romhacking pipeline for Dragon Warrior Monsters 1 GBC with verified debugger-confirmed editing of starter monster (species + stats at 0x50C36), encounter pools per gate/floor (26-byte blocks at 0x6AAE), and full party data mapping. 4071 strings catalogued, 117 pointer tables, encounter dumper tool, Streamlit GUI. Next: gate boss editing, then full encounter editor GUI."

---
