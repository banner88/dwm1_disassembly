# Battle Skill System: presentation foundation + custom-skill alias framework

Reverse-engineering of the DWM (GBC) battle skill system. Two layers:

1. **The skill PRESENTATION foundation** (§7–§9 below, the bulk of the current
   knowledge): the per-skill RECORD table (parameters), the item-effect/meat
   system, and the animation/effect dispatch. This is *discovery + a byte-exact
   round-trip keystone* — no ROM byte changes; the clean build stays
   `1ca6579359f21d8e27b446f865bf6b83`.
2. **The skill-alias framework** (§1–§6): the S45 proof-of-concept that adds
   net-new skill ids ($DE "Scorch", $DF "Smite") by masquerading them as Blaze.

> **S2 is an ARC, not a single done item.** S45 shipped a single-caster,
> Blaze-shaped alias POC (correct, but narrow — see KNOWN LIMITATIONS). The real
> "custom skills" subsystem (all skills editable, animations, item-outcomes,
> novel mechanics) is being built on the presentation foundation below. See
> ROADMAP "Phase F / S2-arc" for the sub-item status.

The S45 patched test ROM was md5 `6e8b8337805d020ca6cdbf878c21f1c6` (the
**patched** ROM, NOT the original).

---

## ⚠️ READ THIS FIRST — CONFIDENCE & UNCERTAINTY (do not trust at face value)

The S45 alias framework took **9 test iterations**; several confident claims
were WRONG and only caught by in-game testing. Treat anything marked INFERRED as
a hypothesis. The presentation-foundation fields marked **PROVEN** below are
either round-tripped byte-identical or FAQ-validated and are safe to rely on.

**PROVEN (round-trip + FAQ-validated, this session):**
- The per-skill **record table** geometry — `$54:$4013` pointer entries (dispatch
  entries 9–230) = `$41CF + id*19`, 222 records × 19 bytes. `build_skill_tables.py
  --selftest` re-emits both the pointer table and the data block **byte-identical**.
- Record field meanings +0,+1,+2,+3,+4,+5,+6,+11,+13,+15,+17 (see §7). +11/+13
  power min/range FAQ-validated **31/32** damage-heal ranges exact (the 1 miss is
  a likely FAQ typo on Explodet). +4 == MP cost 19/19.
- The handler table is the effect **TYPE** (shared: Blaze/Blazemore/Blazemost →
  one handler `$41CD`); the record carries the per-skill **parameters**.
- The 37 **item_effect** skills (ids 176–212) are the in-battle usable items;
  the **meat** items (194–198) special-case to a recruitment handler (§8).
- Animation/effect **dispatch**: descriptor-setters set `$dd6f`+`$dd70/71`; the
  selector packs **two message ids** (low=hit, high=miss) resolved by the bank-`$4c`
  text VM, while the **visual+sound are keyed by skill id** in `$5f`/`$55` (§9, S2c).

**VERIFIED in-game (S45, v9, user-confirmed):** $DE "Scorch" casts as Blaze
(~14 dmg, Blaze anim/msg, targets enemy); $DF "Smite" same but fixed 80 dmg;
basic attacks intact; menu shows the names. Final S45 architecture correct for
the single-custom-caster case.

**STILL INFERRED — re-check before relying:**
- **Combatant struct array `$dd80 + 26*k`** — deduced from base addresses only;
  the index math was never decoded. Writing `$ddf0/$ddfe/$de36` corrupted live
  battle state, so the region is OFF-LIMITS. `$dde8` is (probably) the enemy base.
- Record fields **+7/+8/+9** are flag bitfields (only individual bits observed);
  **+10** is a class flag (LOW). `$dd6f` bit meanings beyond bit7 (=has-effect)
  are partially observed, not exhaustively decoded.
- The effect-script **format** and its `$b000` backing are now **RESOLVED (S2c)**:
  the selector packs two message ids resolved via the mode-0 table at `$4c:$4019`;
  the visual/sound are id-keyed in `$5f`/`$55` (§9). `$dd6f` bits beyond bit7 are
  decoded in §9's consumer trace.
- `SaveBtlFX_43ff` bucket boundaries; `$c8dd`==`wBattleAttackerIdx`; `sm83dis.py`
  coverage — as before.

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
| Effect selector (Blaze `$b882` = hit id $82 / miss id $b8) | `$dd70`/`$dd71` |
| Skill function table (222 entries, `$4011..$41CC` = 444 B) | `$52:$4011` |
| Effect dispatch site (reads `$db8a`) | `$52:$6CC7` (hook at `$6CD5`) |
| SkillBlaze handler — **also the function table's hard upper bound** | `$52:$41CD` |
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

> **Superseded by §13.4** — presentation now works end-to-end (announce +
> animation + flash + SFX), so the recipe below (alias-era) is history. Use the
> §13.4 checklist. Kept for the alias-framework rationale.

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

---

# PRESENTATION FOUNDATION (the editable skill model)

The §1–§6 alias hack masquerades a custom id as Blaze because the presentation
layer was not yet understood. §7–§9 decode that layer. Core principle:

> **Handler = effect TYPE (shared); record = per-skill PARAMETERS.**
> The function table (`$52:$4011`) gives the effect handler, and same-effect
> skills share it (Blaze/Blazemore/Blazemost all → `$41CD`). Everything that
> makes them *differ* — damage, targeting, MP, message, AI weight — lives in the
> per-skill **record**. So most "edit a skill" operations are record edits with
> zero code change.
>
> **Extent (S59, verified against ROM + disassembly).** The table is exactly
> **222 entries × 2 B = 444 B, `$52:$4011..$41CC`**. It has no terminator: its
> upper bound is simply where the first handler starts — `SkillBlaze` @
> `$52:$41CD` (`CD FF 5B` = `call $5BFF`). Anything reading it as 256 entries
> runs 68 bytes into that handler and decodes CODE as pointers, yielding
> phantom ids 222–255 with blank names and bogus `$FFCD`/`$CD5B`/`$E7CD`
> "addresses" (`$CD` is the `call` opcode — the tell). This is exactly what the
> retired `extracted/skills.json` did; `skill_records.json` stops correctly at
> 221. Independently corroborated by `build_skill_tables.py --selftest`, which
> re-emits `SkillFunctionTable` and reports **444 bytes byte-identical**.

## 7. The skill RECORD table (`$54`) — per-skill parameters  [PROVEN]

**Geometry (round-tripped byte-identical).** `$54:$4001` is a 231-entry rst-`$10`
dispatch table; entries 0–8 are routines, **entries 9–230 are the 222 record
pointers** = `$41CF + id*19`, indexed as `$4013 + id*2` by the working id `$db8a`.
The record DATA (222 × 19 = 4218 bytes) begins at `$41CF`, right where the table
ends. The pointer table and the dispatch table share storage. Records are reached
as DATA via the `$4013` index, never executed.

The 4218-byte block at `$54:$41CF` is now re-sectioned in `bank_054.asm` to clean
`db` records, one per line, labelled `; [id] Name` — editable in source.
`tools/build_skill_tables.py --selftest` re-emits the pointer table + data block
byte-identical; `--emit record` / `--emit recordptr` print them.
`extracted/skill_records.json[*].battle_record` holds every record decoded.

**19-byte record field map** (codec in `tools/gen_skill_records.py`):

| Off | Field | Meaning | Conf |
|----|----|----|----|
| +0 | effect_class | fine effect/message id; shared by same-effect skills (Heal/Healmore=$18) | HIGH |
| +1 | effect_category | hi-nibble 1=damage 2=status/debuff 3=heal/buff 8=item | HIGH |
| +2 | target_mode | $11=1 foe, $12=all foes, $21=1 ally, $22=all allies, $31/$41=special. Cached→`$dcfc`, read by AI & anim. FAQ-Range-validated | PROVEN |
| +3 | ai_weight | per-skill AI score; enemy AI (`$57 Jump_057_7529`) SUMS record[+3] over its skill list into `$dce4` → weighted pick (Sacrifice/MegaMagic=0). The per-skill AI lever | HIGH |
| +4 | mp_cost_byte | byte copy of MP cost (`$07` table); 19/19 match | PROVEN |
| +5 | status_id | status/secondary-effect id; groups by effect (Sleep fam=$08, Poison=$13, Slow=$0e, instant-death=$09) | PROVEN |
| +6 | damage_class | $00=non-damage, $04=spell-damage, $05=breath-damage (FireAir/Scorching breath=$05 vs Blaze spell=$04). Element itself is chosen in the handler | PROVEN |
| +7 | flags7 | presentation bitfield (cached `$dcfd`; bit3→guard/skip in bank $53) | MED |
| +8 | flags8 | anim/message bitfield (cached `$dcfe`; bit4→message variant $67/$68) | MED |
| +9 | flags9 | cast-behaviour bitfield (cached `$dcff`; bit5→special cast substate) | MED |
| +10 | field10 | small class flag (read, compared ==1 in a build loop) | LOW |
| +11 | power_party_min | damage/heal MINIMUM, party-side caster | PROVEN |
| +13 | power_party_range | range; **max = min + range** | PROVEN |
| +15 | power_enemy_min | minimum, enemy-side caster | PROVEN |
| +17 | power_enemy_range | range, enemy | PROVEN |

**Side selection:** the caster's side picks the power pair — `StoreDamageResult`
(`$52`) and dispatch entry 5 (`$54:$535F`) test `wBattleAttackerIdx` bit2 → +11
(party caster) or +15 (enemy caster). That's why player Blaze (12–15) hits harder
than enemy Blaze (7–12). FAQ proof: Blaze 12-15 = min 12/range 3, Blazemore 70-90,
Heal 30-40, … 31/32 exact (Explodet ROM 130-150 vs likely FAQ typo 130-140).

**Key reader routines** (annotated in `bank_054.asm`):
- `LoadB54_5249` (entry 0, `ld hl,$5400/rst $10`) — generic field reader: in
  `$db4c`=index, `$db4e`=offset → bc = record word. 28 call sites.
- `LoadB54_526e` (entry 1) — same + also loads offset+2 (read a field then its
  neighbour, e.g. power +11 then aux +13).
- `CacheSkillRecordFields_5298` (entry 2) — caches rec[+2,+7,+8,+9] → `$dcfc–$dcff`.
- `SkillMagnitudeBySide` (entry 5, `$535F`) — side-selected power read.

## 8. Item-effect & meat system (#3)  [PROVEN structure]

The 37 **item_effect** skills (ids `$b0`–`$d4` / 176–212) ARE the in-battle
usable items: HERB, POTION, the stat SEEDs, the MEATs, staves, books. They share
the generic handler `$52:$4625` (`SkillPoisonHit_StepGuard_Whistle_Attack`),
which applies the record's effect via `CalcDefenseWrapper $519a → CalcSkillDefense
$60d7`. The outcome (heal amount, cure, stat boost) is **record-driven** — e.g.
HERB power 30 = heal amount, POTION 20, HEALWATER 60.

**Meat items** (ids `$c2`–`$c6` / 194–198 = FEEDMEAT, BEFFJERKY, PORKCHOP,
BADMEAT, SIRLOIN) are special-cased: `cp $c2 / cp $c7` at `$52:$4014` routes them
to the meat-feeding/recruitment handler **`$58:$591E`** (dispatch entry 9), which
computes the recruitment result (`call $5c0b`) and sets a result message from the
table at `$58:$5937`. (`$52:$4625` and the meat branch are annotated.)

**Authoring an item-outcome skill:** heal/cure/seed shapes → new id + record +
handler `$4625` (no new code). Novel outcomes (meat/recruitment, granting an
inventory item) → a custom handler (free bank, crib `NovelEffect52`) that calls
the relevant routine (`$58:$591E`-style recruitment, or an inventory-grant).

## 9. Skill effect MESSAGES (resolved) + animation dispatch (located)  [S2c, 2026-06-28]

> **Scope of what S2c proved — read this so the status is not over-read.**
> **RESOLVED & validated:** the effect-*message* format. The descriptor selector is a
> packed `(hit msg id, miss msg id)` pair resolved through the bank-`$4c` text VM; one
> effect decoded to bytes (Blaze) and **67/67** statically-resolved skills (across the
> damage, death, sleep, sap, MP-steal, slow, stop-spell and surround classes, plus the
> `$b682` physical-attack default) cross-checked against the categorized skill FAQ
> (`extracted/skill_faq.json`), **0 contradictions**. **LOCATED but NOT reversed:** the on-screen *animation* format. The full
> dispatch is mapped (skill id → `$5f:$58dd/$59c3/$5aa9` anim-index → `$5f:$58bd` routine
> → the routine sets `$dd68` = animation-type) — see "Visual + sound" below — but the
> low-level renderer that *consumes* `$dd68` (the frame/OAM/tile/palette engine) and the
> animation *data* format are **not** decoded. So **reusing** an existing animation on a
> new skill id is a table edit (set its `$58dd/$59c3/$5aa9` slots); **authoring a novel
> animation** still requires reversing the `$dd68` renderer (tracked as an open item).
> **UPDATE (S2c-anim, 2026-06-28): the `$dd68` renderer IS now reversed and emulator-verified — see §11.** It is a metasprite/OAM engine using the same 4-byte format as the follower system. The "reuse vs author" split still holds, but authoring is no longer blocked on an unknown renderer.

**Animation is chosen by the HANDLER, not the record.** Each handler ends by
calling one of ~12 **descriptor-setters** (`$52:$5460–$54f8`, annotated) that set a
16-bit **effect descriptor**:
- `$dd6f` — effect-class bitfield. Blaze=`$a8`; family is
  `$80/$84/$88/$90/$93/$98/$a0/$a8/$d0`, plus `$40`=flag-only.
- `$dd70` = **low** byte of the selector; `$dd71` = **high** byte. Blaze's
  `SetHLBattle_54e7` hardcodes `$b882`.

### The selector is NOT a pointer — it packs two MESSAGE ids  ⚠️ corrects prior model
The earlier note ("`$dd70/71` is an effect-SCRIPT pointer into a `$b000` region; the
bank-`$4c` interpreter is novel bytecode, animation-authoring") was **wrong**. The
truth, byte-verified end to end:

- The selector value `$b882` is **`(low=$82, high=$b8)` = two 8-bit message ids**:
  **low = the "effect happens" message** (damage / status / heal), **high = the
  "effect fails" message** (miss / resisted / no-effect).
- Bank `$4c` is the shared **text/message VM**, not a bespoke effect interpreter.
- The on-screen **visual animation and the sound are SEPARATE systems keyed by
  skill id** (`$db8a`), *not* by this selector (see "Visual + sound" below). That is
  why Blaze/Firebal/IceBolt all share selector `$b882` yet look different.

### Flow / consumer (`bank_053` `jr_053_5a6f`, a frame-stepped state machine)
Reads `$dd6f`. For the common **bit6-clear** path (Blaze `$a8` etc.): bit5 recomputes
bit4 from the damage `$db56/57`; when the hit lands it plays sound (`$55` entry 1) +
visual (`$5f` entry 6), then renders the **low-byte** message; on a miss it renders
the **high-byte** message. Each render does `$c822 = mode (0, or 1 if `$dd6f` bit0/1)`,
`$c823 = the chosen id byte`, then `ld hl,$4c00 / rst $10` → **bank `$4c` entry 0**
(`LoadB4c_42d1`). (A separate **bit6-set** path — `$d0`/`$c0` descriptors — instead
hands the raw `(mode=low, high=id)` straight through.)

### Message resolution (two-level table — the "`$b000` backing")
`LoadB4c_42d1` does `ld de,$4009 / call CallTextEngine`. The shared VM
(`CallTextEngine` `$00:$05B6` → `SaveBankAndSwitch` `$00:$092F`) resolves the string:
```
subtable = [ $4c : $4009 + mode*2 ]      ; mode 0 -> $4019  (the battle-MESSAGE table)
string   = [ $4c : subtable + id*2 ]     ; id = the chosen selector byte
```
`$4009` is just dispatch entry 4, so the "modes" are dispatch entries 4,5,6…; **mode 0
= `$4019` is the battle-message pointer table** (8-bit id → string ptr, 203 live ids).

### Effect-script format = standard text-VM strings
A resolved "effect script" is a normal `$F0`-terminated text section: charmap glyphs,
DTE pairs ($65–$7F), and control codes. Battle-relevant codes (handlers in bank `$56`):
`$F9 <slot>` insert variable (`$00`=target name, `$10`=number), `$FC` name-with-icon,
`$ED`/`$EC` monster/name, `$F1` reposition (wrap), `$F2` clear+reposition, `$F0` end.
High ids are **mid-string entry points** into shared runs (a real DWM feature).

### Worked example (accept test) — Blaze `$b882` decoded to bytes
```
hit  id $82 → $4c:529f  "{mon}{name} takes {num} damage pts!"
     ED F9 00 62 51 3E 48 42 50 F1 F9 10 62 41 3E 4A 3E 44 42 62 4D 51 50 63 EC F0
