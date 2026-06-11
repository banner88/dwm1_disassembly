# DWM1 Disassembly Project — Complete Handoff

## READ FIRST — Critical Context

**The repo always builds to the original MD5: `b90957482011c8083a068781033715b7`.**

The cross-bank room system is PROVEN WORKING but lives as **separate patch files**, not in the repo. The editor will apply these patches to the original ROM at build time. See `CROSSBANK_ROOMS.md` and `KEY_LESSONS.md`.

---

## 1. What This Project Is

**Dragon Warrior Monsters** (DWM1) — Game Boy Color RPG (1998, Enix/TOSE).
Full ROM disassembly into buildable RGBDS assembly. Goal: custom game editor for rooms, scripts, breeding, NPCs, events.

**Disassembly state:** ~45% labels named. All 2,404 function entry points named. Banks $00 and $04 fully named.

---

## 2. Critical Rules

```bash
cd disassembly && make
# MUST output: b90957482011c8083a068781033715b7
```

- **NEVER `make clean`** — deletes .2bpp graphics
- **NEVER `git stash`** — can revert all changes
- **RGBDS v0.6.1** required

---

## 3. Cross-Bank Room Patches (SEPARATE from repo)

The `patches/` directory contains 7 modified ASM files that enable custom rooms in bank $60+. These are applied by the editor on top of the clean repo, NOT committed to the repo.

**To test patches:** copy all `patches/*.asm` into `disassembly/`, build. MD5 will be different (expected). Revert with `git checkout -- <files>`.

**Read before touching patches:**
- `KEY_LESSONS.md` — Every bug from 19 iterations
- `CROSSBANK_ROOMS.md` — Complete implementation reference

**Critical patch rules:**
- NEVER insert bytes into bank $01 or $17 — raw embedded pointers break
- rst $10 clobbers register A — use DE/HL or ROM0 calls
- Every table indexed by mapID must be patched (11 found, all patched)

---

## 4. What's DONE

| System | Status |
|--------|--------|
| Cross-bank rooms | ✅ PROVEN (patches ready) |
| All data tables labeled | ✅ |
| Script system (530 scripts, 100 opcodes) | ✅ |
| Event flags (311 mapped, 463 free) | ✅ |
| Breeding/monsters/skills/EXP tables | ✅ |
| Multi-screen room scrolling | ✅ |

---

## 5. What's LEFT for the Custom Editor

| Priority | Task | Difficulty | Blocking? |
|----------|------|-----------|-----------|
| 1 | **NPC scripts in custom rooms** — intercept bank $04 MapTypeDispatch for mapID ≥ $6B | Medium | Yes — no dialogue without this |
| 2 | **Text/dialogue** — survey text ID capacity, add entries | Medium | Yes — NPCs need text |
| 3 | **LZ compressor tool** — reverse of decompress_tiles.py (~50 lines Python) | Easy | No — can reuse existing layouts |
| 4 | **Custom tilesets** — $26DD table + bank $17 extension | Hard | No — can reuse existing art |
| 5 | **Story events** — custom scripts with event flags | Easy (after P1) | No |
| 6 | **MapID scaling** — table-based source mapID for many rooms | Medium | No — works for small count |

**Shortest path to playable custom content:** Priorities 1-2 unlock NPC dialogue. Everything else builds on that.

---

## 6. Key Documentation

| File | Read When |
|------|-----------|
| KEY_LESSONS.md | BEFORE touching cross-bank code |
| CROSSBANK_ROOMS.md | Complete implementation reference |
| ROOM_DATA_FORMAT.md | Room data structure |
| BANK04_SCRIPT_ENGINE.md | Script routing (needed for Priority 1) |
| DATA_STRUCTURES.md | All game data tables |
| TEXT_SYSTEM.md | Text encoding (needed for Priority 2) |

---

## 7. Patch Files (in `patches/` directory)

| File | What It Patches |
|------|----------------|
| bank_060.asm | NEW: custom room data bank |
| bank_000.asm | 2 ROM0 helpers + collision fix |
| bank_001.asm | 4 same-size mapID patches |
| bank_00b.asm | 6 intercept patches + exit redirect |
| bank_017.asm | 2 same-size palette patches |
| wram.asm | WRAM buffer definitions |
| game.asm | Bank $60 include |
