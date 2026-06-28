# DOC AUDIT — Every Checkable Claim, Verified Against the ROM

Audit date: 2026-06-13. Method: clean repo built byte-perfect
(MD5 `1ca6579…`), then every factual claim in `documentation/` was tested
against the original ROM bytes, the disassembly source, the linker symbol
file (`game.sym`), and the extracted JSON. Verdicts: ✅ confirmed ·
✏️ corrected (fix applied to the doc) · ⚠️ open question.

Re-run spot checks any time with the snippets in each row's "How verified".

---

## A. Cross-document CONTRADICTIONS found and resolved

| # | Claim A | Claim B | Verdict — resolution applied |
|---|---------|---------|------------------------------|
| 1 | "Original MD5 `b909574…`" (NEXT_CLAUDE_MESSAGE, SESSION1_ARCHIVE) | "`1ca6579…`" (README, SCRIPT_TOOLS) | ✏️ **`1ca6579359f21d8e27b446f865bf6b83` is correct** (matches user's ROM; clean build now reproduces it). `b909…` was a drifted build from the bank $0B refactor. Stale docs deleted; verifier polices this forever. |
| 2 | Inventory at `$CA21–$CA50` (old README) | `wInventory = $CA51` × 20 (ARCHITECTURE, known_RAM_map, patches/wram.asm) | ✏️ **$CA51 correct** — confirmed by GiveItem handler (`ld hl, wInventory` in patches/bank_004) and known_RAM_map. README fixed. |
| 3 | NPC RAM slot = **17 bytes** ($11) (ROOM_DATA_FORMAT) | NPC RAM = **32 bytes** per NPC (ARCHITECTURE) | ✏️ **32 bytes correct.** The room-init parser at `$0B:Call_00b_477e` advances slots with `add $20` and writes fields at offsets +$00,+$01…+$11,+$16,+$18. The "$11" was a field offset, misread as the stride. ROOM_DATA_FORMAT fixed. |
| 4 | "530 NPC scripts" (EVENT_FLAGS, NEXT_CLAUDE_MESSAGE, ARCHITECTURE) | "209 scripts" (README, all_scripts.json blurb) | ✏️ **518 scripts**: bank $0C=129, $0D=168, $0E=130, $0F=91 (counted `*_ScriptNN:` labels; `extracted/all_scripts.json` also holds 518 entries). Both old numbers wrong; docs fixed. |
| 5 | Boss table "at `$14:$4897`, 33 entries" (old README) | "Boss redirect table at `$14:$4893`" (DATA_STRUCTURES) | ✏️ Both real, different things: **$4893** = redirect table start (first entry `0004→01E6` is a non-boss redirect), **$4897** = boss table proper, **32 gates × 4 bytes** `[fight_eid:2][join_eid:2]`. Verified against ROM bytes; matches bank_014.asm header. Docs standardized. |
| 6 | Bank $01 free space "$7FE0, 31 bytes, FF fill at bank end" (ARCHITECTURE) | — | ✏️ Actual FF run is **$7FD5–$7FFE (42 bytes)**; **$7FFF = $01, NOT free**. "31 bytes at $7FE0" was a safe subset but the boundary claim was false. ARCHITECTURE fixed. |
| 7 | "Custom tilesets — needs LZ compressor (~50 lines)" (NEXT_CLAUDE_MESSAGE) | — | ✏️ **Compressor already exists**: `tools/compress_tiles.py`, format-compatible with decompressor `$00:$14CF`, roundtrip re-verified this session (512→141 bytes, decompress matches). Roadmap updated. |
| 8 | `CheckEventFlag` at $26AE (EVENT_FLAGS) | source label `TestEventFlag` | ✏️ Address right, name wrong. Symbols verified via game.sym: `$26A0 SetEventFlag`, `$26A6 ClearEventFlag`, `$26AE TestEventFlag`. EVENT_FLAGS fixed to match source. |
| 9 | "Repo always builds to the original MD5" + "Bank $0B is safe (insertions OK, pinned SECTION)" (KEY_LESSONS) | byte-perfect rule | ✏️ The "$0B is safe" loophole is exactly what caused drift #1. Rule rewritten: $0B insertions are fine **in patches/ only**; `disassembly/` admits zero byte-changing edits of any kind. |
| 10 | "9 of 105 banks annotated" (old README) vs "~45%, banks $00/$04 fully" (NEXT_CLAUDE_MESSAGE) | — | ✏️ Measured (labels + comment density): **11 fully annotated** ($00 $03 $04 $0B $0C $0D $0E $0F $13 $14 $41), **~14 usefully partial**, **~80 raw**. "45%" conflated function-naming coverage with annotation. PROJECT_STATE carries the measured table. |
| 11 | `extracted/map_table.json` field names | ROOM_DATA_FORMAT + SameBoy verification | ⚠️ Known generator bug: interact/exit pointers **swapped** in the JSON (`dump_map_table.py`). ROOM_DATA_FORMAT labels are the verified truth. Fix the generator before the editor consumes this file (ROADMAP Phase 0). |
| 12 | "Skill dispatch at `$52:$4211`; 256 entries; 140 handlers" (bank_052 header, ROADMAP Arc 2) | actual disassembly + usage | ✏️ **All three wrong (S44).** Dispatch (`ld hl, SkillFunctionTable`) is at **`$6CC7`**; `$4211` is merely the first byte after the 444-byte table. Real count is **222** ($00–$DD), with **115** unique handlers (the 256/140 came from over-reading the table past id 221). Headers + ROADMAP corrected. |
| 13 | `TilesetLookupTable` at `$07:$570C` (disassembly label) | ROM bytes + FAQ | ✏️ **Mislabel (S44).** The 222 × u16 LE values (2,4,10,… ; 999 for ids 50/102) are the **SkillMPCostTable**, not tileset pointers (far too small for addresses). Reader `$56E8` = `GetSkillMPCost`. Annotated in comments; label/fn rename deferred pending SameBoy confirmation of the `$56E8` callers. |
| 14 | Skill id 215 = "Sheldodge" (name table) | family sub `$6349` + StubBird usage + FAQ learn reqs | ✏️ **Placeholder name (S44).** id 215's handler tests family code `$05`=Bug; StubBird's enemy list uses 215; its learn reqs (Lv12/HP68/Atk72/Agl62) match the FAQ "BugBlow" row exactly. It is the **Bug-family cut** → renamed **"BugCut"** in `patches/bank_041.asm`, SameBoy-confirmed. |
| 15 | mgbdis labels `Map4C/4D/4E/50/51/52/5A_Script*` in bank `$5f` (`$5660`–`$5b8e`) imply a clean map-cutscene-script region | live battle-anim code (`$5f:$52F0`/`$5441`) + ROM bytes + SameBoy (2026-06-28) | ⚠️ **CONTESTED REGION — do NOT convert to data blindly.** The animation index tables `$5f:$58dd`/`$59c3`/`$5aa9` (230 B each, by skill id, value=routine index, `$0d`=no-visual) are **verified by the live dispatch code + watchpoint** (Zap read `$58dd+id`). But these addresses fall **inside** the address span carrying the auto-generated `Map*_Script*` labels, and at least `Map5A_Script02` (`$5aea`) / `Map5A_Script03` (`$5b46`) sit **on `$0d` animation-padding bytes** — i.e. those two labels are **bogus** (mgbdis mis-traced an `rst $10` into anim data). Decoding `$5660` "as script pointers" yields `$db8a` (a RAM addr) = nonsense, so the `Map4C_ScriptPtrTable` labeling there is **also suspect**. The bank-`$5f` map-cutscene-script system was NOT traced this session, so which bytes are genuine map-script vs anim-table vs mislabel is unresolved. **Converting the anim tables to proper `db` requires first reversing the `$5f` map-script accessors to fix the boundaries — its own task.** Tool `tools/emit_anim_data_sections.py` emits byte-exact `db`/`dw` for the anim tables (230-B boundaries confirmed) but is NOT yet spliced for this reason. See BATTLE_SKILL_SYSTEM.md §11. |

## B. Claims VERIFIED CORRECT against ROM bytes (sample commands preserved)

| Claim (doc) | Verdict | How verified |
|-------------|---------|--------------|
| Monster table `$03:$4461`, 221 × 43 B (DATA_STRUCTURES) | ✅ | All 221 family bytes ∈ 0–9 at stride 43 from ROM offset `3*0x4000+0x461` |
| Enemy stats `$14:$4C1D`, 487 × 25 B, `$FF` delim at +$18 | ✅ | 487/487 entries have $FF at +$18 |
| Breeding special table `$16:$4B30`, 825 × 5 B, $FF-terminated | ✅ | Byte at base+825×5 = $FF; first entry `00 1B 00 0C 00` |
| Room pointer table `$0B:$4B43`, 107 rooms (mapIDs $00–$6A) | ✅ | 106/107 in-bank pointers + 1 $FFFF hole; entries 107–108 = $FFFF ⇒ `CUSTOM_ROOM_START = $6B` is exactly one past the table |
| Bank $00 free space $3FE8–$3FFF, 24 B FF-fill | ✅ | ROM bytes all $FF |
| Bank $51 free space $7B34, 1,228 B 00-fill | ✅ | ROM bytes all $00 (safety for code placement still unproven — ROADMAP) |
| Empty banks: 23 banks ($60,$64,$67,$69–$77,$79–$7A,$7C,$7E–$7F) | ✅ | Scanned all 128 banks for uniform $00/$FF; exact match, 23 banks = 368 KB |
| 2,067 text IDs decoded | ✅ | `len(text_id_map.json) == 2067` |
| 256 skills, 221 monsters extracted | ✅ | JSON lengths match |
| Encounter pools: 32 gates, pool indices 0–127 (125 referenced) | ✅ | encounters.json: 32 gates / 64 floor-groups / 125 distinct pools, max index 127. (Old "128 pools decoded" wording ≈ table capacity, kept but clarified.) |
| Event flag fns $26A0/$26A6/$26AE | ✅ | game.sym after byte-perfect build |
| `wScreenIndex = $C925` (ROUTING) vs "?" (known_RAM_map) | ✅ | game.sym `00:c925 wScreenIndex`; known_RAM_map annotated |
| Custom WRAM $D378+ free of original code refs | ✅ | Repo-wide grep: original references stop at `$D375` and `ld [$d376],sp` (touches $D376–77). $D378 onward clean. |
| Script compiler functional, all 100 opcodes | ✅ | `compile_script.py --test` passes |
| LZSS compressor roundtrip | ✅ | compress→decompress == original (512 B layout) |
| Text control codes ($E7=CHOICE, terminator `$F7 $F0`, `$EF $EE` newline) | ✅ (by prior in-game testing v23; consistent with bank $56 jump table) | Not re-traced this session |

## C. Claims that are PLAUSIBLE but UNVERIFIED (flagged in docs)

| Claim | Why unverified | Where tracked |
|-------|----------------|---------------|
| "All 2,404 function entry points named" | No reproducible counting method recorded; label census can't distinguish functions from branch targets. Treat as historical. | PROJECT_STATE (removed as a status metric) |
| Bank $51 1,228 zero bytes are SAFE for code | Zero-fill ≠ unreferenced; needs read-access trace | ROADMAP Phase D |
| Custom event flags persist in SRAM saves | Save format unmapped | ROADMAP Phase 0 (top priority) |
| "1,164 flag operations" (EVENT_FLAGS) | Derived from the script dump with the wrong script count; re-run `analyze_event_flags.py` after audit | EVENT_FLAGS note |

## D. Documentation consolidation executed

21 files → 17, with one entry point. Merges preserve all unique content:

| Action | File | Disposition |
|--------|------|-------------|
| DELETE | NEXT_CLAUDE_MESSAGE.md | Superseded by PROJECT_STATE + SESSION_PROTOCOL (wrong MD5, stale TODO list) |
| DELETE | SESSION1_ARCHIVE.md | Already marked superseded; wrong MD5 |
| MERGE→DELETE | SESSION2_CUSTOM_CONTENT.md | Bank $56 jump table → TEXT_SYSTEM.md; GiveItem wrapper → KEY_LESSONS (already there) + DATA_STRUCTURES; BGM table already lived in known_RAM_map (fuller version — gates 7–8 that SESSION2's copy dropped) |
| MERGE→DELETE | FIRST_5MIN_TRACE.md | Boot/intro trace appended to ROUTING.md as an appendix |
| KEEP+FIX | ARCHITECTURE.md | Bank $01 free space corrected; NPC slot 32 B; script count 518 |
| KEEP+FIX | ROOM_DATA_FORMAT.md | 17-byte slot → 32-byte slot with field offsets from the parser |
| KEEP+FIX | EVENT_FLAGS.md | 530→518 scripts; CheckEventFlag→TestEventFlag; flag-op recount flagged |
| KEEP+FIX | DATA_STRUCTURES.md | Boss table $4893/$4897 clarified |
| KEEP+FIX | KEY_LESSONS.md | "$0B safe" rule scoped to patches/ |
| KEEP | TEXT_SYSTEM, CROSSBANK_ROOMS, BANK04_SCRIPT_ENGINE, ROUTING, MONSTER_DATA, BREEDING_SYSTEM, QUEST_OPCODES, CUSTOM_CUTSCENES, SCRIPT_TOOLS, SAMEBOY_GUIDE, known_RAM_map, known_NOTES | Audited; no errors found beyond the above |
| NEW | PROJECT_STATE, SESSION_PROTOCOL, ROADMAP, EDITOR_DESIGN, DOC_AUDIT (this file) | The meta layer |

Rule going forward (SESSION_PROTOCOL §2): one concept, one home; corrections
are made in place; no new session/handoff files, ever.
