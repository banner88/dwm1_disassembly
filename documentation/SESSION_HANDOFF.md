# DWM1 ROM Hack — Session Handoff

## Build Verification
```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: b90957482011c8083a068781033715b7
```
**Note:** MD5 changed from original (`1ca6579359f21d8e27b446f865bf6b83`) due to
Bank $0B SharedPtrChase refactoring. Data section byte-identical to original ROM.

**NEVER run `make clean`** — deletes committed `.2bpp` graphics files.

## What Was Completed This Session

### 1. Complete Event Flag Map ✅
- **1,164 flag operations**, **311 unique flags** across 530 scripts
- **463 free flag slots** (primary: $0158-$02C0, 361 contiguous)
- Tool: `tools/analyze_event_flags.py`, export: `extracted/event_flags_complete.json`

### 2. Quest-Driving Opcodes Decoded ✅
- **$1F → ArenaBattleSetup**: 0 params, engine-only, arena enemy team calc
- **$2C → CheckInvFull**: 1 param (branch addr), 45 uses, inventory full check
- **$2D → MonsterSlotDialogue**: 1 param (slot 0-2), 3 uses, species-family dialogue
- Documentation: `QUEST_OPCODES.md`

### 3. Bank $0B Expansion Plan + Refactoring ✅
- **4 identical 44-byte pointer-chase functions** → 1 shared `SharedPtrChase`
- Bank split into Code ($4000) and Data ($4B43) sections
- **119 bytes freed** at $4ACC-$4B42
- 24 empty overflow banks available ($60, $62, $64, $67-$77, $79-$7F)
- Documentation: `CROSSBANK_ROOMS.md`

### 4. Bank $17 Palette/Attribute System Parsed ✅
- Per-step entry: [attr_idx:1, attr_bank:1, pal_ptr:2]
- Bank $3C = primary attribute bank (239 unique maps)
- 89 unique palettes, 32 bytes each (4 BG palettes × 4 colors × 2B RGB555)
- Tool: `tools/analyze_bank17.py`

### 5. Bank $04 Monster Family Text Table Annotated ✅
- $60F4-$61DF: 236 bytes of misassembled instructions → proper `dw` data
- 10-entry family pointer table → 4 text ID sub-tables (27 entries each)

### 6. Decompiler Opcode Names Fixed ✅
- `large_event_handler` → `arena_battle_setup`
- `event_dispatch` → `check_inv_full, goto .addr_XXXX`
- `check_step` → `monster_slot_dialogue slot=N`

### 7. Script Compiler Tool Built ✅
- `tools/compile_script.py`: pseudo-code → `dw` assembly with RGBDS labels
- All 100 opcodes, trigger_anim packing, round-trip tested

### 8. Bank $00 Function Naming — 26 Functions ✅
Named 26 previously unnamed functions (175 total named, 440 remaining):
WaitVRAMAccess, ClearInterruptFlags, AudioProcess, Copy8BytesHL2DE,
HandleScreenRefresh, LoadGBCPalettes, DecompressTileLayout, etc.

## All Completed Work (All Sessions Combined)

### Fully Annotated Data Banks
| Bank | Contents | Labels | Status |
|------|----------|--------|--------|
| $03 | Monster info (221×43B) | ~250 | Done |
| $0B | Room data ($4B43-$7FFF) | ~800 | Done; code refactored (119B freed) |
| $0C-$0F | Script data (530 scripts) | 1,626 | Done, 0 unknowns |
| $13 | EXP/growth tables | ~100 | Done |
| $14 | Enemy stats (487×25B) | ~500 | Done |
| $16 | Breeding + gate + encounters | 234 | Done |
| $17 | Palette/attribute tables | ~210 | Attr entries decoded, palettes parsed |
| $41 | Name/text tables + strings | 933 | Done |
| $52 | Skill functions + battle | 912 | Done |
| 14 tileset banks | LZSS tile data | ~500 | Done |

### Named Functions: 219 in Bank $00 (70 new this session)
### WRAM Symbols: 81 unique, 4,676 replacements

