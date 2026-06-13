# DWM1 Disassembly — Handoff for Next Session

## READ FIRST
**The repo always builds to the original MD5: `b90957482011c8083a068781033715b7`.**
Custom content lives as **patch files** in `patches/`. Applied on top of clean repo at build time.

---

## Project State

**Dragon Warrior Monsters** (GBC, 1998) full ROM disassembly into buildable RGBDS assembly.
Goal: custom game editor for rooms, scripts, breeding, NPCs, events, and eventually custom stories.
Disassembly: ~45% labels named, all 2,404 functions labeled, banks $00/$04 fully named.
RGBDS v0.6.1 required. **NEVER `make clean`** (deletes .2bpp). **NEVER `git stash`**.

---

## What Works (All Proven In-Game, v23)

| System | Status | Key Details |
|--------|--------|-------------|
| Cross-bank custom rooms | ✅ | mapID ≥ $6B → bank $60. Multi-screen scrolling, exits. |
| NPC scripts | ✅ | MapTypeDispatch patched in bank $04. Script index 0 = room entry, NPCs at 1+. |
| Custom text/dialogue | ✅ | TextQueueCheck patched. IDs $0A00+. Two-level pointer table. `$EF $EE` for line breaks. `$F7 $F0` to end. |
| YES/NO choices | ✅ | Text ends with `$E7 $F0`. Script uses opcode `$15` to check `$C83C` (0=YES, 1=NO). |
| Item give | ✅ | Opcode `$2A` (GiveItem) via jump table wrapper. Scans first empty inventory slot. |
| Inventory full check | ✅ | Opcode `$2C` branches if all 20 slots used. |
| Event flags | ✅ | Opcodes `$00`/`$01`/`$03`. 463 free flags. |
| Room exits | ✅ | 7-byte format: trigX, trigY, mapID, flags, screen, destX, destY. |

**Patch files (8 total):** bank_000, bank_001, bank_004 (NEW Session 2), bank_00b, bank_017, bank_060, wram, game.asm

---

## Critical Rules

1. **NEVER insert bytes into banks $01, $04, or $17** — raw embedded pointers break. Use same-size replacements or wrappers in padding only.
2. **rst $10 entry index:** L = entry NUMBER not byte offset. Entry 4 = `$XX04`. rst $10 does `add hl,hl` internally.
3. **Script index 0 = room entry.** Runs on every room enter AND screen scroll. NPC scripts at index 1+.
4. **Text terminates with `$F7 $F0`**, NOT `$E7`. `$E7` = YES/NO CHOICE. `$EE` needs `$EF` before it.
5. **Text pointer table must be two-level.** SaveBankAndSwitch ($0940) indexes twice.
6. **When in doubt: `grep` the ROM** for how the original game does it. Don't theorize.
7. **Opcode $2A (GiveItem) needs wrapper.** Original `ret` breaks flow. Jump table redirects to wrapper that `call`s original then `jp ScriptExecContinue`.

---

## Documentation (Read Order)

| File | When |
|------|------|
| KEY_LESSONS.md | BEFORE touching any code — every hard-won bug from 2 sessions |
| DATA_STRUCTURES.md | Master reference — all tables, addresses, verified opcodes |
| BANK04_SCRIPT_ENGINE.md | Script VM architecture + complete opcode reference |
| TEXT_SYSTEM.md | Text control codes, format, YES/NO, custom routing |
| CROSSBANK_ROOMS.md | Room system implementation |
| SESSION2_CUSTOM_CONTENT.md | Supplementary: bank $56 jump table, BGM offsets |

**Archived:** SESSION1_ARCHIVE.md (superseded). **Delete from repo:** old SESSION_HANDOFF.md if still present.

---

## Likely Next Steps

### 1. Random Encounters in Custom Rooms
Deferred from Session 2. `wInGateworld` ($C969) gates encounters but also changes script dispatch ($D8D3→$70) and enables floor generator. Needs decoupled encounter patch or investigation of actual battle trigger mechanism.

### 2. Editor Architecture
All content primitives work. Editor generates bank_060.asm with room data, script data, text data. Needs: text auto-wrap (18 char lines), patch application, build integration.

### 3. Remaining Systems to Verify
- **Teleport/warp** — opcode $0E (SetMapTransition), untested
- **BGM change** — opcode $41, untested (BGM table in SESSION2_CUSTOM_CONTENT.md)
- **Monster give** — opcode $29 (AddMonster) labeled in BANK04, untested
- **NPC visibility** — flag-based show/hide, mechanism unknown
- **Custom tilesets** — needs LZ compressor tool (~50 lines Python)

---

## Complete Item Give Pattern (Verified)
```asm
dw $FF2C                ; check_inv_full
dw .invFull             ; branch if full
dw $FF2A                ; GiveItem (first empty slot)
dw ITEM_ID              ; item constant from items.inc
dw text_received        ; "Received X!"
dw $FFFF
.invFull:
dw text_full            ; "Inventory is full!"
dw $FFFF
```

## Complete YES/NO Pattern (Verified)
```asm
dw text_question        ; text ending with $E7 $F0
dw $FF15                ; CheckAndBranch
dw $C83C                ; choice result (0=YES, 1=NO)
dw $0001                ; compare to NO
dw .no_branch
dw text_yes             ; YES response
dw $FFFF
.no_branch:
dw text_no              ; NO response
dw $FFFF
```

## Build & Test
```bash
cd disassembly && make                    # Clean → MD5 b90957482011c8083a068781033715b7
cp ../patches/*.asm . && make             # Patched → different MD5
# Test: GreatTree → stairway → room $6B (BeefJerky NPC) → room $6C (YES/NO NPC)
# Revert: git checkout -- bank_000.asm bank_001.asm bank_004.asm bank_00b.asm bank_017.asm wram.asm game.asm
```
