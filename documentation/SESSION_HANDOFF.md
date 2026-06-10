# DWM1 ROM Hack — Session Handoff (Bank $41 Complete + Bank $52 Skill Labels)

## Build Verification
```bash
cd disassembly
rm -f game.o game.gbc game.sym game.map
make
md5sum game.gbc
# MUST output: 1ca6579359f21d8e27b446f865bf6b83
```
**NEVER run `make clean`** — deletes committed `.2bpp` graphics files that
cannot be regenerated with matching bytes.

## What Was Completed This Session

### 1. Bank $41 — All Remaining Tables Annotated
Converted ALL raw hex between the already-labeled monster/skill name tables into
fully labeled assembly. Bank $41 is now **100% annotated** — every pointer table
uses `dw Label` references, every string has a named label, and all code functions
are labeled.

**New pointer tables (all using `dw Label` format):**
- `FamilyCodePtrTable` at $4739 — 215 entries (2-letter family code per monster)
- `ItemNamePtrTable` at $48E7 — 44 entries (item ID → name string)
- `ItemDescPtrTable` at $493F — 44 entries (item ID → description string)
- `PersonalityNamePtrTable` at $4997 — 27 entries (personality ID → name)
- `MiscTextPtrTable` at $49CD — 37 entries (battle tactics, level up messages)
- `WatabouTextPtrTable` at $4A17 — 2 entries
- `ItemUseTextPtrTable` at $4A1B — 48 entries (item use messages)
- `SpellUseTextPtrTable` at $4A7B — 12 entries (spell cast messages)

**New string sections (all labeled):**
- `FamilyCodeStrings` at $69F2 — 215 entries, 2 chars + $F0
- `ItemNameStrings` at $6C78 — 43 entries (Herb, Lovewater, SageStone, etc.)
- `ItemDescStrings` at $6DF8 — 43 entries with $F1=newline control codes
- `PersonalityNameStrings` at $7159 — 27 entries (HOTBLOOD through LAZY)

**Code functions labeled:**
- `Func_Bank41_GetText` at $4A93
- `Func_Bank41_PutText` at $4A9A
- `Func_Bank41_GetPutText` at $4AA1

**Bug fixed:** SkillNameStrings was 256 sequential entries bleeding into family
code territory. Now correctly 222 unique + 1 empty terminator at $69F1.
Skills 222-255 all point to that empty entry.

**Dispatch text regions** ($4AA8-$5B1E, $7229-$7FFF) are raw hex with labels
at all referenced addresses from MiscText/WatabouText/ItemUseText/SpellUseText
pointer tables.

**Stats:** 2648 lines, 933 labels. File reduced from 6338 lines.
**Generator:** `tools/gen_bank41_remaining_db.py` (`--apply` to regenerate)

### 2. Bank $52 — Skill Handler Labels from ROM Map
Applied named labels to all 115 skill handler functions in the battle system,
using an externally-sourced ROM map document.

**Function table:** 222 entries converted from `dw $XXXX` to `dw SkillBlaze` etc.
The table nominally has 256 entries but entries 222-255 overlap with the first
handler code (same pattern as bank $41's skill names).

**Overlap fix:** Entries 222-255 were fake `dw` values that were actually handler
code bytes. Replaced with properly disassembled handler functions:
SkillBlaze, SkillFirebal, SkillBang, SkillInfernos, SkillIceBolt, SkillBolt, SkillBeat.

**104 handler labels inserted** at correct positions throughout the bank:
SkillSleep, SkillStopSpell, SkillHeal, SkillVivify, SkillFarewell, SkillChargeUP,
SkillFireSlash, SkillMultiCut, SkillBigBang, SkillMegaMagic, SkillLifeDance, etc.

**Utility function renames (from ROM map):**
- 9 family checks: `CheckIsSlime`, `CheckIsDragon`, etc.
- 7 math helpers: `BCsrl3`/`BCsrl2`/`BCsrl1`, `HLsrl4`/`HLsrl3`/`HLsrl2`/`HLsrl1`

**Stats:** 11578 lines, 912 labels (was 801).
**Script:** `tools/annotate_bank052.py` (not idempotent — applied once)

## Key Patterns Discovered

### 222-vs-256 Overlap Pattern
Both bank $41 and bank $52 use the same space-saving trick: tables nominally
have 256 entries, but only entries 0-221 are valid. Entries 222-255 are "dead
space" that the game reuses for other data (strings in bank $41, handler code
in bank $52). The game never indexes beyond 221 for either skill names or
skill functions.

### Personality Index Formula (from ROM map)
```
personality_id = idx(Charge)*9 + idx(Cautious)*3 + idx(Mixed)
```
where `idx(x)` = 0 if x ≥ $C0, 1 if $40 ≤ x < $C0, 2 if x < $40.
This maps the 3×3×3 grid to the 27 personality names.

### Bank $00 Text System Functions
- `$07AB HandleTextCharacter` — processes text control codes
- `$0D78 ReadNextTextByte` — reads next byte from text stream
- `$05B6` and `$05F6` — called by bank $41's GetText/PutText functions

## ROM Map Intel (for future sessions)

An external ROM map document was provided with detailed analysis of several
banks. Key findings not yet applied:

**Bank $16 data tables (HIGH PRIORITY):**
- `$4874` UnevolvedSkillMap — 256 bytes mapping skill ID → base skill in evolution chain
- `$6E3D` RandomEncounterCounterTable — 50 entries × 4 bytes (PRN threshold + counter)
- `$702B` EncounterRateTable — variable (modifier per gate floor threshold)
- `$70A6` GateFloorDataTable — 32 entries × 8 bytes (floor config per gate)
- `$71A6` GateFloorTypeTable — 16×16 byte arrays (floor type selection)

**Bank $13 experience tables:** 32 entries × 297 bytes at $41E6

**Bank $50 personality adjustment tables:**
- Run ($59B6), Charge ($70A9), Mixed ($70C9), Cautious ($70E9), Command ($7109)
- Each 4×8: [Charge_adj, Mixed_adj, Cautious_adj, Motivation_adj]
- Rows selected by Motivation threshold (151) and Level bracket (10/20/30)

**Bank $00 math functions:**
- `$1DBE` Mul8x8To16 (HL = A × C)
- `$1DE6` Mul16x8To24 (E:HL = BC × A)
- `$1E0D` Div16x8To16 (HL = HL // A; A = HL % A)
- `$2F45` CmpHLvsBC
- `$2F4B` Div16x16To16 (DE = HL // BC; BC = HL % BC)

## Priority Work for Next Session

### HIGH — Data Table Annotation
1. **Bank $16 data tables** — unevolved skill map, encounter tables, gate floor data
2. **Bank $17 per-room attribute entries** — still raw hex between pointer tables
3. **Room name labels in gen_room_data_db.py** — add descriptive names

### MEDIUM — Code Bank Annotation
4. **Bank $16 code** — breeding system functions (already has good header docs)
5. **Bank $51 code** — battle init, event sub-handlers
6. **Bank $56/$57 code** — text engine, battle dispatch

### LOWER
7. NPC behavior values (lower nibble meanings)
8. GUI editor planning