### Tools
| Tool | Purpose |
|------|---------|
| `gen_script_banks.py` | Script data banks $0C-$0F (`--apply`) |
| `decompile_script.py` | Human-readable pseudo-code (`--map`) |
| `compile_script.py` | Pseudo-code → dw assembly (`-o`) |
| `analyze_event_flags.py` | Flag usage report + JSON (`--json`) |
| `analyze_bank17.py` | Palette/attribute data (`--room`) |
| `gen_monster_db.py` | Bank $03 monster info |
| `gen_room_data_db.py` | Bank $0B room data (`--apply`) |
| + 8 more generators | See DATA_STRUCTURES.md |

## NOT Done — Priority for Next Session

### 1. Bank $0B overflow hook (HIGH — enables custom rooms)
SharedPtrChase refactoring is DONE. 119 bytes free at $4ACC-$4B42 in bank_00b.asm.
**Full implementation plan in `CROSSBANK_ROOMS.md`.**

Steps:
- Add WRAM flag check at top of SharedPtrChase: if `[wRoomOverrideActive]` set, read from WRAM buffer instead of ROM
- Write ROM0 trampoline (~40 bytes at $3FE8 or $3A83, see `tools/find_bank0_space.py`)
- Hook RoomEntry0_TilesetLoader to copy room data from overflow bank to WRAM on room transition
- Create test room data in Bank $60 (completely empty, 16KB available)
- 24 empty banks total: $60, $62, $64, $67-$77, $79-$7A, $7C, $7E-$7F
- Test in SameBoy: verify player can enter a custom room loaded from overflow bank

### 2. Bank $04 remaining data tables (MEDIUM — disassembly)
- **$5E22-$5E5D**: Arena battle team name data (60 bytes), still misassembled as instructions. Same fix as $60F4: convert to labeled `dw` entries. Format: 10 groups × 3 battles × 2 bytes.
- **Opcode dispatch table**: The 100-entry jump table routing $FF00-$FF63 to handlers. Find it and label each entry with the opcode name from BANK04_SCRIPT_ENGINE.md.
- **833 auto-labels** in script VM code — many are data tables misassembled as code.

### 3. Bank $17 generator tool (MEDIUM — completes palette annotation)
Build `gen_bank17_db.py` like `gen_room_data_db.py --apply`. Use the format decoded by `tools/analyze_bank17.py`:
- Per-step entry: `[attr_idx:1, attr_bank:1, pal_ptr:2]`
- Bank $3C = primary attribute bank (239 unique attr maps)
- 89 unique palette blocks at $565D-$7F61, each 32 bytes RGB555
- Gate attr tables at $5215/$5415 still raw hex — parse separately

### 4. Bank $00 function naming (MEDIUM — ongoing)
396 `Call_000_` labels remain. Three batches done this session (70 total).
Approach: `grep -c "^Call_000_" disassembly/bank_000.asm` to check count.
Focus on: game loop, map transition pipeline, NPC loading chain.
Pattern-match on WRAM addresses, rst $10 calls, hardware register access.

### 5. Lower priority
- GUI editor prototype — web-based script editor using decompiler/compiler
- NPC behavior values (lower nibble meanings), collision data
- Event state machine (Bank $50/$51) — for non-script-based events
- More WRAM symbol expansion (81 done, many more to decode)

## Key Documentation
| File | Covers |
|------|--------|
| `DATA_STRUCTURES.md` | Master data structure catalog |
| `SCRIPT_TOOLS.md` | Script generator, decompiler, compiler usage |
| `EVENT_FLAGS.md` | Complete flag map (311 flags, 463 free) |
| `QUEST_OPCODES.md` | $1F/$2C/$2D handler analysis |
| `CROSSBANK_ROOMS.md` | Room expansion architecture |
| `CUSTOM_CUTSCENES.md` | Custom cutscene creation guide |
| `BANK04_SCRIPT_ENGINE.md` | Script VM: 100 opcodes |
| `ROOM_DATA_FORMAT.md` | Room data format reference |

## IMPORTANT WARNINGS
- **NEVER `git stash`** on the disassembly directory — it reverts all .asm changes
- **NEVER `make clean`** — deletes .2bpp graphics files
- Build MD5 `b90957482011c8083a068781033715b7` reflects SharedPtrChase refactoring