miss id $b8 → $4c:5871  "Has no effect on {name}!"
     2B 3E 50 62 4B 4C 62 42 43 43 42 40 51 F1 4C 4B 62 F9 00 63 EC F0
```
Other verified pairs: default `$b682` (hit "takes…", miss "Misses!"), heal `$bb84`
("wound heals!" / "But nothing happens!"), sleep `$bccc` ("sent to sleep!" /
"doesn't fall asleep!"), death `$b8e8` ("is finished!"). `$b0b0/$b2b2/$b5b5/$9191…`
(low==high) are **`a:a` flag-params, not selectors**; `$dbXX/$dcXX` loads are
battle-RAM pointers — the decoder classifies these and never renders them as text.

### Visual + sound (the real "animation", keyed by skill id — NOT the selector)
- **Visual dispatch (mapped)**: bank `$5f` entry 6 (`$5f:$52F0`) dispatches on skill id →
  an animation gate (Blaze id 0 → `$5f:$53A4`) → per-skill anim-index tables
  (`$5f:$58dd/$59c3/$5aa9`, indexed by id) → routine-pointer table `$5f:$58bd` (8 entries:
  `$5591/$559b/$55a7/$55b1/$55cd/$55d6/$55df/$55e8`). Blaze's anim-index is `0` → routine
  `$5f:$5591`, which sets `$dd68 = $01` (an **animation-type** byte) and falls to a shared tail.
- **Renderer (NOT reversed)**: whatever consumes `$dd68` to actually draw frames
  (OAM/tile/palette sequencing + the animation graphics source) was not traced. That is the
  remaining work for *authoring* a brand-new animation; the indices above only let you
  **reuse** one of the existing 8 routines.
- **Sound**: bank `$55` entry 1 (`$55:$4026` → `LoadB55_404a`) → per-skill SFX-id table
  at `$55:$4070`, indexed by id → `PlaySoundEffect`.

**To give a custom skill its presentation:** point its handler's descriptor-setter at the
`$bXXX` pair whose (hit, miss) messages you want **(fully actionable now)**, and set its
skill-id slots in the `$5f:$58dd/$59c3/$5aa9` anim-index + `$55:$4070` SFX tables to **reuse**
an existing animation/sound (id-indexed, so a net-new high id needs entries added — the usual
"high-table + forked loader"). A *novel* animation additionally needs the `$dd68` renderer
reversed (open). Selector, visual, and sound are independent.

**Validation (S2c):** Blaze decoded to bytes (above); `--validate` cross-checks the
decoded messages against the categorized FAQ — **67/67** statically-resolved skills match
(damage→"takes N damage"; Beat/Defeat/K.O.Dance→"is finished"; Sleep family→"sent to sleep";
Sap/Defence→"loses N defense"; RobMagic/RobDance→"MP drained"; Slow/SlowAll→"speed goes down";
StopSpell→"spells suspended"; Surround→"illusion engulfs"). The `$b682` default (71 entries =
28 physical-attack skills + 37 item-effects + 6 internal commands) is correct "takes N
damage / Misses!" for the physical attacks; for item-effects/internals it is the setter
fallback and the shown text comes from the item/command flow (§8), so it is **not** claimed
as their on-screen message.

**Tool / data:** `tools/decode_effect_messages.py` — `--selftest` (ROM anchors),
`--validate` (FAQ cross-check, 67/67), and default run writes
`extracted/effect_messages.json` (222 skills, 203 message ids, Blaze decoded to bytes,
descriptor-kind classification). Ground truth: `extracted/skill_faq.json` (built by
`tools/build_skill_faq.py`; effect/class/learn/prereq per skill — also feeds S2d).

## 11. Battle-effect PRESENTATION — the 3 layers (S2c-anim renderer reversed)  [2026-06-28]

> **This closes the §9 open item** ("the renderer that consumes `$dd68` … was not
> traced"). The renderer IS reversed, AND a load-bearing error in the §9 mental model
> is corrected here. Most of this section is **emulator-verified** (SameBoy
> breakpoints/watchpoints, this session); the few static-only parts are tagged.
>
> **Method note for the next session:** the *frame data* decoded statically held up
> perfectly under the emulator, but the *control flow* (which path drives what, on
> which axis, under which side condition) was wrong **four times** from static reading
> alone and was only settled by watchpoints. Treat any `[STATIC-ONLY]` claim below as a
> hypothesis until an emulator check confirms it.

### 11.0 The correction (what §9 and earlier got wrong)
A skill's on-screen presentation is **three independent systems**, not one. The §9
section correctly split *message* vs *visual+sound*, but the visual side was still
under-specified and two later guesses were outright wrong:

- `$c8a8` is **NOT** "screen shake" (a disassembly comment said so; it's wrong). It is an
  **effect-busy / input-suppress flag**. Damage-floor tiles set `$c8a8=$08` **and**
  `wBGPalette=$2d` — the visible effect is the **black palette flash**, not a shake.
  (Ground truth: damage tiles flash, don't shake. GATE_GENERATION.md's "screen-shake
  `$C8A8`" line is the same mislabel and should be read as "effect-busy flag".)
- `$c8b1`/`$c8b2` is a real rSCY/rSCX wobble routine in ROM0 (`$00:$056e–$05aa`) but
  **nothing ever sets it nonzero** — confirmed dormant by watchpoint (never fires).
- The real shake is **vertical only** (SCY), a different routine entirely (§11.3).

### 11.1 Layer 1 — SPRITE ANIMATION  [EMULATOR-VERIFIED]
The actual spell graphic. Driven by the per-skill **routine** path (NOT the `$da81`
command path, which is layer 2):

```
skill cast → $5f entry 6 ($5f:$52F0) visual dispatch
  → side-select table by attacker side ($c863 bit1, =0 in normal turns):
        party caster → $5f:$58dd[id]      (VERIFIED: HL=$58dd+id at the fetch)
        enemy caster → $5f:$59c3[id]
        special phase → $5f:$5aa9[id]      (gated by $d9ed==1 && $d9ee==5)
  → value = routine INDEX (0..$0d)
  → FuncFldUI_5441 ($5f:$5441): ld c,a; ld hl,$58bd; add hl,bc×2; call $0008 (JP [hl])
  → jumps to routine $5f:$58bd[index]
```
The 8+ routines at `$5f:$58bd` (`$5591 $559b $55a7 $55b1 $55cd $55d6 $55df $55e8 …`)
each set `$dd68` = an **animation-type** byte and set up the draw, OR are a bare `ret`.

**Index `$0d` → routine `$55cc` = `ret` = NO VISUAL.** This is the "no animation"
sentinel. (VERIFIED: HealMore reads `A=$0d`, the `JP [hl]` lands on `$55cc`, returns
drawing nothing — matches the in-game "healing sound, no animation".)

Verified per-skill indices (party-cast = `$58dd`):

| Skill | id | `$58dd` index | routine | result |
|---|---|---|---|---|
| Zap | `$10` | `$02` | `$55a7` (sets `$dd68=2`) | animates *(VERIFIED A=$02)* |
| Scorching / IceStorm | `$5e`/`$62` | `$01` | `$559b` (`$dd68=1`) | animates `[STATIC]` |
| MetalCut / EvilSlash | `$48`/`$40` | `$00` | `$5591` (`$dd68=1`) | animates `[STATIC]` |
| HealMore / Increase | `$2c`/`$1f` | `$0d` | `$55cc` = `ret` | **no visual** *(VERIFIED)* |

**Side-gating (VERIFIED):** `$5f:$5441` fires **per involved side** of an action (it
fired on the caster turn *and* when the enemy was hit). Each side reads its own table,
so an offensive skill animates on the caster side (`$58dd`) and is `$0d`/no-visual on the
target side (`$59c3`), and an ally-heal is the reverse. This is why "enemy offensive
skills don't animate on your party, but the enemy's own heal does."

### 11.2 Layer 1 renderer — the METASPRITE/OAM engine  [EMULATOR-VERIFIED]
The routine's `$dd68` animation-type selects a renderer bank; the renderer rebuilds OAM
every frame from a two-level frame table. **It is the same 4-byte metasprite format the
project already knows from the follower engine (GFX-3).**

```
animation command (layer-2 byte $da81, = $56ed[id] / $57d5[id]) → ROM0 dispatcher:
    < $0e  → bank $5c (builder $5c:$40fc)
   $0e..$20 → bank $5d (builder $5d:$4122)     ← Zap (cmd $10) VERIFIED here
    else   → bank $5e (builder $5e:$413a)
```
Each builder (called with `de = $4071`, the bank's frame-table base):
```
animation = [ $4071 + [$c7]*2 ]       ; $c7 = HRAM animation index (VERIFIED = $10 for Zap)
frame_ptr = [ animation + [$c8]*2 ]   ; $c8 = HRAM frame counter (VERIFIED advanced 00→01)
frame     = N × 4-byte OAM entries, $80-terminated:
    byte0 dy   → OAM Y    = dy + [$c5] + $10     (signed)
    byte1 dx   → OAM X    = dx + [$c3] + $08     (signed)
    byte2 tile → OAM tile = tile + [$c9]         (tile base, per-skill)
    byte3 attr → OAM attr = attr XOR [$ca]       (attr base; bit5 = X-flip)
loop bound: sprite counter [$cb] < $28 (40 = max OAM)   (VERIFIED: cp $28 at $4122)
```
HRAM live during a draw (read straight out of the Zap break): `$c3`/`$c5` = X/Y screen
base, `$c7` = animation, `$c8` = frame, `$c9`/`$ca` = tile/attr base, `$cb` = sprite count.
The frame counter struct (`$dd62/$dd63/.../$dd66`) is stepped by a generic bank-`$02`
timer routine via the pointer at `$d7b4/$d7b5`. `$dd66`→`$c8` each frame.

**Per-bank table shape `[STATIC-ONLY]`:** `$5c`'s top table is 14 distinct animations;
`$5d`/`$5e` begin with a run of repeated DEFAULT pointers (`$5d`→`$4173`, `$5e`→`$418b`)
for unused indices, then the distinct animations (`$5d` 19, `$5e` 12). Decoder handles
this; counts are "verified-decodable", not "proven-exhaustive". The *which-frame-plays-
when* playback (projectile motion via `$dd68` phase moving `$c3` across screen) is
decoded statically but only the frame-advance (`$c8` increment) is emulator-confirmed.

### 11.3 Layer 3 — SCREEN SHAKE (vertical)  [EMULATOR-VERIFIED]
A physical hit shakes the screen **up-down only (SCY)**. This is a *separate* effect
step-machine in bank `$5f`, **not** a skill-table entry and **not** `$c8a8`/`$c8b1`:

```
$50:$60b9 (battle main)
  → $52:$6c56 (effect-step dispatcher; reads done-flag $da82, dispatches by $d9ed)
    → $5f:$4c0c  THE SHAKE ROUTINE
```
`$5f:$4c0c` is a `rst $00` step-machine driven by counter **`$da84`** through a jump
table (`$4c15 $4c2f $4c15 $4c3a`):
```
step0 → ld a,$02; ldh [$bb],a   ; SCY = +2  (screen jolts DOWN)   ldh [$b7],a = 0
step1 → SCY = 0
…
step3 ($4c3a) → ld a,$01; ld [$da82],a (done) ; xor a; ldh [$bb]; ldh [$b7] (reset scroll 0)
              ; xor a; ld [$da84],a (reset step)
