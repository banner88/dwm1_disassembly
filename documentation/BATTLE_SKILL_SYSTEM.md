# Battle Skill System & Custom-Skill Alias Framework (ROADMAP S2)

Reverse-engineering of the DWM (GBC) battle skill-cast pipeline, and the
**skill-alias framework** that adds genuinely net-new skill ids ($DE "Scorch",
$DF "Smite") to the starter monster (enemy-stats EID 1, in-game "Slib").

Session S45. Built ROM that passed in-game testing: md5 `6e8b8337805d020ca6cdbf878c21f1c6`
(this is the **patched** ROM, NOT the original `1ca6579359f21d8e27b446f865bf6b83`).

---

## ⚠️ READ THIS FIRST — CONFIDENCE & UNCERTAINTY (do not trust at face value)

This system took **9 test iterations** to get right. Several of my earlier
confident claims were WRONG and only got caught by in-game testing. A future
instance must treat the "INFERRED" items below as hypotheses, not facts, and
**re-verify against the ROM / a live debugger before relying on them.**

**VERIFIED in-game (v9, user-confirmed):**
- $DE "Scorch" casts as Blaze: targets the enemy, Blaze animation + cast
  message, ~14 dmg. $DF "Smite": same presentation, fixed **80** damage.
- Basic attacks work for both player and enemy (no corruption).
- Menu shows "Scorch"/"Smite" correctly.
- The final architecture (commit-templatize + `$db86` stash + `$db8a==0`
  dispatch guard) is correct for the single-custom-caster case.

**VERIFIED by disassembly + matching behavior (high confidence):**
- Effect dispatch at `$52:$6CC7` reads `$db8a` → function table `$52:$4011`.
- The function-table hook at `$52:$6CD5` (→ `FarSkillFork`, bank `$72`).
- `AliasCommit` hook at `$50` line 1864 (the player skill-commit, replacing a
  `call LoadBtl_4f86`).
- Per-skill record table: pointer table `$54:$4013` → 19-byte records from
  `$54:$41CF` (Blaze = id 0). `ptr[i] = $41CF + i*19`.
- `$db8a` = the engine's working skill id, re-derived from action queue `$dcec`.
- `$db4c` (record index) is re-derived **from `$db8a`** repeatedly during a cast
  (bank `$53` lines 1433/1778/2018/5054…). This is WHY templatizing the queue
  fixes targeting.

**INFERRED / ASSUMED — NOT fully verified. RE-CHECK before trusting:**
- **Combatant struct array `$dd80 + 26*k`** (stride 26 = `$1a`, ~8 slots,
  `$dd80`–`$de4f`). DEDUCED only from the literal base addresses that appear in
  code (`$dd80,$dd9a,$ddb4,$ddce,$dde8,$de02,$de1c`). The stride and slot count
  were never confirmed by decoding the index math. What IS confirmed: writing
  `$ddf0`, `$ddfe`, and `$de36` each corrupted live battle state (enemy stats /
  status / damage), so that whole region is OFF-LIMITS. `$dde8` is (probably)
  the enemy's struct base in a 1v1.
- **Field meanings inside records / structs** (record +2 targeting flags, +4 MP,
  +$0b/+$0f damage params; `$dd6f` bit5 = apply damage). Behaviour matched, but
  exact bit/offset semantics are inferred, not exhaustively proven.
- **`SaveBtlFX_43ff` bucket boundaries** (`cp $37`, `cp $d9`, `cp $dd`). Read
  from disassembly; not every branch traced live.
- **`$c8dd` (commit-time combatant index) == `wBattleAttackerIdx` (cast-time).**
  Inferred from queue-slot consistency. The FINAL design does NOT depend on this
  (an earlier design that did, failed — see below).
- **`sm83dis.py`** was validated only against `SkillBlaze` and the dispatch.
  Not fuzzed against the full opcode map. Trust its output for those shapes,
  spot-check anything exotic.

**KNOWN LIMITATIONS of the shipped framework:**
- Only ONE pending custom skill is tracked (`$db86` is a single byte). If two
  party monsters both queue custom skills in the same turn, only the
  last-committed one dispatches correctly. Fine for one custom-caster.
