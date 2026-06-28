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
