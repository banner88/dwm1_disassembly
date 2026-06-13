# SESSION PROTOCOL — How Every Session Adds Value Without Losing Knowledge

This project is built across many short-lived Claude sessions. Knowledge loss
between sessions caused real damage (the byte-perfect drift went unnoticed for
multiple sessions and was then "blessed" in docs). This protocol is the fix.
It is mandatory, short, and cheap.

---

## 0. How to actually run a session (the practical loop)

You (the human) do four things per session; Claude does the rest.

**1. Start a fresh Claude session and paste the kickoff prompt below.**
**2. Upload `DWM-original.gbc`** (the verifier and most tools need it).
**3. Review Claude's APPLY list at the end** — replace/add/delete the
listed files locally, commit, push. CI re-verifies the build.
**4. Tick the ROADMAP box** if Claude forgot to.

### Kickoff prompt (copy-paste verbatim, edit only the TASK line)

```
Project: Dragon Warrior Monsters (GBC) disassembly + custom game editor.
Repo: https://github.com/banner88/dwm1_disassembly/  — clone it.
ROM is attached; place it at data/DWM-original.gbc.

Mandatory startup, in order:
1. Read documentation/PROJECT_STATE.md (canonical facts + iron rules),
   then documentation/ROADMAP.md, then documentation/SESSION_PROTOCOL.md.
2. Build RGBDS v0.6.1 and run: python3 tools/verify_integrity.py
   It must PASS 4/4 before any work. If it fails, fixing it IS the task.
   Never change the expected MD5 (1ca6579359f21d8e27b446f865bf6b83).
3. Before trusting any documented address/format/opcode you depend on,
   verify it against the disassembly or ROM bytes (docs have been wrong;
   see DOC_AUDIT.md). Read KEY_LESSONS.md before touching patches.

TASK: <either: "next unchecked item in ROADMAP Phase 0/1" or a specific
item, e.g. "Phase 1: teleport/warp opcode $0E — meet its acceptance test">

Work rules: ONE roadmap item only. disassembly/ admits zero byte-changing
edits (labels/comments only); functional changes go in patches/. Any tool
you write or improve that produces extracted/ data must be delivered WITH
the data. Knowledge goes into the existing doc that owns the topic — never
a new status/handoff file.

Mandatory wrap-up: run verify_integrity.py (must PASS), update
PROJECT_STATE.md status rows + ROADMAP.md checkbox/blocker notes +
the owning reference doc, then give me the changed files plus an
APPLY_THESE_CHANGES list (REPLACE / ADD / DELETE). No git on your side.
```

### Why "just follow the roadmap" is almost — but not quite — the answer
The roadmap supplies the WHAT (one scoped item with an acceptance test).
The protocol supplies the HOW (verify-first, doc-update-in-place,
deliver-with-apply-list). Skipping the protocol is how the project
previously lost byte-perfection and grew three contradictory MD5s. The
kickoff prompt welds the two together so a fresh session with zero memory
still behaves like a continuing one.

## 1. Session START (10 minutes, always)

```bash
# a) Read, in order:
documentation/PROJECT_STATE.md      # status, iron rules, canonical facts
documentation/ROADMAP.md            # what the current phase is
documentation/reference/KEY_LESSONS.md   # only if touching patches/ASM

# b) Verify the repo before trusting it:
mkdir -p data && cp <user-provided ROM> data/DWM-original.gbc
python3 tools/verify_integrity.py
```

If the verifier FAILS: fixing it IS the session's first task. Do not build
new work on a broken foundation, and never adjust the expected MD5 to make
a failure pass.

Pick ONE task from ROADMAP.md (or the user's explicit request). State it.
Sessions that try three things finish zero.

## 2. During the session

- **Verify before believing.** Docs here have been wrong in specific,
  costly ways. For any address, format, or opcode you depend on: grep the
  disassembly or dump the ROM bytes first. 30 seconds of grep beats hours
  of theorizing (see KEY_LESSONS.md for five examples).
- **Clean tree vs patches.** `disassembly/` may only gain labels and
  comments. Anything that changes emitted bytes goes in `patches/`.
  After ANY edit to `disassembly/`, rebuild and check the MD5 immediately.
- **One concept, one home.** New knowledge goes into the single relevant
  reference doc (or PROJECT_STATE.md if it's status). Never create
  `SESSION_N_NOTES.md`, `HANDOFF_v2.md`, `FINDINGS.md` etc. If a doc is
  wrong, fix it in place — don't write a correction elsewhere.
- **Commit the tool with the data.** If you improve a dumper in-session, the improved tool ships in the same APPLY list as its output, or the output becomes unreproducible (this already happened: see TOOLS_AND_DATA.md Tier B).
- **Generated files note their generator.** Any `extracted/*.json` you
  produce must contain a `"_generator"` key naming the tool and ROM source.
- **Test in-game when patching.** A patched ROM that builds is not a
  patched ROM that works. Use SameBoy (SAMEBOY_GUIDE.md). Record the
  iteration number (continue the v23 sequence).

## 3. Session END (10 minutes, always — even if interrupted, do this early
   whenever a milestone lands rather than saving it all for the end)

```bash
python3 tools/verify_integrity.py     # must PASS
```

Then update, in place:

1. **PROJECT_STATE.md** — flip status rows you changed; update the
   "Last verified" date; add any new known defect you discovered but
   didn't fix.
2. **ROADMAP.md** — check off what's done; if you hit a wall, write the
   exact failure mode and the next thing to try (this is the single
   highest-value sentence you can leave behind).
3. **KEY_LESSONS.md** — only if you debugged something non-obvious. Format:
   Symptom / Root cause / Fix / Rule. Lessons without a Rule are stories.
4. The relevant **reference doc** — new addresses, formats, opcodes,
   verified behaviors.

Deliver changed files to the user as files (this project does not let
Claude run git). List exactly: files to REPLACE, files to ADD, files to
DELETE.

## 4. What a session must never do

- Never change `ORIGINAL_MD5` in `tools/verify_integrity.py` or any doc.
  If a build mismatches, the BUILD is wrong, by definition.
- Never refactor/optimize `disassembly/` (even "harmless" `jp`→`jr`).
- Never insert bytes in banks $01/$04/$17 (and in `disassembly/`, any bank).
- Never run `make clean` or `git stash`.
- Never write a new top-level status/handoff doc.
- Never re-run a `gen_*.py --apply` tool over a bank with un-regenerated
  manual edits (it overwrites them with original ROM data).

## 5. Locating a byte-perfect regression (if verifier check 1 fails)

```python
# Diff built ROM vs original, report ranges per bank:
orig  = open('data/DWM-original.gbc','rb').read()
built = open('disassembly/game.gbc','rb').read()
diffs = [i for i in range(len(orig)) if orig[i] != built[i]]
# group; bank = offset // 0x4000; in-bank addr = 0x4000 + offset % 0x4000
```

$014E–$014F differences are just the header checksum — the real cause is
always elsewhere. Then `git log -- disassembly/bank_0XX.asm` to find the
offending commit and revert the byte-affecting hunks (keep label renames).