```
Hardware path: HRAM `$bb` (SCY source) → `$00:$122c` copies it to `rSCY`. The battle
scroll uses HRAM `$b7`(SCX)/`$bb`(SCY) directly — **NOT** the `$c991/$c992` scroll
shadow (watchpoints on the shadow never fired; this is why the shadow was a dead end).
Fires on *any* physical hit (attacker or target). A sibling SCX (horizontal) oscillation
exists at `$5f:$51dd` (`-2,+2,-4,+4,-8,+8…` written to `$b7`) — a *different* effect, not
the hit-shake. `$da84`/`$da85` are written **only** in bank `$5f` (effect-only; quiet
outside battle — the clean watch target).

### 11.4 Layer 2 — SOUND + screen-FLASH  (recap, keyed by `$56ed`/`$57d5` → `$da81`)
The `$56ed[id]`/`$57d5[id]` → `$da81` command path (§9 "Visual + sound" / the `$5c/$5d/$5e`
dispatch on `$da81`) drives **sound and screen-flash/blink**, side-selected like layer 1:
- offensive skills (`$11/$12`): real cmd in `$56ed`, `$ff` in `$57d5`
- ally skills (`$21/$22`): `$ff` in `$56ed`, real cmd in `$57d5`
- `$ff` in both = no layer-2 effect.
Examples: HealMore `$57d5=$14` = the heal **chime** (the sound you hear with no visual);
TatsuCall (`$84`) = `$ff` both → no sprite, but routine `$55cd`→`$4a60`→`$4b0b` sets
`$da83=$04` = the **rapid screen blink** (Tatsu itself is never drawn — it appears via the
combatant-display system). BeDragon (`$d5`) `$57d5=$18` = the transform animation (whitelisted
to force the `$57d5` path on its own side). Summons (`*Call` `$84-$87`) = `$ff`/`$ff` = no
effect animation.

### 11.5 Tools / data
`tools/decode_battle_animations.py` — decodes the `$5c/$5d/$5e` two-level frame tables to
metasprites + the per-skill `$5f` descriptor tables. `--selftest` (ROM anchors),
`--dump` (every frame), default writes `extracted/battle_animations.json` (45 distinct
animations across 3 banks, ~600 frames, + 222 per-skill descriptors).

**Disassembly-cleanup status (NOT yet applied — see DOC_AUDIT #15):** the `$5f` tables
`$56ed`/`$57d5` (anim commands), `$58bd` (routine ptrs), `$58dd`/`$59c3`/`$5aa9` (anim
indices, 230 B each) currently mis-disassemble as instructions. `tools/emit_anim_data_sections.py`
emits byte-exact `db`/`dw` for them, BUT this span overlaps mgbdis-auto `Map*_Script*`
labels in bank `$5f` (some bogus — e.g. `Map5A_Script02/03` sit on anim padding — some
possibly real map-cutscene scripts not yet traced). **Converting safely first requires
reversing the `$5f` map-script accessors to settle the boundaries.** Until then the regions
are left as-is and documented here; the live code + watchpoints (not the labels) are the
truth for the anim tables. Same caveat applies to the `$5c/$5d/$5e` frame tables (code/data
interleaved at `$4071`+).

### 11.6 Quick-reference (layer addresses)

| Thing | Address |
|---|---|
| Visual dispatch (entry 6) | `$5f:$52F0` |
| Side-select tables (by skill id) | `$5f:$58dd` (party) / `$59c3` (enemy) / `$5aa9` (special) |
| Routine-index → routine dispatch | `FuncFldUI_5441` `$5f:$5441` (`JP [hl]` via `$00:$0008`) |
| Animation routine table (8+) | `$5f:$58bd` |
| **No-visual sentinel** | index `$0d` → `$5f:$55cc` = `ret` |
| Metasprite/OAM builders | `$5c:$40fc` / `$5d:$4122` / `$5e:$413a` (de=`$4071`) |
| Frame-table base (per bank) | `$4071` → `[$c7]` anim → `[$c8]` frame → 4B `dy,dx,tile,attr` $80-term |
| Anim/frame HRAM | `$c7` anim · `$c8` frame · `$c3/$c5` X/Y base · `$c9/$ca` tile/attr base · `$cb` OAM count |
| Frame counter struct / stepper | `$dd62..$dd66` ; bank-`$02` timer via `$d7b4/5` |
| **Screen shake (vertical, SCY)** | `$5f:$4c0c` (step ctr `$da84`, done-flag `$da82`) → HRAM `$bb` |
| Shake hardware copy | `$00:$122c` (`$b7`→rSCX, `$bb`→rSCY) |
| Effect-step dispatcher | `$52:$6c56` (dispatch by `$d9ed`) |
| Effect-busy / input-lock (NOT shake) | `$c8a8` |
| Dormant ROM0 wobble (never triggered) | `$00:$056e–$05aa` (`$c8b1/$c8b2`) |
| Sound (layer 2) | `$55:$4026` → `$55:$4070[id]` SFX table |
| Screen-blink (TatsuCall etc.) | `$da83` (set by `$5f:$4b0b`) |

## 10. Updated address quick-reference (additions to §4)

| Thing | Address |
|---|---|
| Record pointer table (dispatch entries 9–230) | `$54:$4013` = `$41CF + id*19` |
| Record data (222 × 19B), re-sectioned to `db` | `$54:$41CF` |
| Generic record field reader (idx `$db4c`, off `$db4e`) | `LoadB54_5249` (`$54` entry 0) |
| Record field cache → `$dcfc–$dcff` | `CacheSkillRecordFields_5298` (`$54` entry 2) |
| Side-selected power read | `SkillMagnitudeBySide` `$54:$535F` |
| Damage/heal applier (record-driven) | `StoreDamageResult`/`CalcSkillDefense $60d7` (`$52`) |
| Item-effect handler (ids 176–212) | `$52:$4625` |
| Meat branch (ids $c2–$c6) → recruitment | `$52:$4014` → `$58:$591E` |
| Descriptor-setter family | `$52:$5460–$54f8` |
| Effect descriptor / message-id selector | `$dd6f` / `$dd70`–`$dd71` |
| Message VM / visual-anim / sound | bank `$4c` e0 (msg) + `$5f` e6 (`$52F0`, visual) + `$55` e1 (sound) |
| Battle-message table (mode 0) | `$4c:$4019` (8-bit id → string) |
| FX router (id-range split) | `SaveBtlFX_43ff` `$58:$43FF` |

**Tools:** `tools/gen_skill_records.py` (decodes records → JSON, 7 ROM sources
incl. battle_record), `tools/build_skill_tables.py` (round-trips function/MP/learn
+ record ptr/data; `--selftest`, `--emit {func,mp,learn,record,recordptr}`).

---

### 11.7 Message/animation TIMING gate, hit-flash, and the enemy-blink (mechanism SOLVED S52, implementation deferred)  [S50/S2e + S52, emulator-tested]
Reversed while sequencing Tame's beats (heart → then damage). All user-confirmed except the last.

**Message-vs-animation timing gate — `$53:$5b07`.** In the effect state machine's bit6-clear
(damage) path (`jr_053_5a6f`→`$5ab4`), the message step WAITS for the animation done-flag
`$da82` **only when the skill id is `$84`–`$87`** (summon/TatsuCall-type). Every other id (incl.
custom `$E1`) SKIPS the wait, so "takes X damage" fires the instant the hit lands, on top of a
brief animation. (`ld a,[$db8a]; cp $84; jr c,skip; cp $88; jr nc,skip; ld a,[$da82]; or a;
ret z`.) `$5b07` is a `jr` target ($5b17's address must hold); forked byte-neutrally
(`jp TameGateHook`, pool `$53:$6c6a`).
- **Gating Tame on `$da82` did NOT fix it** — the note's done-flag fires EARLY (before the note
  visually finishes). Working fix = a **FIXED FRAME DELAY**: `wTameDelay` (`$D488`) inits to 40
  in SkillTame; TameGateHook `ret`s (waits) each frame until it drains, so the heart plays fully
  before the message. Same ret-and-re-enter mechanism the $84–$87 gate uses (proven safe).

**Damage sound = bank `$55` entry 1 (`$5501`@`$5add`) + entry 2 (`$5502`@`$5afa`)** — both fire
EARLY (with the animation). Tame suppresses both for its id (`TameSound1Hook`/`TameSound2Hook`
fork `$5add`/`$5afa`, byte-neutral jp+nop: skip the `rst` for $E1 else play it) and re-fires the
sound near the end of the delay (8 frames left) so it lands with the text.

**Hit-FLASH = `wBGPalette`** (`$c89b` BGP / `$c89c` OBP0 / `$c89d` OBP1). The game's white flash
sets these to `$00` (all-light) and restores the battle palette (`$d2/$d2/$e2`); bank `$5f`
drives it. Setting all three flashes the WHOLE SCREEN. `$da83=$04` (set by `$5f:$4b0b`, which
also clears `$da82`–`$da87`) is a separate screen blink (TatsuCall), not per-enemy.

**SOLVED (mechanism) — per-enemy hit-blink; implementation DEFERRED** [S52, HW-confirmed
via `$9929` tilemap watchpoint captures; user: "bank it"].
- **The old premise here was WRONG:** the battle enemy is **BG-DRAWN, not OBJ**. Enemy tile
  data is composed in the `$c500` buffer and written to the BG map by `LoadBtl_7627`
  (`$50:$7627` → `BtlFunc_7656`, three enemy slots at BG columns `$25/$2b/$31`); the OBJ/OAM
  layer holds the EFFECT metasprites (heart, fireballs — compositor `$5c:$40fc`, `$80`-term
  entries, position base `hFFC3/hFFC5`). Three fix attempts failed by targeting layers the
  enemy doesn't use: OBP0/1 flash (S50 — enemy isn't OBJ), whole-BGP flash (S52 — that IS the
  PLAYER-hit whole-screen flash, user-identified on sight), `$ffc3` bump (that's the
  PLAYER-hit screen shake, ticked by banks `$5c/$5d/$5e` entry 0 on `$dd60/$dd62/$dd65/
  $dd66/$dd68` state).
- **The actual blink = a TILEMAP TOGGLE** inside the layer-2 animation machine, bank `$5f`
  **entry 5** (`$4b1b`; far-called `ld hl,$5f05; rst $10` from `$52:$6c56`): global 5-frame
  divider `$da34`, done-flag `$da82`, phase dispatch `rst $00` on **`$da83`** (ptr table
  `$4b28`), and within the blink phase a sub-dispatch on **`$da84`** at `$4b99`
  (ptrs: `$4ba5` = BLANK frame, `$4bcb` = ENEMY frame, `$4bf4` = finish→`$da82=1`).
  Both frame routines resolve tile sources via `$50f4` (table lookup `[hl+2A]`; enemy src
  table `$50ff`, blank src table `$5109`) and write the enemy's BG cells with the VRAM-safe
  copy at **`$4e1f`** (DI/STAT-wait/EI per byte — the `$9929` cell alternates `$14`⇄`$e0`).
  Captured backtrace: `$5f:$4e2a ← $5f:$4bc3/$4bec ← $52:$6c56 ← $50:$60b9`.
- **Implementation plan (1–2 SameBoy iterations expected):** from `TameGateHook`'s per-frame
  delay, arm the machine (`$da82=0`, `$da83=<blink phase>`, `$da84=0`, `$da34` divider) at the
  hit beat and let the existing entry-5 tick run the toggle; or trampoline the two frame
  routines directly. `wTameBGSave` (`$d489`, 3 bytes) is reserved and free for this state.
  Deferred to its own session / editor animation support (ROADMAP optional-polish box).

---

## 12. Skill-ID bucketing audit & de-aliasing surface (S2d FOUNDATION)  [S48, 2026-06-28]

**Why this section exists.** S45 added custom skill ids ($DE/$DF) by *aliasing*
them to Blaze at commit time, precisely to AVOID enumerating where the engine
buckets the skill id. The "proper" S2d (own record/handler/name, no alias) needs
that enumeration. This section is it — the `$db8a` analog of the species-slot map.
Tool: `tools/map_skill_id_buckets.py` → `extracted/skill_id_bucket_map.json`
(self-checking, aborts on ROM drift). Everything below is ROM-grounded; the
hardware lines are from a SameBoy session.

### 12.1 Geography
Real skills are `$00–$DD` (222 records). Custom budget is `$DE–$FF`. The working
id lives at **`$db8a`** (authoritative — never reused). The record-lookup index
**`$db4c`** is re-derived from `$db8a` but is ALSO reused as scratch inside
routines, so its low-threshold gates (`cp $02/$03/$04`) are NOT skill-id gates.
High-id specials: `$D5` BeDragon, `$D9` GigaSlash, `$DA` LIFE, `$DB` RUN (flee
*skill*, not the menu command), `$DC` IRONIZE, `$DD` Ahhh. **Avoid id `$E1`** —
`$50:$6BC4` routes `$db4c==$e1` to a menu pseudo-action.

### 12.2 The surface reduces to a small fork set
`$db8a` is read at **254 sites across 9 banks** ($00/$50/$52/$53/$54/$55/$57/$58/
$5f); bank `$57` (enemy AI) alone holds 148. But the surface is bounded:

- **204 equality checks** vs specific ids; the highest value compared is `$C5`,
  so a custom id (`≥ $DE`) matches NONE → auto-safe (asserted as an invariant).
- **15 range gates** (`cp X; jr c/nc`): all are windowed equality ladders; a
  custom id falls through to the default, and NONE routes it into a table index.
- **Enemy AI `$57`** — all 148 reads classified exhaustively: 138 equality (max
  `$95`), 5 windowed range ladders, 3 shared-`$54`-reader setups, and one `rst $00`
  sub-dispatch at `$57:$4C50` **guarded by `cp $d9; ret nc`** so every custom id
  returns before reaching it. **Zero** of the 148 mishandle a custom id. The AI's
  record reads use the shared `$54` reader, so the record fork covers the AI.

### 12.3 The cast pipeline (production → consumption)
**Production.** Menu real id at `$caea` (name). On commit at **`$50:~$4A55`**:
`ld a,[hl]; ld [$db4c],a; ld [$db8a],a; ld [$db4f],a`, then the action is queued at
`$dcec` and `$db8a` is re-derived from it at resolution. The FX router (`$58`) and
multi-hit code (`$52`) re-set `$db8a` for sub-effects (most of the 35 write sites).
**De-alias point = this commit:** S45's `AliasCommit` forces the queued value to
`$00` for `$DE/$DF`; S2d must NOT templatize and let the real id flow.

**Consumption (every id-keyed subsystem):**

| Subsystem | Indexer | Custom-id behavior | Fork |
|---|---|---|---|
| **Record table** `$54:$4013` | entries 0/1/2 (`$5251/$5276/$529E`), `ld hl,$4013; add hl,bc;×2` | overshoot | **KEYSTONE** (3 sites) |
| ↳ magnitude | `$52:$66D6 StoreDamageResult` → entry 1 | overshoot | (record fork) |
| ↳ targeting (+2) | entry 2 caches `record+2 → $dcfc`; `$dcfc` drives `and $01` target select | overshoot | (record fork) |
| ↳ status/dmg/ai_weight | +5/+6/+3 via shared readers | overshoot | (record fork) |
| ↳ entry 5 `$535F` | side-power; `cp $d5/jr nc $53a6` BAILS `≥$d6` | bails (minor path) | defer |
| **Function table** `$52:$4011` | `$52:$6CD5` dispatch | — | DONE (FarSkillFork) |
| **MP** `$07:$570C` | 3 readers `$56E8/$5A98/$5B4E`; `$570C+2*id` | overshoot | 3 sites |
| **Sound** `$55:$4070` | side-selected ptr table, indexed at `$55:$4067` | overshoot; `$FF`=silence | 1 site |
| **Anim** `$5f:$58dd` | `$5f:$5433`, `$58dd+id` | `$58dd[$DE]=$0d`=no-visual | none for no-visual skills |
| **Message** `$dd6f/$dd70` | handler-set descriptor (Heal: `$bb84`) | not id-indexed | none |
| **Name** `$41:$4539` | 256 entries | in range | repoint only |
| **Learn-req** `$06:$50E0` | species-keyed (`$06:$4FA5`), not cast-path | irrelevant to assigned skill | only if naturally learnable |

MP is **mirrored**: `$570C[id] == record+4` (verified) — set both (build_skill_tables.py does).

### 12.4 Keystone fork is byte-neutrally implementable [PROVEN]
The 3 indexer sites are the identical 5 bytes `21 13 40 09 09`. Replace each with
`call Fork` + `nop` + `nop` (`cd lo hi 00 00`, exactly 5 bytes, byte-neutral). No
interior branch targets land in any window; readers don't re-use `bc`. Bank `$54`
has ~10550 free trailing bytes, so the `Fork` routine **and** the high pointer
table + 19B custom records live IN-BANK (near `call`, no bankswitch). `Fork`:
`ld a,c; cp $DE; jr nc,.custom; ld hl,$4013; add hl,bc; add hl,bc; ret; .custom:
push bc; sub $DE; ld c,a; ld b,0; ld hl,HIGH_PTR; add hl,bc; add hl,bc; pop bc; ret`.
RGBDS-assembled and byte-executed: normal ids come out **vanilla-identical**
(`$2B`→`$4069`, `$00`→`$4013`), custom ids index the high table (`$DE`→base).

### 12.5 Hardware verification (SameBoy, 2026-06-28)
- **Record-index = skill id [CONFIRMED]** — bp `$52:$66D9` casting Scorching (`$5E`,
  handler `$4932`) writes `$db4c = $5E`; a custom id overshoots here.
- **`$535F` minor [CONFIRMED]** — bp `$54:$5362` did NOT fire for Scorching/Zap/
  IceStorm (`$5E/$10/$62`); the side-power reader is off the main damage path.
- **RUN correction** — bp `$52:$4E3A` did NOT fire on the menu Flee command; menu
  Flee ≠ skill `$DB`. High-id FUNCTION dispatch is proven by the shipped S45 patch.

### 12.6 S2d is shovel-ready
Fork the 3 record sites (+ in-bank high tables), MP (3 sites), sound (1 site),
name (repoint). A no-visual ally heal needs no anim/message/targeting patch
(those follow from the record). Authoring a *visible* custom animation is **SOLVED** via the GetPresentId
presentation proxy — see §13.2 (the whole anim/flash/SFX pipeline now works for
custom ids). §13 is the current end-to-end truth; skill #1 (MagicBurn) is live.

---

## 13. Custom-skill PRESENTATION — the working system  [S49, 2026-06-29, v32]

S2d shipped end-to-end for skill #1 **MagicBurn (`$E0`)**: a non-aliased custom
skill with its own record (½ current MP as damage to all foes), result text,
**announcement**, **animation**, **hit-flash**, and **cast sound** — all via
clean dynamic indirection, no per-aspect byte hacks. This supersedes the earlier
"presentation blocked on `$5f` cleanup" note (§12.6) and the standalone
groundwork doc (folded here). Empirically located via SameBoy (probe ROM, bp
`$4c:$42d1 if [$db8a]==<id>`): a normal cast renders msgs `$23`(announce) →
`$82`(damage) → `$e4` → `$ec`; `$E0` was missing `$23` only.

### 13.1 Announcement — per-skill template table + custom message pool
- **Lookup:** bank `$58` entry 6 (`$57C5`) sets `$db4c = [AnnounceTemplateTable + skill_id]`,
  where `AnnounceTemplateTable = $58:$5806` (256-wide, indexed by skill id). The
  renderer is `$50` entry 7 at `$50:$5A42` (`ld a,[$db4c]; ld [$c823],a; cp $ff;
  ret z; ld hl,$4c00; rst $10`). **`$db4c == $FF` ⇒ silent.** `$E0`'s slot
  (`$58:$58E6`) was `$FF` — the entire bug. The table is misdisassembled as code
  in `disassembly/`; the clean `db` form (label `AnnounceTemplateTable`, custom
  slot `AnnounceTpl_E0_MagicBurn`) is in `patches/bank_058.asm`.
- **Message text:** battle messages are an 8-bit id → pointer table at `$4c:$4019`
  (`subtable=[$4c:$4009]=$4019`; `string=[subtable+id*2]`) → `$F0`-terminated
  bytes in bank `$4c` (charset/codes in TEXT_SYSTEM.md). **The 256-id space is
  full**; the only empty slot was `$FD`. Custom announce text therefore lives in
  a **custom message pool** at `$4c:$7326` (~3290 free bytes after the last
  message at `$7325`); `$FD`'s pointer (`$4c:$4213`) is repointed there. MagicBurn's
  message (`CustomMsg_E0_MagicBurn`, 56 B) decodes to `{name} burns half its MP!
  {name}<slime>A huge burst of magic energy!` (`{name}`=caster, no skill-name
  insert — the custom-id name path is unfilled, so name-inserting templates like
  the generic "casts {skill}!" `$23` would garble for custom ids; see §13.4).

### 13.2 Animation + hit-flash + cast-SFX — the GetPresentId presentation proxy
- **One root cause for all three.** The on-screen animation is a **command
  script**: bank `$5f` selects a per-skill start command from tables at
  `$5f:$56ed` / `$5f:$57d5` (and entry-6 dispatch `$52F0` → anim-index
  `$5f:$58dd/$59c3/$5aa9` → routine table `$5f:$58bd`), all indexed by skill id
  `$db8a`; bank `$5f` entry 7 advances the script and sets `$da81` (command),
  which the renderers in `$5c`/`$5d`/`$5e` consume. The hit-flash and cast SFX
  are commands *within* that script. `$E0` overshoots the selection tables →
  garbage command → the script never emits "done" → `$52:$6c4d` spins on
  `$da82` forever (the hang) and nothing flashes/sounds.
- **Key enabling fact:** the renderers `$5c`/`$5d`/`$5e` read `$db8a` **zero
  times** — they are driven purely by the `$da81` command stream. ALL skill-id
  dependence is the **12 reads in bank `$5f`** (`$4a60 $4c02 $52d6 $52f0 $5382
  $5433 $544e $564e $565f $567f $56cb $56dc`).
- **The foundation (`GetPresentId`, in `$5f` free space, patches/bank_05f.asm):**
  a resolver returning the skill id unchanged for stock ids (`< $DE`) and a
  per-skill **proxy** id for custom ids (`>= $DE`, from `CustomProxyTable`
  indexed by `id-$DE`). All 12 reads are forked `ld a,[$db8a]` → `call
  GetPresentId` (byte-neutral, 3→3). A custom skill thus selects a *real* skill's
  whole script and plays it to completion → no hang, flash + SFX restored.
  MagicBurn's proxy = `$09` (Infernos); it animates/flashes/sounds identically.
  Stock skills are unaffected (resolver is the identity for `< $DE`).

### 13.3 Skill #1 file set (the complete working stack)
- `patches/bank_072.asm` (NEW) — far-call table + `CustomBattleExec`/`SkillMagicBurn` (effect).
- `patches/bank_054.asm` — record fork (`Fork54_RecordIndex`, `CustomRecord_E0`).
- `patches/bank_052.asm` — `CustomDispatch52` (runs `$52`-context result setup, far-calls `$72`).
- `patches/bank_041.asm` — `SkillName_224_MagicBurn` (menu name).
- `patches/bank_058.asm` — `AnnounceTemplateTable` clean db + `$E0`→`$FD`.
- `patches/bank_04c.asm` — `CustomMsg_E0_MagicBurn` in the pool + `$FD` repoint.
- `patches/bank_05f.asm` — `GetPresentId` + `CustomProxyTable`, 12 forked reads.
- `patches/bank_014.asm` — test-monster skill assignment (line 1468; currently `$E0`+`$09` Infernos for regression compare).
- All registered in `tools/verify_integrity.py` `PATCH_FILES`/`PATCH_NEW_FILES`. Integrity PASS 4/4, clean build byte-perfect `1ca6579…`.

### 13.4 How to add a custom skill (the repeatable recipe — skills #2–#12)
Each presentation layer is now a one-line edit; nothing is rebuilt:
1. **Effect:** add a record (`CustomRecordPtrTable`/`CustomRecord_*`) and, if the
   behavior isn't pure record-driven damage, a handler in the `$72` dispatch.
2. **Name:** `SkillNamePtrTable[id]` → a `SkillName_*` string (bank `$41`).
3. **Assignment:** give a monster the id in bank `$14`.
4. **Announce:** set `AnnounceTemplateTable[id]` (patches/bank_058.asm). Either
   reuse a **self-contained** stock template (no skill-name insert, e.g. `$40`
   "uses all magic powers!", `$3c` "calls down lightning!") or add a bespoke
   message to the pool at `$4c:$7326` and claim a slot. NOTE: only `$FD` is free
   in the stock id table; a 2nd+ bespoke message needs either a verified-unused
   id or a forked render — OR fix the custom-id **skill-name insert** so the
   generic "casts {skill}!" templates work with the real name (higher leverage;
   open follow-up).
5. **Animation/flash/SFX:** set `CustomProxyTable[id-$DE]` (patches/bank_05f.asm)
   to a stock skill whose presentation fits. (Unique custom animation = authoring
   a new script into the same indirection — a refinement, not a redo.)

**Open follow-ups (not blockers):** (a) custom-id skill-name insert for
name-inserting announce templates; (b) a 2nd bespoke-message render path beyond
`$FD`; (c) FIELD-cast skills (e.g. teleport) — a different code path the battle
foundation doesn't touch yet.

#### 13.4.1 S74 additions to the recipe (Earthquake-era techniques, all reusable)

Everything below is built, PyBoy-verified, USER-CONFIRMED, and designed to be
cribbed by the next skill. Deep dives live in §13.7.1–§13.7.11; this is the
index a future session should read FIRST.

- **No cast animation / custom presentation window:** point the anim-INDEX
  lookup at a quiet id via `GetAnimPresentId` (bank `$5f`): any id whose
  routine index is `$0D` in ALL THREE side tables (`$58dd/$59c3/$5aa9`;
  `$12` qualifies, HealMore `$2c` does NOT — side-B `$00`) renders NOTHING and
  completes instantly. Do NOT force `$da82` — the `$5F` driver also ticks the
  d9ee setup machine and starving it wedges the action (§13.7.10).
- **Presentation that must precede ALL per-target beats** (screen effects,
  charge-ups, multi-pulse anything) belongs in the CAST-ANIM SLOT
  (`d9ed==1 && d9ee==3`), held via the `$6c4d` 15-byte window + a bank-`$72`
  fork that reports E=0 until done. Rules: arm once (guard both vars — d9ee
  idle-cycles 1,2,3 under d9ed==0), keep the verdict STICKY until the machine
  leaves the state, and let the fork keep servicing the vanilla driver for
  non-custom ids. `QuakeAnimHold72`+`QuakeShakeSeq` are the template.
- **Multi-target sweeps** (all-foes, both-sides, conditional skips): the
  `$52:$719C` sweep window → `QuakeSweep72` (entry 3) + the first-target scan
  stand-in `QuakeFirstTgt53`. Per-target damage handlers key side-dependent
  math on `wQuakePhase`, NEVER on `$db88` (target-contaminated) — and the
  per-beat target var of record is **`$db89`** (proved by the damage math AND
  by the v4 `$db88` real-menu divergence).
- **Battle-winning multi-target actions:** the step-6 side-wiped check
  (`$7033 call $7782`) aborts iteration mid-sweep; gate it on your
  phase/state var (`QuakeVictGate52`, funded from the sweep window pad — and
  remember window pads are EXECUTED fall-through, `jr` over stashed code).
  The scheduler's second call (`$70bd`) lands victory/defeat one action later
  unconditionally.
- **Per-target outcome text:** 0-damage hits auto-route to miss messages
  `$B7/$B8`; intercept in `LoadB4c_Fork` keyed on (skill id, `$db89` side,
  target state) and render a pooled string through a 1-entry mode table
  (`LoadB4c_MaybeFlew` template). `F9 00` in the string = the current beat's
  subject name. Gate-inserted renders cap at TWO lines (18 chars each) — the
  `FC 10 EC F2` page-ender only works in engine-driven messages.
- **Per-beat damage sounds are free:** the vanilla `$5501/$5502` sites ding
  damaged beats and stay silent on 0-damage beats. Only suppress+refire
  (Tame-style) if a looping SE would otherwise pin the `$dd80` handshake —
  and delete the compensation the moment the loop is gone (§13.7.11).
- **Looping SFX** (rumbles, drones): queue via `$c8b8`; ANY new SE replaces a
  looping one, so a one-byte SFX-`$00` write is a universal stopper. Screen
  shake = `$c8b1` (SCY wobble counter, no vanilla writers; ~16 frames reads
  as one distinct jolt).
- **Tiered skill chains:** learn levels + prereq-EVOLVE rows in
  `CustomLearnReqTable2` (bank `$06`); the same level gates CAST-time
  validity (below-level actors get vanilla msg `$1D` — enforced per actor).
- **SKIL-menu descriptions:** repoint the bank-`$56` desc-table rows off the
  `$664a` empty string and pool 3-line strings from the trailing nop pad
  (§13.7 v2; `SkillDescPtr_E5..E8` are the pattern).
- **Species-conditional targeting** (flying, and by extension any species
  flag): battle-side per-slot flags at `$db8b[slot]` (bit 4 = flying); the
  ROM species source + all offsets are exported in
  `extracted/flying_flags.json` (`tools/dump_flying_flags.py`).

### 13.5 Custom skill #2 — Tame (`$E1`): reusable custom-message fork + note-then-hit timing  [S50/S2e, 2026-06-30, USER-CONFIRMED in SameBoy]
Skill #2 = **Tame** (`$E1`): recruit (meat-meter) + small anti-abuse damage, single-target.
Announce, heart animation, sound timing, damage, and recruitment are all confirmed correct;
only the per-enemy-sprite blink is deferred (§11.7). This resolves §13.4 open follow-up (b).

**(A) Reusable custom-message render fork (`$FD` → per-skill pool string).** Message id `$FD`
is now a general **custom-message escape**, not a one-skill slot (the stock `$4c:$4019` table is
full — TEXT_SYSTEM.md). `LoadB4c_42d1` (`$4c:$42d1`, bank $4c entry 0) head is replaced
byte-neutrally (`jp LoadB4c_Fork` + 15 nop) with a fork in the pool (`$4c:$735e`):
- id `$FD` → `id=[$db8a]-$DE`, mode 0, `de=CustomMsgModeTable`, `call CallTextEngine`
  (`$00:$05b6`, the SAME two-level resolver). Guard `$db8a<$DE` (stock emitting $FD) → vanilla
  `$4019[$FD]`. All non-$FD ids byte-identical to vanilla.
- `CustomMsgModeTable: dw CustomMsgPtrTable`; `CustomMsgPtrTable: dw dummy,dummy,
  CustomMsg_E0_MagicBurn,CustomMsg_E1_Tame` (index = id-$DE → $E0=idx2, $E1=idx3).
- `CustomMsg_E1_Tame` = "{caster} used Tame!" = `ED F9 00 62 52 50 42 41 62 37 3E 4A 42 63 EC F0`.
- **MagicBurn (`$E0`) migrated onto the fork** (idx2 → its existing 56-B string); its old fixed
  `$4019[$FD]` repoint is now dead but harmless. Scales: each skill = one table entry + one pool
  string. All in `patches/bank_04c.asm`; `AnnounceTemplateTable[$E1]=$FD` (bank_058) drives it.

**(B) The 4-beat presentation, and how each beat was achieved.** Target: "used Tame!" box →
heart plays → then the enemy takes damage (sound + text). The heart and the hit-flash are the
SAME layer-2 command channel and CANNOT share one presentation (§11.7), so a **fixed delay +
sound-move** in the effect state machine sequences them **without a second animation beat**
(the "two-beat replay" surgery was explored and deliberately AVOIDED — bank $52 is full and it
touches shared code):
- Beat 1 announce: `AnnounceTemplateTable[$E1]=$FD` → CustomMsg_E1_Tame.
- Beat 2 heart: `CustomProxyTable[$E1]=$c2` (meat/heart; `$56ed[$c2]=$2c` note command).
- Beats 3/4 sound+text: effect state machine forked (`TameGateHook`, §11.7) to hold the message
  a fixed number of frames (heart plays first) and to move the damage sound onto the text.
- Damage: `SkillTame` (`$72`) = **ATK/4** (was ATK/2 — ATK/2 equalled a normal attack, so the
  anti-abuse hit must be weaker). Meter += `TameMeterTable[id-$E1]` since S52 (crank
  reverted; §13.6 — the old "$000A = Beef Jerky" note was a MISLABEL: $0A=10 is FEEDMEAT tier).
- Record/dispatch (unchanged S2d pattern): `CustomRecordPtrTable[$E1]`→`CustomRecord_E1_Tame`
  ($54); `CustomBattleExec` ($72 e1) `cp $E1; jp z,SkillTame`; `SkillNamePtrTable[$E1]`→"Tame"
  ($41); Slime learns $E1 ($14, harness); descriptor `SetHLBattle_54e7` ($dd6f=$a8, msg $b882).

**(C) File set (skill #2):** bank_04c (msg fork), bank_058 (announce=$FD), bank_05f (proxy=$c2),
bank_054 (record), bank_072 (SkillTame ATK/4 + meter + `wTameDelay` init), **bank_053 (NEW —
timing/sound/blink, §11.7)**, bank_041 (name), bank_014 (harness), wram (`$D488 wTameDelay`,
`$D489 wTameBGSave[3]`). `tools/verify_integrity.py` registers `bank_053.asm`.

**Stage-2: DONE S52 — see §13.6** (crank reverted; 3-tier evolve chain; learn/MP/announce
forks; natural-to-Slime DE-SCOPED by user — the learn fork makes any species slot work).
Per-enemy blink: mechanism solved, implementation deferred (§11.7).

### 13.6 Tame Stage 2 — the 3-tier EVOLVE chain + the three new forks  [S52, 2026-07-06, v34-v37]

**Status:** level-up learn + upgrade-replace + upgrade message **user-confirmed in SameBoy**
(v34). Built S52, **NOT yet user-tested**: MP charging (10/30/50), meter tier values
(10/100/400), the "!" page-split message. Clean build byte-perfect throughout; verifier PASS.

**(A) Skills.** TameMore `$E2` / TameMost `$E3` = Tame with a bigger meter boost, on the full
§13.4 stack: records (`$54`, mp mirror +4 = 30/50; Tame's set to 10), `CustomBattleExec`
dispatch → shared `SkillTame`, names (`$41` [226]/[227]), announce (`$FD` via the NEW
`AnnounceIdxFork`, below), proxy `$c2` (heart), pool messages (idx 4/5), `TameGateHook`/
`TameSound1/2Hook` widened to the `$E1-$E3` range. Meter: `TameMeterTable` (`$72`) dw
**10/100/400** = the vanilla per-meat record `power_enemy` words (FeedMeat/PorkChop/Sirloin;
BeefJerky=30, BadMeat=5; cap `$0640`=1600 unchanged — the two `$0640`s in bank_052 are that
VANILLA cap, never a crank).

**(B) Natural-learn / EVOLVE fork (`LearnLoopFork`, bank `$06`).** The scanner ($06 entry 5,
`$4f9a`; caller = `$51` level-up flow via `ld hl,$0605; rst $10`) loops skill ids `0..$D9`
against `SkillLearnReqTable` (18 B: lvl, 6 u16 stats, up to 5 prereq ids `$FF`-padded),
skipping already-known ids via the `$c0d8` working copy (caller pre-fills $FF + the monster's
8 skills). Return in `$ffd8/$ffd9`: code 0 = plain learn (id found in the monster's personal
learnable queue — natural slots seed it), code 1 = **UPGRADE** (prereq known; old id in
`$ffda`; the caller REPLACES it in the skill list — this IS vanilla skill-evolve, e.g.
Vivify→Revive per the FAQ), code 2 = all-prereqs path; `$FF` = nothing. Custom ids were
simply NEVER SCANNED (loop bound `cp $da` — exclusion, not overshoot). Fork: the 3-byte
window `ld a,c / cp $da` at `$5088` → `call LearnLoopFork`; at `c==$DA` the fork repoints
`HL=CustomLearnReqTable`, `c=$E1`, and the SAME loop continues to `$E4`. Table: `$E1` lvl 2
no prereq; `$E2` lvl 3 prereq `$E1`; `$E3` lvl 5 prereq `$E2` (PLACEHOLDER reqs — the editor
owns real values). Placement: bank `$06`'s only free run (`$7F1E`, 225x`$FF`): 28 `rst $38`
kept + 15 B fork + 54 B table, so `Jump_006_7f7f` and `db $06 @ $7FFF` keep exact offsets.
Ids `$DA-$E0` stay unscanned by design ($DE/$DF retired POCs, $E0 not naturally learnable).

**(C) MP fork (`MPPtrFromId`, bank `$07`).** ALL THREE `SkillMPCostTable` readers (S48 map:
`$56E8` GetSkillMPCost/display, `$5A9x` afford, `$5B4x` deduct) had the identical 9-byte
index window (`add hl,hl` + table add) → each replaced with `call MPPtrFromId` + 6 nops
(byte-neutral). Fork: id < `$DE` → exact vanilla math on the labeled table; id >= `$DE` →
`CustomMPCostTable` dw 0/0/0/**10/30/50** (`$DE..$E3`). Clobbers A only; BC/DE preserved.
Before S52, custom ids read GARBAGE past `$58C8` (e.g. `$E1` → 65242) — Tame worked only
because its record mp was 0; with real costs the fork is mandatory. Record `+4` MUST stay
mirrored with this table. Placement: appended in the `$7F58` free run; 43 fill bytes
consumed, so `FollowerArtResolve07` relocated (label-based; assembler updates the call).

**(D) Announce fork (`AnnounceIdxFork`, bank `$58`).** The announce table (`$5806`,
"256-wide" by design) PHYSICALLY ends at id `$E1`: the byte for `$E2` **is the first opcode
of `Jump_058_58e8`** — high slots cannot be edited in place. Fork: the 9-byte index window
at `jr_058_57e6` → `call AnnounceIdxFork`; ids >= `$E2` read `CustomAnnounceTable`
(db `$FD,$FD`). Placed in the `$6920` free run replacing 28 nops 1:1 (`DataBtlFX_7959`
offset preserved).

**(E) Upgrade-message "!"-orphan fix.** The upgrade message is **mode-$0b template 3**
(`MiscTextPtrTable` `$41:$49CD` entry 3 → `MiscText_03` `$728B`; the `ld hl,$0b02/$0b03/
$0b0f` constants in the `$51` caller are (mode,idx) pairs — `$0b03` was mgbdis-mislabeled
as ROM0 `DispatchAboveE2`). Line 2 "becomes [New]!" auto-wraps the bare `!` for names >= 8
chars (a VANILLA defect too: Blazemore/Blazemost). Fix: entry [3] repointed to
`MiscText_03_Paged` (bank $41 free space), page-splitting like sibling `MiscText_02`:
page 1 `[Mon]'s [Old]`, page 2 `becomes` + NL + `[New]!` — never orphans, costs one button
press, applies to vanilla upgrades too. Insert codes: `$F9 $00` nickname / `$F9 $30` old /
`$F9 $20` new; `$68` = "'s".