- **Enemy-casts-Blaze edge case:** the dispatch guard distinguishes "aliased
  custom cast" from "normal cast" by `$db8a == 0`. A *real* Blaze cast also has
  `$db8a == 0`. So if an ENEMY casts genuine Blaze on the same turn the player
  has a custom skill pending AND the enemy moves first, the enemy would borrow
  the player's custom effect. Starter enemies don't have Blaze, so it doesn't
  surface, but it's unclosed. Proper fix = per-caster ownership (needs a couple
  more verified-free RAM bytes, or capture at a cast-setup point — see "dead
  ends").

---

## 1. The core problem: id-range bucketing is pervasive

There is **no single "current skill" variable** the engine reads. Instead, the
skill id is bucketed by NUMERIC RANGE in many independent places — targeting,
animation, cast message, MP, the per-skill record — each with its own hardcoded
`cp`-chain or table bound (most tables are 222 entries; a new high id like `$DE`
overshoots them all). So a net-new id presents wrong **everywhere** unless every
bucket is taught about it, OR the id is made to masquerade as an existing one.

We chose to **masquerade** (the alias framework): make the new id behave as a
**template** existing skill (Blaze, id 0) for the whole engine, and only peel off
the real id where the custom **effect** is dispatched and where the **name** is
shown.

## 2. The cast pipeline (data flow)

```
 menu select (player) ──> action queue $dcec[combatant]  (2 bytes/slot: id, target)
                            │
   selection readback @ $50:1864-1868:  LoadBtl_4f86 writes b->$dcec[$c8dd],
        reads it back into $db4c / $db8a / $db4f
                            │
   cast state machine (bank $53):  re-derives $db8a from $dcec[wBattleAttackerIdx]
        at several points; re-derives $db4c FROM $db8a (1433/1778/2018/5054…)
                            │
   presentation buckets read $db8a / $db4c:
     - targeting: record-driven via $db4c -> record +2 flags -> wBattleTargetIdx
     - FX/anim/message: SaveBtlFX_43ff (bank $58) buckets $db8a by range
     - record props (MP, damage params): $54:$4013 table indexed by $db4c
                            │
   effect dispatch @ $52:$6CC7:  reads $db8a -> SkillFunctionTable $52:$4011
        -> handler (e.g. SkillBlaze $52:$41CD) -> computes damage into $db56/57
        -> descriptor $dd6f tells the consumer how to apply it
```

The single source everything re-derives from is the **action queue `$dcec`**.
Templatize the queue early enough and the entire engine inherits the template.

## 3. The shipped framework (final, working)

Three hooks, all byte-neutral, plus one new bank:

1. **`AliasCommit`** — bank `$50`, replaces the `call LoadBtl_4f86` at the player
   skill-commit (line 1864). `b` is the committed id. If `b ∈ {$DE,$DF}`: stash
   `b -> $db86` (the real id), set `b = 0` (Blaze template), then tail-`jp
   LoadBtl_4f86` so the queue + the immediate readback into `$db4c/$db8a/$db4f`
   all get Blaze. Otherwise clear `$db86 = 0` and commit `b` unchanged.
   *Templatizing here, before the readback at 1866, is what makes targeting and
   animation correct.*

2. **`FarSkillFork`** — bank `$72`, far-called from the dispatch hook at
   `$52:$6CD5` (which replaced `ld hl,$4011 / add hl,bc / add hl,bc`). Returns
   `HL = &handler-pointer`, `BC = id`. Logic:
   - `$db8a != 0` → normal action (incl. every enemy action) → dispatch on
     `$db8a`. **This guard is what stops the enemy reading the player's stash.**
   - `$db8a == 0` → consult `$db86`: if `$DE/$DF`, that's our aliased cast → use
     it; else it's a genuine Blaze cast → id 0.
   - id `<$DE` → `HL = $4011 + id*2` (vanilla). id `$DE/$DF` →
     `HL = $7FED + (id-$DE)*2` (CustomSkillTable52, bank `$52` tail).

3. **`CustomSkillTable52`** @ `$52:$7FED`: `dw SkillBlaze($41CD)`,
   `dw NovelEffect52($7FF1)`. So $DE→Blaze's own handler (pure reuse), $DF→custom.
   **`NovelEffect52`** @ `$52:$7FF1`: `call $5BFF` (Blaze damage machinery) /
   `call $54E7` (descriptor setter) / `ld a,$50; ld [$db56],a` (override to 80) /
   `ret`. Runs with `$db8a=0` so it borrows all of Blaze's setup.

