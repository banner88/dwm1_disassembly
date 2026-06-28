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
- Animation/effect **dispatch**: descriptor-setters set `$dd6f`+`$dd70`; the
  effect-script pointer flows to bank `$4c`/`$55` (§9).

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
- The effect-script **bytecode format** and its `$b000`-region backing are NOT
  reversed (the remaining animation-authoring sub-item; §9).
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

## 9. Animation / effect dispatch (#2)  [dispatch PROVEN; bytecode format OPEN]

**Animation is chosen by the HANDLER, not the record.** Each handler ends by
calling one of ~12 **descriptor-setters** (`$52:$5460–$54f8`, annotated) that set:
- `$dd6f` — effect DESCRIPTOR bitfield. **bit7 = has-effect** (the consumer's
  gate). Other bits select mode: Blaze=`$a8` (bit7+5+3); family is
  `$80/$84/$88/$90/$93/$98/$a0/$a8/$d0`, plus `$40`=flag-only (no pointer).
- `$dd70/71` — effect-SCRIPT pointer. Blaze's setter `SetHLBattle_54e7` hardcodes
  `$b882`.

**Flow / consumer** (`bank_053` `jr_053_5a6f`): reads `$dd6f`; if bit7 set, hands
`$dd70/71` → `$c822/$c823` to **bank `$4c`** (the effect/message script engine,
`CallTextEngine`) and **bank `$55` entry 1** (sprite-animation trigger). So battle
effects are interpreted **bytecode scripts**, not raw frames. `$dd6f` bit5 selects
the `$db56` alt pointer; bits 3/4 gate sub-effects.

**Pointer space:** effect-script pointers live in `$b6xx–$bcxx`. `$b682` is the
shared default (28 handlers); generic spell-damage uses `$b882`; a few skills have
unique pointers (`$b886/$b888/$b88a/$b88e/$b895/$b898/$b8e8/$bb84/$bccc`).
(`$b0b0/$b2b2/$b5b5` are `a:a` flag-values from `ApplySkillDamage`, not pointers.)

**For goal #2 (custom animations):** to REUSE an existing animation on a custom
skill, point its handler at a different `$bXXX` setter — low-risk, no new data,
and it frees a custom skill from inheriting Blaze's `$b882`. **OPEN sub-item:** the
effect-script **bytecode format** and its `$b000`-region backing are not reversed
(`$dd70` is passed as a handle to bank `$4c`, not dereferenced inline). Reversing
the bank `$4c` effect interpreter = "animation authoring", the next discovery item.

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
| Effect descriptor / script pointer | `$dd6f` / `$dd70`–`$dd71` |
| Effect-script / sprite engines | bank `$4c` (entry 0) + bank `$55` (entry 1) |
| FX router (id-range split) | `SaveBtlFX_43ff` `$58:$43FF` |

**Tools:** `tools/gen_skill_records.py` (decodes records → JSON, 7 ROM sources
incl. battle_record), `tools/build_skill_tables.py` (round-trips function/MP/learn
+ record ptr/data; `--selftest`, `--emit {func,mp,learn,record,recordptr}`).