**(F) File set (Stage 2):** bank_006 (learn fork), bank_007 (MP fork), bank_041 (names +
msg template), bank_04c (2 pool msgs, 44 nops consumed), bank_053 (range checks; the S50
OBP flicker REMOVED — a no-op on the wrong render layer, §11.7), bank_054 (ptr entries +
records + mp mirrors), bank_058 (announce fork), bank_05f (proxy $E2/$E3 = $c2), bank_072
(dispatch + TameMeterTable), wram (comment only). Harness (bank_014) KEPT per user.

## §14 FIELD-cast skills — the menu-side pipeline (RE'd S73, built with skill $E4 "Anchor")

This closes the §13.4(c) open item. The field skill-use flow lives in bank $07
(the field-menu bank) and is a `$c90e` state machine inside menu-shell page 3:

**Menu shell (`$c90d`, dispatcher at $07:$4009):** 0 = closed / 1 = "(re)draw
main menu" transition (→2) / 2 = main menu (2×2 grid cursor `$C8DA`:
0 INFO, 1 ITEM, 2 SKIL, 3 OPTN; bit7 = latched) / 3 = sub-page / 4 = FULL
teardown-to-field (`label7_6b04`: restores tiles/OAM/BG, `res 1,wGameState`,
`$c90d=0`, gate-mode VRAM reload). The item flow's `SetFld_6a8f + $c90d=1`
"close" only returns to the MAIN MENU — a real close from code is `$c90d=4`
(measured S73; that's the main-menu B-exit path).

**Skill select (A on a skill row):** the skill id (from the `$caea` cached
copy of the monster's record skill array, record offset **+$29**, 8 slots) is
stored to **`$da5e`** and run through the FIELD-USABILITY WHITELIST (cp
ladder): $2b-$2f heals, $30/$31 Vivify/Revive, $33 Antidote, $36 CurseOff,
$37 StepGuard, $38, $7e → proceed; anything else → `$0e0a` "Can't use here"
tilemap message + state $0a. **S73 fork:** the ladder tail was rewritten IN
PLACE byte-exact (the last three `jr z,jr_007_56a3` become `ret z` — 56a3 IS
a bare ret — buying 3 bytes for `cp $E4 / ret z`). Bank $07 has ~2 bytes of
tail slack; anything bigger must consume the $7F58 free run (S52 precedent).

**Use flow after select:** single-target heals detour to a target-select
state ($58E9 ladder); everything else skips (+2 states). Then the MP afford
check (reads `SkillMPCostTable` via the S52 `MPPtrFromId` fork — a 0-cost
row always affords; caster current MP compared at record **+$54**), then
`rst $10 $1404` = **bank $14 entry 4** (per-skill field VALIDATION/effect
prep: e.g. Heal sets `$da5e=$FF` "fizzle" when HP is full; unknown ids
default to $FF), then a result-message ladder + `SetFld_5b1e` (bank $14
entry 5 effect apply + the MP deduct).

**S73 hooks:** (1) bank $14 entry-4's 6-byte default tail →
`ld hl,$7202 / rst $10 / ret / nop` → bank $72 `AnchorField14Tail`
reproduces the `$FF` default for non-$E4 and, for $E4, classifies context
(`wInGateworld==1` → gate-side; else `wMapID>=$30` → gate-like special room;
else town ± `wAnchorFloor`) and ARMS the dialog script (below), leaving
`$da5e=$E4` as a marker. (2) `Anchor07Post` (bank $07, replacing the
post-$1404 `ld a,[$da5e]/cp $ff` 5-byte window): $E4 → pop out of the state
handler + `$c90d=4` (full menu close, no message, no deduct); others →
byte-exact flag reproduction.

**Arming a script from the menu (the S73 protocol):** `$D8D3=$71`
(medal_vault; CustomScriptRead keys on wScriptMapType), `$D8D4`/`$D8DC` =
script index, **counter `$D8D5/6 = $FFFF`** (the per-frame ticker
`ScriptExecContinue` PRE-increments before reading — only `ScriptInit`
reads at 0), `$D8D7 = $01`. The script engine is gated on the UI-busy
flags, so it starts ticking only after the state-4 teardown; the script's
own `init_dialog` then opens the box (works on generated maze floors —
measured). `GateAwareDispatch` (bank $60 template, re-pinned S73) routes
`wScriptMapType >= $6B && != $70` to CustomScriptRead so this works in any
physical room; `$70` (the gate-world script type) stays on the wMapID route
— that value caused the original B-bug freeze.

**Anchor ($E4) semantics as built:** confirm scripts 2 (gate-side) / 3
(return) with YES/NO, error scripts 4 (special/boss/custom room) / 5 (no
anchor); YES writes `wAnchorArm` (1/2) + warps (script `map_transition`:
$0000/$E8/$58 = the WarpWing recipe incl. `$d92b=6`; $8000 staircase-style
for the return). Bank $73 commit hook: arm 1 → store gate + floor+1
(1-BASED; `wAnchorFloor==0` is the no-anchor sentinel, and `wCurrentFloor`
is 0-based) → $D9D7-8 in the save image; arm 2 → install gate +
`wAnchorFloor-2` (entry-5's inc restores), charge `curMP := curMP >> 2`
(record +$54; the commit IS the arrival), clear the anchor (single-use),
arm:=3; `GateDecisionFork` consumes 3 → forced STANDARD maze (also bypasses
the gate-1 POC rotation on returns, by design). Battle cast of $E4 =
SILENT no-op (record anim9=$02 keeps the $dcff announce/animate gates
clear — the MagicBurn finding inverted); v2 polish = a "can't use in
battle" message. Status: **SHIPPED, USER-CONFIRMED (S73 v1 + S73b).**

**Record-layout correction (S73):** the party record is +$50 curHP /
+$52 maxHP / +$54 curMP / +$56 maxMP (known_RAM_map's old "+$52 MP" row was
wrong — the afford check reads +$54 and Heal validates +$50 vs +$52); the
menu skill array is +$29 (8 bytes), NOT +$32.

### §14.1 S73b additions — descriptions + battle rejection

**Skill DESCRIPTIONS (SKIL-menu info box):** pointer table at **$56:$6667**
(256 × dw, indexed by skill id; strings = charset + $62 space + $F1 newline +
$F0 end, ≤3 lines ≤18 chars). Unused ids ($DB-$FF) all point at the $664A
empty string — custom skills therefore showed a BLANK box until S73b.
patches/bank_056.asm (NEW patch file, registered in verify_integrity
PATCH_FILES which the compiler's builder parses) repoints entries $E0-$E4
byte-neutrally (the table renders in the source as `ld c,d / ld h,[hl]` pairs
= raw $4A,$66) and funds five description strings from the trailing nop pad.

**Battle rejection of FIELD-only skills:** the vanilla predicate is
`LoadBtl_4b98` ($50:$4B98; Z = field-only = $37 StepGuard/$38 MapMagic/$7e):
on Z the battle skill menu shows the **$0302** "can't use" message
(jr_050_4a57) and returns WITHOUT queueing the action — no turn consumed. A
second inline ladder at $50:$498A excludes the same ids from the usable-skill
count ($d9f6, the AI/order pool). S73b rewrites both sites byte-neutrally to
call a shared `FieldOnlySkillA` predicate (bank $50 tail, funded from the
mid-bank pad run; shift audit vs the previous ROM was clean — only the two
sites, the label-relinked tail helpers, and header checksums differ) with
**$E4 added**, so Anchor inherits StepGuard's exact battle behavior. Verified
at instruction level in the built ROM; a live battle round exercised both
rewritten sites without anomaly.

### 13.7 Custom skill #4 — Earthquake 4-tier chain (`$E5`-`$E8`): the SWEEP FORK, screen shake, and the looping-SE deadlock  [S74, 2026-08-01; v2 feedback round 2026-08-02, PyBoy-verified]

**Tremor/Quake/QuakeMore/QuakeMost** (`$E5`-`$E8`): all-foes earth damage
(40-60/90-120/150-190/240-270, top = 1.5x WhiteAir; editor tunes
`QuakePowerTable` in patches/bank_072.asm) that ALSO sweeps the caster's own
side for 1/3 damage, skipping the caster and ANY flying combatant on both
sides (`$db8b[slot]` bit4, packed from monster-info `+$04` by bank $51 init;
`tools/dump_flying_flags.py` exports every species' flag + ROM offset to
`extracted/flying_flags.json`). MP 5/10/16/24 (record `+4` + bank $07
CustomMPCostTable, whose index base moved to `$E0`: the retired POC rows
were dropped to fund the new entries in the FULL bank $07 tail — as was a
1-byte `cp $ff`→`inc a` rewrite in Anchor07Post, Z-equivalent since its
callers reload A). Learn chain lvl 2/4/6/8 with each tier requiring the
previous (two-stage LearnLoopFork + CustomLearnReqTable2 in bank $06's
post-`$7F7F` run; `$7F7F`/`$7FFF`/table06 tail bytes verified unmoved).

**The sweep fork ($52:$719C).** Vanilla all-foes iteration lives in bank $52:
a 20-byte window (`inc a / cp $04 / jr z` ... ceiling ladder) was replaced
byte-neutrally with a far-call to bank $72 `QuakeSweep72` (entry 3) using the
**rst-return-via-DE contract**: the window passes cur-target in A/E; the fork
returns D=1 finish / D=0 continue with E=next-1 (the window's surviving
`inc a` re-adds 1). Stock ids traverse `.vanilla` (A/B-proven with a live
MagicBurn cast on the patched ROM: swept 4→5→6→7, damage landed, clean
finish). Quake ids get: caster-skip + flying-skip on advance; at the first
side's ceiling with `wQuakePhase`<2 → **crossover**: phase:=2, arm the ally
banner (`wQuakeAllyMsg`=1 + `wTameDelay`=$2d hold) and re-aim at the caster's
own side (base-1); at the second ceiling → clear all state, D=1.

**THE TWO BIG TRAPS (both cost hours; both PyBoy-root-caused):**

1. **A looping SE deadlocks the battle effect pipeline.** Effect step 2
   ($52:$6D56) spins until `($dd80 & $dd9a) == $FF` — and that mask includes
   the SOUND-DRIVER-done bits. SFX `$68` (the GreatTree growth rumble) is a
   LOOPING ambience: play it anywhere before/during the effect and `$dd80`
   cycles forever → `$d9ed` pins at 2 → soft-lock. Suppressing the engine's
   hit sounds has the same signature (nothing ever completes) — which is
   precisely why Tame's gate REFIRES `$5501/$5502` at delay==8: a newly
   queued SE *replaces* the lingering one. The Quake solution: the handler
   queues `$68` via `wSoundEffect` (`$c8b8`) + starts the SCY wobble
   (`$c8b1`=$50), and a 15-byte ROM0 stub — **QuakeShakeEnd, living in the
   audited-dead interrupt-vector gap bytes $0051-$0057 + $005C-$005F** (timer
   `$50` and joypad `$60` vectors keep their `reti` first bytes; no
   call/jp/jr anywhere in the ROM targets the gaps) — hooks the wobble's
   `dec a / ld [$c8b1],a` (4-for-4 window at $0574) and queues **SFX `$00`
   as a stopper** the frame the shake counter hits 0 (~80 frames). Any
   queued SE replaces a looping one (measured: `$00` and `$6b` both free the
   stall). Net effect: the pipeline HOLDS under rumble+shake for ~80 frames,
   then damage flows. `$c8b1` has NO vanilla writers (BattleRex shakes use
   the separate `$c8b2`/X copy), so the stub fires only for Quake shakes.
   Note the corollary for step-1: it dispatches the handler at `$d9ee`==$0B
   via the $6CD5 far-call, and unknown ids fall from step 1 STRAIGHT INTO
   the step-2 body ($52:$6cfa `jp $6d56`) in the same frame.

2. **`$db88` (wBattleAttackerIdx) is NOT the caster during a sweep.** The
   per-target redirect ($53:CallBtlC_5e38) rewrites it to the CURRENT target,
   so caster-skip/side tests against it mis-skip slots and re-aim the
   crossover at the enemy side (measured: slot-5 skip + double enemy pass).
   Fix: `wQuakeCaster` ($DEB6), derived at the phase-0 handler run by
   scanning the action queue (`$dcec` id/target pairs) for our skill id
   (first-match; two same-tier queuers collide — v1 note). The ally-1/3
   decision doesn't use targets at all: it keys on **`wQuakePhase` >= 2**
   (phase 1 = committed victim side full damage, phase 2 = own side /3),
   immune to the first-dispatch `$db89` staleness (the target is set AFTER
   the phase-0 dispatch) and to the `$db88` contamination.

**Records** (bank $54): byte-for-byte the proven MagicBurn all-foes shape
(`$46,$12,$12,...`) with only mp at +4 — **power words MUST stay zero**
(nonzero powers loop the presentation: same `$dd80`-cycling stall signature).
Damage lives in the handler's bank-local table. Announce = `$FD` custom
escape → "{caster} sets off a quake!"; crossover banner "Allies are caught!"
— both SINGLE-LINE (Tame pattern; the vanilla multi-line battle format ends
pages with `63 FC 10 EC F2` and its handshake interaction is undecoded — the
requested longer wordings are the v2 item). Early hit sounds are suppressed
for `$E1`-`$E8` (widened TameSound hooks) so the cast is rumble+shake, then
per-hit text; the crossover hold refires the damage pair at delay==8.
Proxy = `$09` Infernos (HealMore `$2c` stalls the `$6c4d` done-spin on the
offense side).

**Measured end-to-end** (3 enemies + fabricated ally, deterministic
queue-poke rig): rumble f+1, stopper f+83, shake SCY ±4, sweep
4→5→6→7 → banner+hold → 1→2→3, enemy damage -43/-57/-40 (KOs), ally
-17/-19 (= roll/3), caster untouched, flying slot-5 skip clean, MP -5,
back-to-back casts clean (`$d9ed`/phase reset), MagicBurn + attack +
Infernos regressions clean. **Rig caveats:** a real-menu commit was NOT
exercised (menu navigation isn't scripted) — the queue-scan caster
derivation and first-target selection ran only under poked state; Tame
can't commit through the rig (tameability gate) — its ladder bytes are
verified untouched. If ALL enemies fly, the sweep never starts (no ally
pass either). Fabricated-ally harness lore: `$dd1b[slot]` must be **0**
(nonzero-non-FF = invalid — see the fixed CheckMonsterSlot comment: CF SET
= INVALID), `$dd13[slot]` a live turn-state, `$db8b[slot]` real flags.

#### 13.7.9 v2 (user-feedback round, 2026-08-02) — victory-proof ally sweep, wind removal, tier-scaled shake bursts

User feedback on v1: (1) a battle-winning quake never hit the caster's own
side; (2) the borrowed Infernos "wind" cast animation played before
everything and had to go, with the ordering fixed to shakes → blink/damage
text; (3) the tiers should shake 1/2/3/4 distinct times; plus the announce
split "quake" mid-word and the skills had no SKIL-menu descriptions.

**(1) Victory gate.** Step 6 (`$52:$6ffa`, the per-target continuation step)
opens with `call $7e85 / call $7782 / jp c,$70e0 / call $7dd7 / ret c`.
`$7782` is the SIDE-WIPED check: BC=$0300 then $0304, per-slot `$77a8`
calls, returns CARRY when either side is fully dead → `$70e0` = battle-end,
abandoning the rest of the multi-target iteration (measured: a 3-kill Tremor
ended the action at the third kill's step 6; the ally pass never ran).
`$7782` has exactly TWO callers: `$7033` (this step-6 head) and `$70bd`
(inside `$7085`, the iteration-done actor scheduler — runs unconditionally
right AFTER the action). So the fix gates only `$7033`: it now calls
`QuakeVictGate52`, a 9-byte trampoline living in the sweep window's former
pad: `ld a,[$deb4] / or a / jp z,$7782 / xor a / ret` — while wQuakePhase!=0
report "nobody wiped" (A=0, carry clear); once the sweep finishes, the
`$70bd` call runs the real check and victory/defeat land one action later.
PyBoy: all-3-kill Tremor → ally dispatched and damaged (−roll/3) AFTER the
wipe, then battle mode 2→1 (won). A quake that wipes the caster's own side
defers defeat the same way.

**(2) Wind removal — two failed designs and the real mechanism.** Forcing
`$da82:=1` for quake ids at the `$6c4d` gate (far-fork, entry-5) wedges the
battle: the `$5f05` driver that gate calls is not just the cast-animation
player — it is the engine that ticks the d9ee ACTION-SETUP machine, and
starving it freezes d9ee (first wholesale, then even when scoped to
d9ee==3, which the old traces show is precisely the cast-anim wait state
spanning the wind window). The correct fix goes to the SOURCE: the Layer-1
sprite-anim routine index is `table[$58dd/$59c3/$5aa9][GetPresentId()]`
(§11.1), and index `$0D` is the documented bare-`ret` "no visual" sentinel.
That one lookup site now calls `GetAnimPresentId` (bank $5f, 12 B from the
pad): quake ids return `$12` — a skill whose index is `$0D` in ALL THREE
side tables — every other presentation site (flash/SFX/messages) keeps the
proven `$09` proxy, and stock ids fall through to `GetPresentId` unchanged
(Infernos regression-checked). Related: HealMore `$2c` is `$0D/$00/$0D` —
its non-quiet side-B selector is why it stalled as a full proxy in v1.
Windows at `$6c4d` were reverted to vanilla bytes.

**(3) Tier-scaled shake bursts.** The ROM0 stub + wobble window from v1 are
fully REVERTED (ROM0 is vanilla again; the vector-gap bytes are free for
future use). Instead, the head of effect-step 2 (`$52:$6D56`,
`ld a,[$dd80] / ld hl,$dd9a / and [hl]`) is a 10-for-10 window far-calling
bank $72 entry 4 `QuakeStepTick72`, which returns E = the same
`[$dd80]&[$dd9a]` mask (A/flags do NOT survive the rst $10 bank-restore —
register-return contract) and, while wQuakePhase!=0, runs the shake
sequencer: `wQuakeBursts` ($DEB7, set to tier count 1..4 by the handler) ×
16-frame `$c8b1` bursts with 12-frame `wQuakePause` ($DEB8) gaps, then one
SFX-$00 write to `$c8b8` (the rumble stopper; wQuakePause=$FF marks
terminal). Because step 2 is exactly the state the pipeline holds in while
the $68 rumble loops, the whole burst train plays BEFORE any per-target
presentation: announce → N clean shakes → blink/damage text, by
construction. The handler no longer touches `$c8b1` directly. PyBoy: E5/E6/
E7/E8 → 1/2/3/4 bursts (16 f each, ~13 f gaps), damage in tier range, ally
/3 crossover intact (an E8 test even KO'd the fabricated ally cleanly).

**(4) Cosmetics.** The announce is now the 2-line "{name} sets off"␊"a
quake!" ($F1, byte-count-identical to the old single line; the v1 stall
blamed on $F1 was really the rumble + nonzero record powers). All four
tiers got SKIL-menu descriptions in bank $56 (4 table rows repointed off
the `$664a` empty string + 186 string bytes funded from the 3213-nop pad).

**Hard-won structure notes.** (a) The "spare nops" of a byte-neutral window
are EXECUTED fall-through path, not dead pad — v2's first trampoline
placement made step 6 `ret` out mid-flow every frame (sweep called every
frame, d9ed pinned at 6). The window now `jr`s over the trampoline, paying
for the jr with `ld a,e / dec d / jp z` (dec d: Z iff D==1, carry
untouched) in place of `ld a,d / or a / ld a,e / jp nz`. (b) Per-target
step chains: survivor `1→2→4→6→1`, kill `1→2→26→3→6→1` (step 26 =
`$7ee3`); step 6 decides continue-vs-end. (c) `rst $10` operand is
H=bank, L=ENTRY INDEX — `ld hl,$5305` is bank $53 entry 5, NOT address
$5305. (d) Cast-time skill validation enforces the LEARN-LEVEL: an actor
below a tier's CustomLearnReqTable2 level gets the vanilla "doesn't know
that yet" reject (msg $1D) — which is the prereq chain working; harness
runs must not poison OTHER actors' `$db8a` (the v2 rig gates its pokes on
`$db88==0`, and pumps `$dc65` = the battle-side (level,id)-pair skill
cache when casting an unlearned tier).

#### 13.7.10 v3 (second feedback round, 2026-08-02) — the shake IS the cast animation; fly-dodge beats

User feedback on v2: the first target's blink + damage text still landed
simultaneously with the shake; the ally banner needed the full "Allies are
caught in the seismic wave!" wording; and skipped flying combatants needed a
visible "But X flew above it!" beat (including the all-allies-flying case,
but NOT when the caster stands alone).

**Root cause of the simultaneity.** The v2 stall lived at effect-step 2 of
the FIRST target — which runs AFTER that target's step-1 (message + blink).
So target 1's presentation always preceded the shakes. The fix moves the
whole shake train into the CAST-ANIMATION slot (`d9ed==1`, `d9ee==3` — the
exact slot the borrowed wind used to occupy), restoring the vanilla ordering
anim → announce → per-target blink/damage with zero pipeline surgery.

**Mechanism.** The `$6c4d` da82 gate is now a byte-neutral 15-for-15 window
(it swallowed the trailing `ld a,[$da82] / or a / ret z` re-read as well:
`ld hl,$7204 / rst $10 / ld a,e / or a / jr nz,<dispatch> / ret` + 6 nops).
The 10-byte version failed because the fall-through re-read the REAL $da82
(=1, the quiet `$0D` anim finishes instantly) and let the machine advance
mid-burst with the rumble still looping. E is authoritative now; nothing
branches into `$6c55-$6c5b` (bank-$53 `call $6c59` hits in a full-ROM scan
are bank $53's own address space — same-address/different-bank scan trap).
Entry 4 (`QuakeAnimHold72`) reproduces vanilla exactly for non-quake ids
(including the nested `$5f05` driver call that ticks the d9ee setup
machine); for `$E5-$E8` in the anim slot it arms (once) the `$68` rumble +
tier-count burst train, ticks `QuakeShakeSeq` every frame ($10-frame
`$c8b1` bursts, $0C-frame `wQuakePause` gaps, SFX-$00 stopper, `$FF`
terminal), and reports E=0 until the real anim AND the train are done. Three
measured traps encoded in the final shape: (a) the arm test needs
`d9ed==1` — d9ee also cycles 1,2,3 while `d9ed==0` (idle), and arming there
plays the train outside the action; (b) the done-report must be STICKY
(`wQuakeArmed` stays set; the sub-machine takes several frames to leave
d9ee==3, and clearing it re-armed the train each frame — six Tremor bursts);
(c) `wQuakeArmed` ($DEB9) is cleared by the handler's phase-0 init and
`.qfinish`. The step-2 window from v2 is fully reverted (vanilla bytes); the
handler no longer touches the presentation at all.

**Fly-dodge beats.** Flying combatants are no longer skipped: the sweep and
the first-target scan (`QuakeFirstTgt53`) keep only the caster skip, so
flyers get real per-target beats. The handler forces their damage to 0
(`$db89` is the current target at every dispatch). The engine routes a
0-damage hit to miss-message `$B8` "Has no effect on {name}!" (measured) —
`LoadB4c_Fork` now intercepts `$B7`/`$B8` and, for a quake id with a flying
current target (`$db8b[$db88]` bit 4), renders `CustomMsg_QuakeFlew`
("But {F9 00} / flew above it!") through a 1-entry mode table instead; the
`F9 00` escape resolves the current message subject = the flyer. This
covers both sides, gives the all-allies-flying case its banner + per-ally
fly lines (real beats exist), and the solo-caster case stays silent for
free: no ally beats exist, and `.qfinish` clears the armed banner flag.
The ally banner is now the full 3-line "Allies are caught / in the seismic
/ wave!". All verified in PyBoy: enemy-flyer line, ally-flyer line after
the banner, solo-caster silence, E8 = 4 bursts before any beat, all-kill →
ally hit → victory, Infernos/plain-attack regressions.

#### 13.7.11 v4 (third feedback round, 2026-08-02) — banner fit, side-scoped fly line, honest sounds

Four user reports, four fixes:
1. **Banner cut off** ("…in the seismic" and no third line): the battle box
   shows two lines; a third `$F1` line never displays. The vanilla page
   mechanism (`FC 10 EC F2` mid-string, as in msgs $67/$83) DOES scroll to a
   third line — but inside a GATE-inserted render it swallowed the following
   beat's own message (the ally fly line never posted; measured). Final:
   2 lines that fit exactly — "Allies are caught" / "in a seismic wave!"
   (line 2 = 18 chars; "the"→"a").
2. **Fly line is PARTY-side only** (user preference): enemies keep the
   vanilla "Has no effect on {name}!". `LoadB4c_MaybeFlew` now keys on
   `$db89` (the target var the damage handler trusts — `$db88` proved flaky
   on real-menu casts) and requires `$db89 < 4`. Hook-verified: enemy flyer
   → vanilla text; ally flyer → the fly line at its own beat.
3. **Party-hit sound played even when every ally flew**: the
   `wTameDelay==8` `$5501/$5502` refire in `QuakeGate_delay` is deleted
   (nop'd in place). Its rumble-stopper duty moved to the anim-slot train in
   v3, so it had become a pure false-positive sound.
4. **Enemy damage sound missing on the blink**: the Tame-era
   `TameSound1Hook`/`TameSound2Hook` suppression covered `$E1-$E8`; the
   quake half existed only because the early sounds used to fire under the
   looping rumble. Range narrowed to `$E1-$E4` (one byte each: `cp $e9` →
   `cp $e5`): quake beats play the vanilla per-beat damage sound again —
   which is intrinsically honest: damaged beats ding (measured at each
   damaging beat), flyer/0-damage beats stay silent (measured), on both
   sides. Tame `$E1-$E3` behavior is untouched.

### 13.8 Custom skill #5 — Mourn (`$E9`): defense-calc dispatch, dead-ally multiplier, double-slash replay  [S75, 2026-08-02; PyBoy-verified, NOT user-tested]

**Mourn (`$E9`)**: single-foe physical-style attack whose damage is the
vanilla ATK-vs-DEF roll multiplied by **(dead allies + 1)** — 0 dead = 1×
(all alive or caster alone), 1 dead = 2×, 2 dead = 3×. MP 10 (record `+4` +
`CustomMPCostTable`). Natural learn: standalone lvl 3, no prereq
(`CustomLearnReqTable2` row appended past the `$E8` record; the LearnLoopFork
end bound moved `cp $e9`→`cp $ea`). Announce "used Mourn!"; a boost banner
"Fallen allies / lend power!" renders (then holds 40 frames) ONLY when the
multiplier fired. Proxy = `$40` EvilSlash, played **twice** back-to-back.

**The defense-calc dispatch (NEW pattern — second custom trampoline).**
MagicBurn-class customs run `CustomDispatch52` = `LoadBattle_653e` (the
MegaMagic MP-based context) + descriptor + far-call. Mourn needed the
PHYSICAL damage base instead: `FarSkillFork` returns a *different*
pointer-holder for `$E9` — `MournDispatchPtr` (`$52:$7FFA`, in the tail pad)
→ **`MournDispatch52`** (`$52:$6C56`, funded from the 6 audited-dead bytes
after the S74 anim-gate window): `call CalcDefenseWrapper / jp
CustomDispatch52_shared`. The shared tail (label inside `CustomDispatch52`)
runs the descriptor + `$72` far-call as usual. So "which vanilla damage
machine seeds `$db56`" is now a per-skill choice at the fork, at zero cost
to the existing customs.

**Dead-ally counter (`SkillMourn`, bank `$72`).** Party slots 0-3, skipping
the caster (`$db88` — stable here: single-target, no sweep redirect):
present = `$dd1b[slot] != $FF`, dead = present && battle HP
(`$DBA3+slot*2`) == 0. **`$dd1b` semantics (measured S75): `$00` alive,
`$01` processed-KO ("skip"), `$FF` never existed.** The v1 `==0` presence
test excluded a corpse once the engine's KO scan flipped 0→1 (~400 frames
after death) — casts after that lost the boost; the `!=$FF` test holds for
the whole battle (verified: 8 consecutive 2× casts post-KO-processing).
Multiplier = add-loop (dmg += base, dead times). If dead>0: arm
`wMournBoosted`=1 + `wTameDelay`=$28.

**Double-slash replay (`QuakeAnimHold72 .mourn`, bank `$72` entry 4).**
In the cast-anim slot (`d9ed==1 && d9ee==3`): arm `wMournSlashes`=2; tick
the `$5f05` driver; each time `$da82`→1, decrement and **re-arm** the
animation (`$da82`:=0 + `$5f06` entry-6 re-dispatch — re-reads the proxy id
and re-inits the frame machine; measured: the second play runs identically).
**Sticky terminal is mandatory** (the S74 trap, re-measured): the sub-machine
lingers in d9ee==3 ~2 frames after E=1, and slashes==0 doubling as "not
armed" re-armed the train every lap = INFINITE slashing (26-frame period).
`wMournSlashes`=$FF marks done; the handler's staleness clear resets it
(it runs right after the anim slot in every normal action). An abnormally
aborted action can leave $FF → the next cast skips its animation once and
self-heals (v1 note).

**Boost banner (`MournGate_delay`, bank `$53`).** TameGateHook ladder gains
`jp z, MournGate_delay` for `$E9` (jp — the target is past QuakeGate_delay,
outside jr range). Gate: flag set → render `$FD` (LoadB4c_Fork_custom checks
`wMournBoosted` FIRST → `LoadB4c_MournBoost` renders the banner and clears
the flag) and hold that frame; then tick `wTameDelay` to 0 → resume. No
dead allies: flag never set, delay never armed → zero-hold pass-through;
vanilla per-beat damage sounds play (`$E9` is outside the `$E1-$E4`
suppress range).

**Announce-vs-banner ordering (the design risk, MEASURED SAFE).** Both are
`$FD` renders, disambiguated by `wMournBoosted` — which would hijack the
announce if the handler ran first. Measured order: anim slot (2 slashes) →
announce renders (flag still 0 → "used Mourn!") → handler at effect
dispatch (sets flag) → message step (gate renders banner + hold) → damage
text. The flag is set strictly between the two renders.

**Byte funding:** bank `$07` was 1 byte OVER — reclaimed 3 in
`MPPtrFromId .custom` (`ld a,$00/adc HIGH/ld h,a` → `ld h,HIGH(table)`,
valid only while the table sits in one page — **link-time ASSERT added**,
build fails if a future row crosses). Bank `$41`: the Mourn name is funded
from the dead `$00` fill before Scorch (only `$7FF9+` of the `$7E39` region
is ever indexed; redirect gates id>=224). Bank `$56` desc + `$4c` messages
consume their nop pads 1:1; bank `$58` announce row consumes 1 nop
(DataBtlFX_7959 pin re-verified); bank `$06` learn row consumes 18 `rst $38`
(db `$06` still at `$7FFF`).

**Measured end-to-end (queue-poke rig, real .sav party of 3 WingSlimes,
TriggerBattle-mimic pokes `$DA03/04`+`$DA02`+`$DA09`+`$C905`+`$C8EB`.6):**
0 dead → rolls 6-9, no banner flag ever; 1 dead → 16/16/14/16... (2×,
persists post-KO-processing), banner rendered + 40f hold, enemy HP -16
applied; 2 dead → -31 (3×~10); MP 96→86 per cast, casting stops below 10;
two slash plays then clean release (sl 2→1→$FF→advance); kill chain
1→2→26→3→6; regressions Tremor (full sweep + ally pass) / Infernos / plain
attacks clean. **Rig caveats:** real-menu commit NOT exercised (S74
precedent; the queue was forced at `$dcec[0]`); one -13 among eleven 2×
events (odd ≠ 2B — possibly apply-time variance in the shared vanilla
pipeline; watch in user test); level-3 actor vs level-3 learn req passed
the cast-time validation (>= semantics confirmed at the boundary).

**v2 (user-feedback round, 2026-08-02) — the banner comes BEFORE the
animation.** v1 rendered the boost banner in the damage-message step (after
the slashes); the user wanted it first. The dead-ally condition therefore
moved UP into the anim fork: `MournCountDead` (bank `$72`, shared by fork +
handler — both run with the bank mapped, plain `call`) is evaluated on slot
entry; if dead>0 the banner renders immediately (`wMournBoosted`=1 →
`$FD` → LoadB4c_MournBoost, which clears the flag so the LATER announce
`$FD` still resolves to "used Mourn!"), then a `wMournSlashes`=$FE hold
state ticks `wTameDelay`=45 **without calling the `$5f05` driver** (a
bounded deferral, unlike the S74 permanent starve — measured safe: the
setup machine just waits in d9ee==3; the render's own text-typing adds
~43 pipeline-held frames, total ≈88 frames of banner before slash 1), then
$FE→2 and the slash phase runs unchanged. The handler keeps only the
multiplier; `MournGate_delay` (bank `$53`) is now a natural pass-through
(flag 0 + delay 0) and stays in place unchanged. Only bank `$72` changed.
Measured (v2, PyBoy): banner box pixels during the pre-slash hold are
IDENTICAL to the v1 visually-confirmed banner; the banner persists on
screen through both slashes; announce replaces it; 2× events all even
(16/10/14/12/14), MP -10 ×5, multiple rounds no wedge; 0-dead never enters
the banner phase; Tremor regression clean. One incidental measurement:
`$da82` is still 1 from the PREVIOUS action when the slash phase arms —
the first .mournTick takes the done-path instantly and the "first" slash
is really the entry-6 re-arm; both plays still show (v1-confirmed
visually), but a v3 wanting N slashes should arm N+0 with an explicit
$da82:=0 + entry-6 call at .mournArmSlashes instead of relying on the
stale done-flag.

**S75 fences (crash-investigation hardening).** (1) `LearnCode2Guard06`
(bank `$06` `$7F1F`, jp-trampoline from `Jump_006_50b5`): the scanner's
code-2 exit — vanilla blanket stat-qualification, no species latch — is
closed for custom ids `$E1+` (divert to the skip-record path, scan
continues); customs learn ONLY via code 0 (natural species slots) or code 1
(prereq evolve). (2) `SlotProbeGuard50` (bank `$50`, `CmpBtl_6383` head):
the level probe rejects slot indices `>= $28` — the exp walker leaves
`$cac0 == 40` and a stale re-probe otherwise processes the phantom slot,
whose "record" is echo RAM. Both byte-neutral. Their presence in the built
ROM is ENFORCED by `tools/validate_custom_data.py` (verify_integrity check
6 + the editor builder): a universal-qualifier learn row (no prereq +
all-zero stats, like Tremor's and Mourn's) without the code-2 fence is a
BUILD ERROR.


---

## Power calibration — what actually makes a fight hard (S76)

Written after a randomizer shipped a first gate that hit for 15 a turn while
every stat in the ROM was still "preserved". Everything here is the calibration
data an editor needs to change content without wrecking progression.

### Learn requirements are NOT a difficulty gate

`SkillLearnReqTable` (`$06:$50E0`) answers "can this monster ever learn this?"
It does NOT answer "is this appropriate for a level-3 enemy?" Breath skills in
particular are gated by SPECIES in vanilla, not by stats, so their stat
thresholds are low and a level-2 enemy passes them trivially.

Enemy rows do not learn anything — their four skill bytes are handed to them
directly. Filtering those by learn requirement lets a Gate-of-Beginning slime
carry FireAir. **Filter by damage instead.**

### The enemy-side power pair is the knob

`SkillRecordData` `$54:$41CF`, 222 records × 19 bytes (indexed via `$54:$4013`).
Region-identical. The fields that matter for calibration:

| Offset | Meaning |
|---|---|
| +1 | category, hi-nibble: 1 damage, 2 status, 3 heal/buff, 6 item-ish, 8 item |
| +2 | target mode: `$11` one foe, `$12` ALL foes, `$21` one ally, `$22` all allies, `$41` self |
| +6 | damage class: `$00` none, `$04` spell, `$05` breath |
| +11/+13 | party-side damage min / range |
| **+15/+17** | **ENEMY-side damage min / range** |

Two power pairs exist because the caster's side selects which is used — enemy
Blaze (7–12) is weaker than party Blaze (12–15). **For enemy content, +15/+17 is
the only number that matters.**

Calibration samples:

| Skill | Target | Enemy damage | Note |
|---|---|---|---|
| Blaze (0) | one foe | 7–12 | |
| FireAir (92) | **ALL foes** | **10–16** | flat, ignores ATK/DEF/level |
| Firebal (3) | ALL foes | 10–18 | |
| Bang (6) | ALL foes | 15–20 | |
| HealMore (44) | one ally | 75–90 | fine on a boss |
| **HealAll (45)** | one ally | **999** | full bar |
| **HealUsAll (47, 163)** | **all allies** | **999** | full bar, whole team |
| Meditate (147) | self | 500 | flat — a full heal on anything under 500 HP |

### Rules that hold difficulty steady

1. **Match kind, target breadth AND damage.** Breadth is invisible to a power
   comparison — HealAll and HealUsAll are both 999, so a naive "same power"
   swap turns a single-ally heal into a whole-team full heal. S76 shipped that
   bug before catching it.
2. **Band asymmetrically.** Allow replacements to be weaker; keep the upward
   allowance at 0. A symmetric ±35% band let six bosses gain damage (one 130 →
   160) purely by luck of the draw.
3. **Never give a boss or arena entrant a full heal.** Skills **45, 47, 163**
   are banned outright on every boss / arena / boss-join row (169 rows). Also
   cap any heal at the row's own max HP, which catches flat-value heals like
   Meditate on low-HP rows without needing a blacklist entry per skill.
4. **Swap species, keep stats.** An enemy row's level, six stat words and exp
   reward define its place in the curve. Changing only `species` (+0) and the
   four skill bytes gives you a completely different fight at identical pacing.
5. **Group encounter pools by EXACT level, not by quantile.** S76 first bucketed
   543 pool slots into 10 quantile bands; that is fine at the top of the curve
   and catastrophic at the bottom, where it moved level-4/5 rows (ATK 26–35)
   into the Gate of Beginning (vanilla: level 1, ATK 8–19). Low-level difficulty
   tracks absolute stat deltas, not rank.

`randomizer/audit_threat.py` enforces rules 1–4 as a per-row regression: for
every one of the 487 enemy rows it compares worst-case enemy-side damage against
vanilla and fails if any row got harder. Pool-level maxima are reported
separately as informational, since EIDs permuting between same-level pools moves
a pool's maximum without changing any row's threat.

### Resistances are an ENEMY stat too

Enemy resistances are NOT in the 25-byte enemy-stats row. The battle initialiser
(bank `$51`, `ld hl,$0301` / `rst $10` per combatant) loads the **species** info
block, so monster-info offsets `$0F`-`$29` drive both your monsters and every
enemy in the game.

This makes resistance edits a difficulty knob, and a global column shuffle
flattens the curve badly — vanilla has 66 zero-immunity fodder species and four
21-immunity bosses; shuffling columns independently gives everything ~3. Measured
vanilla means by tier byte `$2A`: tier 0 = 0.00, tier 3 = 1.24, tier 4 = 1.53,
tier 5 = 2.62, tier 6 = 8.21, tier 7 = 4.57.

To scramble resistances without moving difficulty: permute each species' own 27
values across the damage types, and swap whole vectors only WITHIN a tier bucket.
That preserves resistance mass per tier exactly while changing every profile.

---

## The record power field is BLIND on 43 skills — S77

The single most expensive lesson of the randomizer work. `SkillRecordData`'s
enemy power pair (`$54:$41CF` +15/+17) is **0** for 43 of the 222 skills, because
their handler computes damage itself rather than rolling the record:

| Skill | Learn level | Why the record says 0 |
|---|---|---|
| Sacrifice / Opfer | 1 | damage from caster HP |
| Kamikaze | 18 | damage from caster HP |
| Beat / Defeat | 16 / 30 | instant death |
| BeDragon | 28 | transforms the caster |
| Chance / Mystik | 40 | random effect table |
| MegaMagic / Madante | 38 | `(MP*2 + level*2) / 4` |
| GigaSlash | 33 | handler-scaled |
| SamsiCall | 33 | summon |

Any rule that bands, caps or compares on record power **cannot see these at all**.
That single blind spot produced six separate "how is this in gate 1" bugs in a
row — FireAir, BigBang, Lähmer, BeDragon, MegaMagic, Sacrifice — each patched
individually before the pattern was recognised.

### The fix: vanilla's own placement is a complete danger rating

Vanilla already encodes how dangerous every skill is, in **where it is willing to
use it**. Build `{skill: (min_level, median_level, row_count)}` from the vanilla
enemy table and the problem disappears for all 222 skills uniformly, with no
formula tracing and no blacklist:

| Skill | Vanilla rows | Min level | Median |
|---|---|---|---|
| Sacrifice | 9 | 20 | 26 |
| MegaMagic | 2 | 48 | 48 |
| GigaSlash | 4 | 40 | 45 |
| SamsiCall | 2 | 33 | 35 |
| Blaze | 33 | 1 | 12 |

`randomizer/logic.py::vanilla_placement()`. Rule: **a row may not carry a skill
below the lowest level vanilla ever placed it at.** Also require
`meets_requirement()` against the row's own level AND stats — a row should only
use what it could have learned.

### Usage FREQUENCY is a second, independent constraint

Preserving moves-per-row does not preserve rows-per-move. Measured on a build
that passed every other check: `Speed` 1 → 44 rows, `Upper` 9 → 44,
`Sacrifice` 9 → 40, `Whistle` 1 → 23, while `ChargeUP` fell 22 → 4 and
`SleepAir` 16 → 2. Three skills vanilla never arms an enemy with appeared 12-15
times. Deal skills from a **bag holding each skill exactly as many times as
vanilla used it**.

Two ordering traps when dealing from that bag:

1. **Deal LOWEST level first.** A level-6 row can only accept skills vanilla
   placed that low; a level-60 row can use nearly anything. Dealing high-to-low
   drains the bag and leaves 34% of slots with no legal candidate, falling back
   to their vanilla move — concentrated on the early bosses the player sees
   first.
2. **Prefer a candidate that differs from vanilla.** Count preservation means a
   low-level row draws from a small pool where the commonest skills dominate
   (Heal alone is on 32 vanilla rows), so without this the early game keeps its
   vanilla movesets even though the algorithm "randomized" it.

### Severity is invisible to power too

Every status skill has record power 0, so Slow, StopSpell and **Paralyze** rank
identically. Swapping between them tripled paralysis on boss/arena rows (2 → 7)
and nearly doubled it overall (14 → 26). Paralysis (`damage_class $03` — 105
Lähmer, 107 Allähmer) needs its own bucket, and is banned outright on boss /
arena / boss-join rows alongside the full heals (45, 47, 163).


## 15. DAMAGE FORMULAS — traced and differentially validated (S78)

Everything below was read from `disassembly/bank_052.asm` (routine names
cited), reimplemented exactly in `simulator/damage.py`, and validated by
replaying PyBoy captures of the real engine through the model:
**698 comparisons, 0 mismatches** (`simulator/s78_master_events.json`,
`simulator/validate_damage.py`). RNG is the LCG `state16 = state16*5+$1357`
(state = RNG1<<8|RNG2); damage code builds its 16-bit dividend SWAPPED as
(RNG2<<8)|RNG1.

### 15.1 The physical roll — `CalcSkillDefense` ($52:$60D7)

One `BattleRNG` step at entry; all later RNG reads reuse that value.

```
if ATK <= DEF/2:           damage = RNG1 & 1                       [regime A]
else base = (ATK - DEF/2) >> 1
  if base <= ATK>>4:       damage = RNG16d mod (ATK>>4)            [regime B]
                           (ATK>>4 == 0 -> regime A)
  else:                                                            [regime C]
    var = (RNG16d mod ((base>>3)+1)) >> 1
    n = RNG2 & $0F:  n==0 none; n&8 -> base += var; else base -= var
    t = RNG1 & 3:    t==0 none; t odd -> +1; else -1
    damage = base
```

Then `LoadBattle_61ec`: the THIRD party slot (target idx 2; in LINK
battles, idx&3 == 2 of either side) takes **×0.8** — **MEASURED S79** with
a 3-monster party (rig `--party3`): ti=2 roll 45 at the $61EC waypoint ->
36 at commit (=45*8//10), ti=1 control unchanged (46 -> 46). NB the $61EC
hook sees the PRE-adjust value. Finally the zero floor: damage==0 -> RNG2&1 (applies AFTER
the slot-2 adjust; a hook at $61EC sees the pre-floor value).

The plain attack command IS skill id 58 through this core. Physical
multiplier handlers (validated): TwinSlash/PsycheUp ×1.5, Beserker ×2 (+
sets $db08 bit2), SquallHit ×0.8, Ahhh ×0.5, RainSlash per-hit ×0.8/0.6/0.4/0.4
($DD69 = hit counter, **4-hit cap MEASURED S79**: handler `$52:$48B4`
stops at $DD69==5; hit1 = ×8/10 `$69B7`, hit2 = ×6/10 `$69D2`, hits 3-4 =
(×8/10)>>1 `$69E1`; dead targets skipped by walking $DB89 within the side), BiAttack rolls with ATK×0.75 (2 hits), QuadHits
ATK×0.625 (4 hits, measured 100→75 / 100→62), CALLEVIL rolls with ATK=400,
MetalCut ×1.5+1 iff target metal flag ($DB8B+slot bit0), family cuts
(DrakSlash class) ×1.5 iff target family matches (Slime 0/Dragon 1/Beast 2/
Bird 3/Plant 4 via `LookupTargetSpecies`).

### 15.2 Record spells — `StoreDamageResult` ($52:$66D6) + `LoadBattle_679c`

`damage = record_min + (RNG1 mod (range+1))` — **no RNG advance, no caster
stat, and DEF does NOT reduce spell damage** (the S77 open question). Side
selection: party caster +$0B/+$0D, enemy +$0F/+$11 (validated both sides,
69 checks). Heals are the same roll (Heal 43 = 30+RNG1%11 for BOTH sides;
HealAll = 999 -> clamp to max).

### 15.3 Resistances — packing and ladders

Species info +$0F..+$29 (27 levels 0-3) is packed 2-bit MSB-FIRST into 7
bytes per combatant at `$DD28 + slot*7`; type t sits at packed position
t+1 (byte (t+1)//4, bit-pair 3-((t+1)%4)); position 0 unused. Verified
15/15 element cores vs the FAQ table (§ resistance_types.json order).

Damage multiplier ladders, keyed on target status byte $DB05+slot*8 bits
6/7 (`CheckTargetGuardA` family — the spell/GigaSlash path):

| res level      | 0      | 1       | 2    | 3    |
|----------------|--------|---------|------|------|
| normal         | 1.0    | ×85/100 | 0.5  | 0    |
| bit6           | 1.0    | 0.75    | 0.4  | 0    |
| bit7 (amplify) | 1.3125 | 1.15625 | 0.75 | 0.30 |

Breath ladder (`BitCheck_676c` — breaths, BigBang, RockThrow, MegaMagic):
normal [1, 0.75, 0.4, 0]; bit6 [0.75, 0.5, 0.25, 0]; bit7 = amplify row.
Elemental slashes (`BitCheck_6782`, after the phys roll): bit6 -> plain
row, otherwise the AMPLIFY row (a 1.3125× bonus vs res-0!).

Hit ladders (RNG1 < threshold after one step): `CheckTargetGuardB` normal
[always, $D8, $7F, never], bit6 [always, $BF, $66, never], bit7 [always,
always, $BF, never]. **`BitCheck_6749` (Beat/Defeat/K.O.Dance, ids < $72,
and the status helpers) has NO bit6 branch**: bit7 clear -> [$BF, $7F,
$3F, never] — an unguarded Beat vs res-0 is a 74.6% roll, not a sure hit
(measured). `BitCheck_6733` (Kamikaze class): normal [always, $BF, $66,
never].

Element grid: Blaze grp→Fire(0), Firebal→Heat(1), Bang→Explosion(2),
Infernos→Wind(3) (via the 3-byte $5C27 tail), Bolt/Lightning/Hellblast→
Lightning(4), IceBolt→Ice(5), BigBang→Fire(0), FireAir grp→(16),
FrigidAir grp→(17), RockThrow→Aid(24), GigaSlash→(25) — GigaSlash is
RECORD-driven (350-410 party / 270-320 enemy), not handler-scaled.

### 15.4 Boss protection — `LoadBtlC_51aa` (bank $53 entry $10)

`$DB73` is the **battle type**, set by `LoadBtlS_43c9` (bank $51 init):
arena→2, wild ($DA09==0)→0, scripted w/ wScriptMapType $5D→2, else
(boss/scripted)→1; $FF = loss freeze. The gate: skills {$12 Beat, $13
Defeat, $14 Sacrifice, $3E Kamikaze, $69 Paralyze, $6B, $71 K.O.Dance}
AUTO-FAIL vs ENEMY targets when db73==1 — instant death and paralysis
never work on bosses, and DO work on wild monsters (validated both ways;
the rig sets $DA09=1 so rig battles are "boss" battles — poke db73=0 to
reproduce the wild condition).

### 15.5 Handler-computed specials (all validated unless noted)

- **MegaMagic** (`LoadBattle_653e`): base = 2·MP + 2·level (level array
  `$DB9B+slot`); variance = 0.1×base (((base×8/10)>>1)>>2), one RNG step,
  RNG1&1 odd -> −(RNG16d mod var) else +. vs MegaMagic res (15) through the
  breath ladder. **The §8-era note "(MP*2+level*2)/4" was WRONG** — no /4.
- **Kamikaze** (`BattleCall_6232`): hit via Sacrifice-res ladder; caster
  HP==1 -> 1; the fork at `$6259` keys on **$C86C (LINK) or db73==0 (wild)**
  -> damage = target current HP − 1 (floor 1); otherwise — that is BOTH
  boss (db73==1) AND arena (db73==2) — (caster HP − 1)/2. Measured: HP200
  -> 249 wild, 99 boss (S78), **99 arena (S79)**. S78's "wild/arena" label
  for the first branch was wrong; "arena" in the damage-layer forks means
  the LINK flag throughout (same finding in WindBeast `$642B`).
- **Sacrifice** (state $D9ED=3 -> bank $53 $67A9): boss gate; res 14
  (packed low pair of $DD2B+slot*7): 3=immune, 2=works only if RNG1<$C0;
  then RNG2<$7F (49.6%) -> damage = target **CURRENT** HP (kill, msg $E9)
  else HP − max(HP/100,1) (~1% survivor, msg $82). `$2FE8` returns current
  HP, not max — **MEASURED S79** with HP 180 / MaxHP 250: kill 180,
  survivor 179, 4/4 branches exact; consumes NO RNG steps (all rolls read
  the ambient state). Caster dies in the state chain.
- **WindBeast** 3L+10 party / 1.5L enemy, cap 180; **Vacuum** 2L+30 /
  1.5L, cap 150; ±half the (mod-)remainder, sign from the shifted-out bit
  (see damage.py for exact polarity per skill).
- **Ramming**: target current HP × 0.8 + 1, Sacrifice-res via ladder A.
- **Beat/Defeat**: pure hit ladder (15.3) then HP=0, presence $DD1B=1.
- **CallHelp/YellHelp**: 50% (RNG1&1) to summon. **Massacre**: random
  target with a $A0/256 gate. **Smashlime/Sheldodge/Branching**: family-
  conditional (traced).

### 15.6 TURN ORDER — traced and differentially validated (S79)

Built each round by **TurnOrderBuild `$58:$54D1`** (battle phase $05's
machine, after the enemy-AI queue fill), validated **143/143 over 47
rounds** (`simulator/turn_order.py` + `validate_order.py` + corpus
`s79_order_events.json`; rig `measure_order.py`, 4 hooks: $54D1 / $5662 /
$55C2 / $5707).

For each combatant with `$DD13[slot]==2` (command queued; 1 = no-action
marker, set by the bank $50 command committers), in slot order:
one `GenerateRNG` step ($00:$12D0), then (`SaveBtlFX_5662`):

```
agl  = max(AGL16, 1)
span = 1 + agl/4 + agl/16          (~31% of AGL)
rand = ((RNG2 & 3) << 8) | RNG1    (10-bit, post-step)
key  = agl - span + (rand mod' span)
```
where mod' is repeated subtraction with an exit-on-EQUAL quirk (result
range is INCLUSIVE [0, span]). Floor: key < 2 -> 2. Action tweaks:
- queued action in {$2A Ironize, $7F Imitate, $88 Cover, $89 Guardian,
  $8C Dodge, $8D Defence, $8E StrongD, $8F SuckAll, $90 BladeD,
  $DC IRONIZE} -> **+$0600** (`SetBtlFX_56cf` — defensive interceptions
  always resolve first)
- $55 SquallHit -> **+$0400** total ($0200 inside 5662 + $0200 in the
  main loop) — the "strikes first" behavior
- $56 PsycheUp -> key forced to **$0001** (always last)
- link peer sentinel: id $10, key $0200, appended when $DB77 != $FF

Keys land in `$DB61` (8×u16) with ids in `$DB4C`, then a descending
shrinking-bound bubble sort (`$55C2`; **ties swap**, and pass 1 literally
compares a 9th out-of-bounds pair $DB71/$DB72+$DB54 — modelled verbatim).
Ties net to slot order in practice (party before enemy at equal keys —
measured). Ids compact into **$DB79** (the round order list), consumed by
bank $53 entry 0 with cursor **$DB82**, which skips dead actors.

### 15.7 The ACTION machine and the damage APPLY step (S79)

Battle phase $07 far-calls bank $52 entry 0 (`$6C4D`): waits on the anim
done-flag $DA82, ticks bank $5F entry 5, then dispatches **$D9ED** through
the 28-entry table at `$52:$6C60` (states $00-$1B; the old ROADMAP knew 8).
State 0 ticks bank $53 entry 0 (per-actor setup, its own sub-machine on
$D9EE; $D9EE==$0B triggers the skill-handler dispatch at `$6CC7`).
$DB77/$DB78 = the pending actor/action pair; action codes >= ~$BA are
META-actions (items/flee/shift etc., not skill ids — e.g. the AI queues
$E9 as a flee-class action).

Bank $53 entry 0's per-actor gate order (`$4558-$45C8`): $DB07&$C0 ->
forced action $11; status +2 bit6 -> $13 (paralyzed); +2 bit7 -> the sleep
wake roll (§15.8); status +5 bits0-5 one-shots -> actions
$12/$14/$15/$16/$17/$18; +2 bit5 curse roll (25%: RNG1<$40 -> bank $53
entry 2 self-hit, can KO); +2 bit4 confusion -> `LoadBattle_7ab5` rewrites
the queued action (RNG1&3 over table $7AFF {$3A,$5E,$62,$80}; attack picks
a random target with a cross-side wrap quirk: candidate&3==0 continues at
absolute slot 2).

APPLY step (state 2, `$6D56` -> the id lists at `$6D83-$6DB8` + block
`$6DB0-$6DE8`): the real gate is descriptor **$DD6F bit5**; id overrides
(skip the HP subtract): $1A RobMagic, $75 OddDance, $76 RobDance,
$71 K.O.Dance, $94 Hustle, $12 Beat, $13 Defeat, and the sub-$3A status
region except $37/$38; transformation specials $29/$AA/$D5 branch to their
own states. HP subtract floors at 0; result 0 or borrow -> KO state $1A
($D9F1=0).

Battle phase $09 (bank $50 `$6AAC`, 6 sub-states) is the **END-OF-ROUND
processor**, not the sequencer: per combatant, +2 bit0 poison -> damage
MaxHP/16 (if >=10: RNG16/6+10), text $E1; +2 bit1 heavy DoT -> MaxHP/6
(if >=30: RNG16/11+30), text $E2; floor 1 pre-cap; KO -> join-candidate
($DD61) + side-wipe -> phase $0A. Then it rebuilds $DD13 (1 = alive) for
the next round's command phase.

### 15.8 STATUS system (S79 — byte map measured per-skill)

Per-combatant 8-byte block at **$DB00+slot*8**. Model:
`simulator/status.py` (sleep wake = exact code port of `$53:$4AEB`).

| byte | bit(s) | status | set by (measured) |
|------|--------|--------|-------------------|
| +2 | 0 | poison (DoT /16) | PoisonHit $67, PoisonGas $6C |
| +2 | 1 | heavy DoT (/6) | (applier not yet identified — OPEN) |
| +2 | 3:2 | sleep counter | applied value $8C = flag+count 3 |
| +2 | 4 | confusion | PanicAll $19 |
| +2 | 5 | curse | Curse $6F |
| +2 | 6 | paralyze (forced $13/turn) | Paralyze $69 |
| +2 | 7 | asleep flag | Sleep $15 / SleepAll $16 / SleepAir $6A |
| +3 | 0 | StopSpell | $17 |
| +3 | 1 | Surround | $18 |
| +3 | 4/5 | transformed | Transform $29 / CHGDRAGON $AA + BeDragon $D5 |
| +3 | 6 | DanceShut | $91 |
| +3 | 7 | MouthShut | $92 |
| +5 | 6/7 | guard / amplify ladder rows (§15.3) | guard cmd / ChargeUp class |
| +5 | 0-5 | ONE-SHOT compulsions (cleared at victim's turn) | LureDance $78 -> bit1, etc. |
| +7 | $C0 | packed turn counters -> forced action $11 | OPEN (phase-9 sub 2 decrements) |

**Sleep wake (`$53:$4AEB`, exact):** at the sleeper's own turn, wake iff
RNG1 <= threshold by counter {3: $60 = 37.9%, 2: $A0 = 62.9%, 1: $E0 =
88.0%, 0: always}; else the 2-bit counter decrements (floor 0) and the
turn becomes the "asleep" action $0F. No RNG step consumed.

### 15.9 What is NOT yet modelled (S80 partial; residuals → S81)

Loop-level differential validation of `simulator/battle.py` (components
engine-exact, glue traced-only); MISS/dodge + $DA33 timer interplay;
meta-actions beyond the option-list observation (flee $E9 class, items,
shift — the state-0 preamble consumes w[3], §15.10.7); AI evaluator rule
chains per effect_class (§15.10.5 — stubbed in simulator/ai.py); enemy
TARGET resolution (queued target stays $FF at commit; resolved later,
site untraced); $dd0b mode assignment at battle init; the player/tactics
plan-adjust values $DB50-52 under each plan; the $DB07 timer statuses and
the +2 bit1 applier; curse self-hit magnitude (bank $53 entry 2); sleep
application counter source; PsycheUp carry-over; interception redirects.

**Hazard for the romhack (S79 finding, ROOT CAUSE FOUND S80):** the AI
re-roll loop lives at $57:$76A9: on an all-vetoed/all-zero pick it does
`$dd02++` and reruns from the category stage WITH NO BOUND CHECK — once
$dd02 walks past the three ranked-id cells ($DCFF-$DD01) it reads
adjacent RAM as "category ids" forever. Enemies given CUSTOM skill ids
must be AI-table-audited (tag byte + evaluator coverage) before the
editor exposes enemy movepools. (S79's "bank $58" attribution was
imprecise — the machine is bank $57; bank $58 entry 11 is only the
cat-1 plain-attack comparison service, §15.10.6.)

### 15.10 ENEMY/TACTICS AI — bank $57 decision machine (S80, traced + validated 26/26)

Built S80, NOT yet user-tested. Model: `simulator/ai.py`; rig:
`simulator/measure_ai.py`; validator: `simulator/validate_ai.py` (26/26
checks over 10 EIDs incl. weightless EID 0). Phase 5 / $d9ed=1 runs this
per actor; sub-state $D9EE, stages at $7129 ent / $73b9 cat / $7529 sum /
$7439 filter / $75a2 pick / $7859 post.

**15.10.1 Inputs.** Battle init fills, per combatant slot: category base
arrays $DC44/$DC4C/$DC54[8] and $DC5C[8] from enemy_stats ai_weights with
mapping +17→cat1, +19→cat2, +18→cat3, +20→$DC5C (w[3]; consumed by the
state-0 act/flee preamble as $db4d=w3/10, not by the category machine);
and the OPTION LIST at $DC64+idx*16: up to 4 pairs {tag, skill}, tag =
skill record effect_category hi-nibble (1 dmg/2 status/3 heal), skill
$FF-terminated on the odd bytes, $00 on the even. The player-hero slot's
list holds meta-actions (e.g. $E9 flee class) tagged 1.

**15.10.2 Category scores** (FuncBtlAI_71b9 → SaveBtlAI_72ce), one
GenerateRNG step each, byte-swapped 16-bit dividend (S78 rule):
`score[c] = base[c]//10 + plan_adj[c] + r16' % mod` with mod=10 for
player slots (<3) and link, else the base ladder <50→30, <100→25,
<150→20, ≥150→10. plan_adj = $DB50/51/52 (cat1 adj is skipped for
enemies; cat2/3 adjs apply unconditionally — 0 outside player plans in
all measurements). Heuristics: +$1E to cat1 if the actor's status+3 &
$0C or status+6 & $33 (magic-limited → prefer attack; exact trigger
statuses unmeasured); $dcfe −$1E floor-0 when $db76==0 (heal-category
nerf, LoadBtlAI_719b); the finisher scan when $dd0b==2 (any opponent
below MaxHP/6 → option-list walk, tail untraced).

**15.10.3 Ranking** (LoadBtlAI_7322) — exact quirky partial sort over
cells $DCFC/D/E with ids seeded 1,2,3 in $DCFF/$DD00/$DD01: (1) cat1 vs
cat2 → possible rank1/rank2 id swap, winner kept; (2) winner vs cat3 →
possible rank1↔rank3 id swap ONLY (rank2 untouched — ranking can be
non-sorted); (3) **LoadBtlAI_73a5: iff cat1 is NOT rank1, +$1E to cat1's
CELL** (the "attack as perennial runner-up" bonus — note the hidden
rank3 check at $73AB, see KEY_LESSONS S80); (4) rank2 vs rank3 by their
(possibly bumped) cells → possible id swap. $DD02=3 (cursor at rank1).

**15.10.4 Per-skill sum** (Jump_057_7529): for every listed pair
regardless of category, `$DCE4[i] = record_ai_weight(skill) + r16'%16`,
saturating $FF; one RNG step per skill. The chosen category id for the
current attempt is $DD6A = [$DCFC + $DD02].

**15.10.5 Filter + evaluators** (Jump_057_7439): zero $DCE4 entries
whose tag ≠ $DD6A; each surviving skill fetches record flags7 → $DD6B
and dispatches state 7 through the per-category dw tables at
$57:$4308/$4358/$4404 (misdisassembled as code; plausibly indexed by
effect_class). Rules accumulate the 16-bit $DD26/27 in +$0A steps, high
byte $FF = veto (ReadBtlAI_750c contract). Measured writeback on the
traced decisions: dce4[c] += 50 with $DD26 ending 60; per-chain
semantics NOT yet traced — simulator/ai.py stubs this (RuleChainStub)
and loop validation will flag decisions where the stub is wrong.

**15.10.6 Pick** (Jump_057_75a2). Status overrides first (attacker
block): +2 bit4 (confusion) → force $3A; +6 bit2 → force $42; +7 bit4 →
force $95. $dd0b==0 → the LIGHTWEIGHT picker Jump_057_76DF (no per-skill
RNG; observed choosing by top-category tag match — EID 37; tail
untraced). Else argmax over $DCE4[0..6], first-nonzero seeds, tie →
one RNG step, RNG1 bit0: 0 keep incumbent / 1 take challenger. All-zero
→ retry $76A9 ($dd02++, rerun from category stage — UNBOUNDED, see
§15.9 hazard). Epilogues by chosen category: cat1 → far-call bank $58
entry 11, returns a plain-attack score via $DD26; if ≥ best skill score
→ queue plain Attack $3A; cat2 → commit; cat3 with best <$14 → extra
checks (LoadBtlAI_77a4/77b4, untraced) that can retry, fall back to $3A,
or queue Defence $8D. Commit writes the WINNING SKILL id to
$DCEC+idx*2; the target byte stays $FF (resolved later, site untraced).
Winner skill $FF → $3A.

**15.10.7 State-0 preamble** (pre-$7129, ~$6EC1): plan read
(wMenu_selection / link $C1D5-6) → $DD72; w[3]-derived $db4d
(LoadBtlAI_7905) + threshold ladders on cat bases (FuncBtlAI_791a,
b=0/9/18 rows — the personality-table row group offsets) feed
LoadBtlAI_7a5d: carry → clear $DCEC pair to $FFFF, set bit6 of
$DD03[idx], run the machine (plan $81 "Command" diverts to the direct
path via $DD03[idx]==3 at $714E); no-carry → alternate outcome at
$6F8C (flee/loaf class, untraced).
