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
(those follow from the record). Authoring a *visible* custom animation remains
blocked on the `$5f` disassembly cleanup (DOC_AUDIT #15) — separate item.
