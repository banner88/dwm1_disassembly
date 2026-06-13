# PROJECT STATE — Single Source of Truth

> **This file is the entry point for every session.** It is the only document
> allowed to state project-wide status. Other docs are subject-specific
> references and must not duplicate status claims. If this file and another
> doc disagree, this file wins — and the session should fix the other doc.
>
> Last verified: 2026-06-13 (v24 test ROM: monster give $29+$28,
> teleport $0F (not $0E — that's BranchByScreen), BGM change $41;
> opcode $0E/$0F misidentification in bank_004.asm + BANK04_SCRIPT_ENGINE
> fixed; $00/$01 naming confirmed correct; NPC show/hide step system
> confirmed in-game via SameBoy)

---

## Canonical Facts (verified, do not trust other copies)

| Fact | Value |
|------|-------|
| Original ROM MD5 | `1ca6579359f21d8e27b446f865bf6b83` |
| Clean build target | MUST equal the MD5 above, byte-perfect |
| Assembler | RGBDS v0.6.1 exactly |
| ROM size | 2 MB, 128 banks ($00–$7F) |
| Custom content bank | $60 (~15.3 KB free as of v23 content) |
| Empty banks available | 23 banks = 368 KB: $60,$64,$67,$69–$77,$79–$7A,$7C,$7E–$7F |
| Verifier | `python3 tools/verify_integrity.py` — run at session start AND end |

**The MD5 `b90957482011c8083a068781033715b7` is WRONG.** It was a drifted
build produced when commits `2000e99`/`036dc06` refactored bank $0B code
(inline pointer chases → `call SharedPtrChase`), shifting ~2,282 bytes. A
session then rewrote the handoff doc to "bless" the drifted hash. Restored
to byte-perfect on 2026-06-13 by reverting bank_00b.asm to the e78eb1d
version (+1 symbol rename). Any doc still citing `b909...` is stale.

## Iron Rules

1. **Clean disassembly is never refactored.** No `jp`→`jr`, no shared-helper
   extraction, no "optimization" in `disassembly/`. All such changes go in
   `patches/`. Annotation = labels and comments ONLY (zero byte impact).
2. **Never insert bytes into banks $01, $04, $17** (raw embedded pointers).
   Same-size replacements or wrappers in end-of-bank padding only.
3. **Never `make clean`** — it deletes committed `.2bpp` binaries that cannot
   be regenerated identically. Remove only `game.o game.gbc game.sym game.map`.
4. **`verify_integrity.py` must PASS before any commit.**
5. **When in doubt, grep the ROM/disassembly for how the original does it.**
   Documentation has been wrong before ($E7 ≠ END; opcode $04 ≠ give item).

---

## Status Dashboard

### Custom content primitives (all proven in-game, ROM v23)

| Primitive | Status | Where |
|-----------|--------|-------|
| Custom rooms (mapID ≥ $6B), multi-screen, exits | ✅ working | patches/bank_060.asm + intercepts |
| Custom NPCs with scripts | ✅ working | bank $60 entry 4 dispatch |
| Custom text, multi-page, line breaks | ✅ working | IDs $0A00+, two-level ptr table |
| YES/NO choices with branching | ✅ working | $E7 $F0 + opcode $15 on $C83C |
| Item give + inventory-full check | ✅ working | opcodes $2A (wrapped) / $2C |
| Monster/egg give + storage-full check | ✅ working | opcodes $29 (wrapped) / $28; egg give proven with SkyDragon (EID 350) |
| Script-driven teleport | ✅ working | opcode $0F (MapTransitionFull); vanilla + custom destinations |
| BGM change | ✅ working | opcode $41 (SetBGM); track reverts on room exit |
| Event flags set/clear/check | ✅ working | opcodes $00/$01/$03; 328 used, 298 with sets, ~200 safe+persistent free |
| LZSS tile compressor | ✅ working | tools/compress_tiles.py, roundtrip verified |
| Script compiler/decompiler | ✅ working | tools/compile_script.py / decompile_script.py |

### Not yet implemented (the roadblocks — see ROADMAP.md)

| System | Blocker |
|--------|---------|
| Random encounters in custom rooms | Encounter system entangled with gate/floor generator via `wInGateworld` ($C969) |
| Teleport/warp between maps | ✅ Exit-based transitions work all directions (v23). Script-driven teleport via opcode **$0F** (MapTransitionFull) **confirmed working** from custom scripts — both vanilla destination (Castle) and custom room ($6B) tested. Note: $0E is BranchByScreen, NOT teleport (bank $04 comment was wrong, fixed). Format: `$FF0F <gate_id:flag> <spawnX> <spawnY>`. |
| BGM change | ✅ Opcode $41 (SetBGM) **confirmed working** in custom scripts. Saves current BGM to $C8B6, plays new track. Tested with Arena music ($1E) in custom room. |
| Monster give | ✅ Opcode $29 (AddMonster) **confirmed working** in custom scripts. Gives egg (enemy_stats_id=350 SkyDragon = proven, same as Farm event) or monster to storage. Opcode $28 (CheckStorageFull) also confirmed. Wrapper needed (bare `ret` → AddMonsterWrapper, same fix as GiveItem $2A). Note: without `$FF04 $000F` preamble, species/stats may not fully initialize — eggs work perfectly; direct monster give needs further investigation for stat initialization. |
| NPC show/hide by flag | Mechanism confirmed in-game: step system (multiple step entries per screen, counter set by opcode $12). SameBoy test: setting Castle screen 5 step counter $D92C from 4→0 made a priest NPC appear. Remaining: test in a custom room with ≥2 step entries + WriteRAM opcode $12 to advance counter on room re-entry. |
| Custom tilesets | Compressor done; needs PNG→tile pipeline + tileset GFX loading from custom bank |
| Custom music | Sound engine unexplored |
| Save-data audit | SRAM save layout fully traced and documented in ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 are in save range. Flag byte collisions mapped. Only remaining: in-game save/load test of a custom flag in SameBoy. |

### Disassembly annotation (measured 2026-06-13, not estimated)

Objective metric: meaningful (non-auto) labels + comment density per bank.

| Tier | Banks | Notes |
|------|-------|-------|
| Fully annotated (11) | $00 $03 $04 $0B $0C $0D $0E $0F $13 $14 $41 | Core engine + script data banks |
| Useful partial (≈14) | $01 (36%) $16 (30%) $17 (75%) $50 (21%) $51 (27%) $52 (36%) and tileset banks $23–$31/$37/$38 (data-only, trivially "done") | |
| Effectively raw (~80) | everything else | mgbdis output, auto labels |

All 2,404 function entry points are named repo-wide, but most bank
*internals* are raw. "~45% disassembled" overstates editability: **data
tables inside raw banks are still misassembled as fake instructions**, which
blocks direct editing of monsters/enemies/encounters/breeding in source.

### Known documentation defects (to fix as encountered)

- ~~Two contradictory MD5s across docs~~ → fixed; verifier now polices this.
- README inventory range `$CA21–$CA50` was wrong; **correct: `wInventory` =
  `$CA51`, 20 slots** (ARCHITECTURE.md + patches/wram.asm agree, verified in
  GiveItem handler).
- ~~`extracted/map_table.json` interact/exit labels swapped~~ → fixed;
  `dump_map_table.py` rewritten with verified semantics + $FFFF hole-
  skipping bug also fixed (was dropping a third of rooms).
- NEXT_CLAUDE_MESSAGE.md and SESSION1_ARCHIVE.md are superseded — delete
  (replaced by this file + SESSION_PROTOCOL.md + ROADMAP.md).
- ~~Data layer: tool-behind-data and frozen-source JSONs~~ → ALL RESOLVED.
  `dump_enemy_stats.py` reconciled (full 25-byte decode, 487/487 match);
  new generators written for `skills.json`, `text_id_map.json`,
  `all_scripts.json`; `map_table.json`/`exit_table.json`/
  `room_connections.json` regenerated with fixed decoders; remaining
  JSONs reclassified (hand-authored reference or stable analysis, not
  frozen-source). See TOOLS_AND_DATA.md for the complete audit.
  `monsters.json`, `event_flags.json`, `edits.json` are legacy (deletable).
- KEY_LESSONS.md claims "Bank $0B is safe for insertions" — true for the
  *patched* tree, but this is exactly the loophole that caused the
  byte-perfect drift. Insertions in $0B are allowed **in patches/ only**.
- ~~ROADMAP "NPC show/hide" pointed at opcodes $48/$49 and claimed the
  mechanism was "untraced"~~ → Fixed. The mechanism is the **step
  system** (multiple step entries per screen, counter at $D92A–$D99A
  set by opcode $12). Opcodes $48/$49 are runtime movement-based
  show/hide for cutscenes. Full documentation added to
  ROOM_DATA_FORMAT.md "Room State System", ARCHITECTURE.md RAM map,
  known_RAM_map.md, and CUSTOM_CUTSCENES.md.
- ~~Decompiler opcode names had systematic errors~~ → Fixed. Handler
  code verified against ROM bytes for all critical opcodes. Key fixes:
  $29 was "give_item" (actually AddMonster), $2A was "check_level"
  (actually GiveItem — PROVEN in v23), $41 was "save_map_return"
  (actually SetBGM). Compiler had same errors — "give_item" compiled
  to $29 (AddMonster) instead of $2A (GiveItem). All three tools
  reconciled: decompile_script.py, compile_script.py,
  dump_all_scripts.py. all_scripts.json regenerated.
- ~~Opcodes $00 and $01 names may be swapped~~ → **Confirmed correct
  (no swap).** Verified from assembly: $00 handler does `jp nz, skip`
  after `TestEventFlag`, so it branches when flag is CLEAR =
  "if_flag_clear". $01 handler does `jp z, skip`, so it branches when
  flag is SET = "if_flag_set". `TestEventFlag` returns Z=clear, NZ=set
  via `and [hl]`. Definitively resolved from code; no SameBoy test needed.
- ~~dump_all_scripts.py decoded linearly, missing ~45% of WriteRAM ops
  at branch targets~~ → Fixed. Work-queue follows 9 branch opcodes.
  810/866 unique WriteRAM ops found (93.5%); 56 in alternate dispatch
  paths remain. $D9E3 story progression counter documented.
- ~~14 separate room-name dictionaries across tools (30–97 entries each,
  all different)~~ → Fixed. Created `dwm/map_names.py` as single source
  of truth (97 entries from editor/editor.py). All 14 tools now import
  from it. Regenerated JSONs use canonical names.
- ~~`analyze_event_flags.py` scanned scripts linearly, missing 70% of
  set_flag operations behind branches~~ → Fixed. Tool now reads
  `all_scripts.json` (branch-following data). Result: 298 flags with
  sets (was 92); check-only anomalies dropped from 219 to 29.
  `event_flags_complete.json` and `EVENT_FLAGS.md` regenerated.
  The 29 remaining are in the 6.5% unreached script paths or engine-set
  (flag $00F1 confirmed in unreached Castle script 0 branch at $0C:$46C4).
  Story progression fully mapped: arena-driven with mandatory Anger/
  Durran gate interludes.
- ~~Bank $04 inline comment at $59D2 labeled opcode $0E as
  "SetMapTransition"~~ → Fixed. $0E is **BranchByScreen** (branches
  if `wScreenIndex == param`). The real map transition is opcode
  **$0F** at $5A02 (MapTransitionFull: writes gate_id → $C96D, flag
  → $C96E, spawn XY, sets wIsPlayerChangingMaps). ROADMAP also
  corrected ($0E → $0F).

---

## Repository Layout (target structure)

```
README.md                      Quick start + pointers (no status claims)
documentation/
  PROJECT_STATE.md             ← YOU ARE HERE. Status + canonical facts.
  SESSION_PROTOCOL.md          How every session starts, works, ends.
  ROADMAP.md                   Phased plan to the editor + open roadblocks.
  EDITOR_DESIGN.md             Architecture of the new editor.
  reference/                   Subject docs (stable knowledge):
    ARCHITECTURE.md  DATA_STRUCTURES.md  BANK04_SCRIPT_ENGINE.md
    TEXT_SYSTEM.md   ROOM_DATA_FORMAT.md CROSSBANK_ROOMS.md
    EVENT_FLAGS.md   ROUTING.md  MONSTER_DATA.md  BREEDING_SYSTEM.md
    QUEST_OPCODES.md CUSTOM_CUTSCENES.md SCRIPT_TOOLS.md
    KEY_LESSONS.md   SAMEBOY_GUIDE.md    known_RAM_map.md  known_NOTES.md
    SIDEQUEST_MAP.md
disassembly/                   Byte-perfect source. NEVER refactored.
patches/                       All custom-content modifications.
extracted/                     Generated JSON (regenerable; note generator in file header)
tools/                         Python tools incl. verify_integrity.py
dwm/                           Python support package (rom, text, map_names — single source of truth for room names)
editor/  (legacy)              Frozen Streamlit editor — do not extend
data/                          DWM-original.gbc (gitignored, user-provided)
```

Housekeeping queue (low priority, safe deletions): root-level `rom.py`,
`text.py`, `__init__.py`, `__pycache__/` (stale duplicates of `dwm/`;
nothing imports them), `.DS_Store` files, stray
`disassembly/18-5694-TEXT_DeathMore_Intro`, `ALL_ROOMS_FINAL.png` and
`FULL_FAQ.txt` → move under `documentation/reference/assets/`.