4. **Names** — bank `$41`: `SkillNamePtrTable` ($41:$4539, 256 entries) [$DE]→
   "Scorch", [$DF]→"Smite" (encoded strings in the bank tail). The in-battle
   menu reads the real id (`$caea`), so names show correctly without extra work.

5. **Assignment** — bank `$14`: starter EID 1 skills `db $DE,$DF,$FF,$FF`, MP
   set to 100.

**The one new RAM byte:** `$db86` (a documented unused `ds` gap between
`wJoinability $db85` and `wBattleAttackerIdx $db88`). Verified safe by testing.

## 4. Verified addresses (quick reference)

| Thing | Address |
|---|---|
| Action queue (id,target per combatant, stride 2) | `$dcec` |
| Working skill id (re-derived from queue) | `$db8a` |
| Record-lookup index (re-derived from `$db8a`) | `$db4c` |
| "Selected skill" (targeting helper) | `$db4f` |
| Attacker / target combatant index | `$db88` / `$db89` |
| Computed damage number | `$db56`/`$db57` |
| Damage descriptor bitfield (bit5 = apply $db56/57) | `$dd6f` |
| Animation pointer (Blaze = `$b882`) | `$dd70`/`$dd71` |
| Skill function table (222 entries) | `$52:$4011` |
| Effect dispatch site (reads `$db8a`) | `$52:$6CC7` (hook at `$6CD5`) |
| SkillBlaze handler | `$52:$41CD` |
| Per-skill record pointer table (222) | `$54:$4013` |
| Record data start (Blaze rec, 19 bytes) | `$54:$41CF` |
| FX/anim/message selector | `SaveBtlFX_43ff` (bank `$58`) |
| Skill name pointer table (256) | `$41:$4539` |
| **Our stash (real id, single)** | **`$db86`** |
| **Our custom dispatch fork** | **`FarSkillFork` `$72:$4003`** |
| **Our custom handler table** | **`$52:$7FED`** |

## 5. Dead ends (so nobody re-treads them)

- **Net-new high id with no aliasing** → wrong animation + wrong cast message
  every time (deterministic mis-bucketing, NOT random procs).
- **Per-bucket fixes** (fix targeting, then animation, then message…) → endless
  whack-a-mole; the buckets are in ≥3 banks ($50/$52/$53/$58).
- **Record-table relocation** (give $DE/$DF Blaze's record) → fixes only
  record-driven props (targeting/MP/damage), NOT the separately-id-bucketed
  animation/message. Reverted.
- **Templatize at cast-setup (line 943) instead of commit** → too late:
  targeting is locked in at the selection readback (1866) before 943, so Slib
  hit himself with no animation. Must templatize at commit.
- **Stash in "free-looking" RAM `$ddf0`/`$ddfe`/`$de36`** → all three are inside
  the combatant struct array → corrupted enemy stats / status / damage. The
  literal-reference free-RAM scan is BLIND to base+offset arrays. `$db86`
  (a scalar `ds` gap) was the safe choice.
- **Per-combatant stash array indexed by `wBattleAttackerIdx` at dispatch** →
  `wBattleAttackerIdx` is repurposed during target processing, so it reads the
  wrong slot at effect time. The `$db8a==0` guard sidesteps the whole index
  question.

## 6. How to add the NEXT custom skill (foundation is built)

For a damage-variant like Smite: add a `CustomSkillTable52` entry pointing to a
new handler (crib `NovelEffect52`), a `SkillNamePtrTable` name, extend
`AliasCommit`/`FarSkillFork`'s `cp` range, and assign the id in bank `$14`.

For a NON-damage skill (e.g. "Tame" = recruitment, "Anchor" = warp): same, but
(a) pick the right **template** to alias for presentation (e.g. an escape/return
spell for Anchor so the animation/targeting fit), and (b) the custom handler
calls the taming/warp routine instead of damage. The template controls
presentation; the handler controls effect. If different skills need different
templates, `AliasCommit` must map id→template (a small table) instead of always
→ Blaze(0), and the `$db8a==0` guard must be revisited (a non-Blaze template is
non-zero, which actually makes the guard cleaner).
