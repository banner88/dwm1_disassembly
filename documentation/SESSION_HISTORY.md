# SESSION HISTORY — Cold Archive (do NOT read at session start)

> Last verified: 2026-10-03 (Session 114 — **ROADMAP P3.13a: THE ENCOUNTERS TAB — LISTS OF
> YOUR OWN, A LIST PER GATE FLOOR, ROOMS WITH THEIR OWN LIST, FLAG VARIANTS, BATTLE RATES**
> (user on the audit: "1) Music next is fine. 2) Give option. Especially if I want to
> insert custom rooms with its own encounters. 3) Gate too, great idea. 4) Yes separate
> rate is good. 5) Doesnt matter. 1 random unused gate is irrelevant … 6) Ranges for now is
> fine, just keep in mind future real fight-length numbers for balance and prepare for it.
> … I WANT TO MAKE NEW GATES. This includes a) random gates just like vanilla - maybe copy
> a vanilla gate and edit encounters & link to new boss room, and b) FULLY CUSTOM GATES -
> ie series of rooms with branching structures, with per-room encounters settable" — the
> new gates are ROADMAP arc NG; P3.13 was split into a (this) / b (Music, next)).
> **Test ROM `DWM_S114_encounters_test.gbc` (`241c458b…`, patched) USER-CONFIRMED 2026-10-03 09:52 ("Looks good. Give editor files")**; the editor half test_app-verified, not yet run on the user's Mac.
> Verifier PASS (6/6; check 5 += `dump_encounters.py`); clean `1ca6579…` byte-perfect
> (bank $01 encounter code + bank $16 counter / rate tables annotated in both trees:
> comments only); **patched pin `dbc4dee9…` (patched)**, was `8cf0b93b…` (patched,
> historical); the user's project (my-dwm-hack_6) as-is now builds `0a45fbf4…` (patched)
> and draws exactly the vanilla way (census below). test_compiler --rom 818/818, test_app
> + test_app --rom PASS (GUI build == pin), test_canvas --rom PASS. `EDITOR_REVISION` =
> 'S114'. S113's and S111b's test ROMs USER-CONFIRMED 2026-10-03 00:19 ("Tested, works").
> Also: the verifier's hand-staged patched build == the pin again (`patches/bank_041.asm`
> regions had drifted from the compiler's output — regenerated); `audit_mapid_range.py
> --selftest` PASS again (9 sites since S100 adjudicated, json regenerated).
>
> **Built (PROJECT_COMPILER §2.30, DATA_STRUCTURES "Encounter list choice (S114)",
> EDITOR_DESIGN §5.5 "As built S114", help `59_encounters.md`):** bank $01
> `LoadNextDungeonFloor` SAME-SIZE fork → NEW compiler bank **$76** `EncResolve` (template
> `bank_076_head.asm`): the vanilla gate+floor rule on byte copies of bank $01's tables, a
> gate's own per-floor plan, a CUSTOM room's own list (no gate pin — works inside a dive),
> flag variants (first whose terms hold), a room's rate code; the chosen list is copied
> to `wEncListBuf` ($D11E) and the five list readers read it (`ld hl` + `ld bc, $0000`, same
> size); `wEncounterPoolIndex` keeps the floor's vanilla number (floor gold). Schema:
> `custom.encounter_lists` (numbers 128-255), `custom.rooms[].encounters.{list, variants,
> rate}`, `custom.gates[].encounters.{floors, variants}`. Editor: the **Encounters** tab
> (Lists: all 128 + yours, usage, real chances, staged slot edits + Apply, the commonest
> battles, New list (copy); Gates: a list per floor, flag variants, shared-list warning;
> Rooms: off / a gate floor's list / the dive's / its own + variants, own rate); the Rooms
> tab knows "its own list"; Monsters "where met" + the pool dialog use the live usage.
>
> **Measured:** `tools/census_encounters.py` (stub calls, RNG pinned): ORIGINAL ROM vs the
> vanilla model 633 list choices + 15,192 battle draws, 0 mismatches (negative control
> 1,417); the example, a lists / variants / rates fixture (641 + 15,384), the user's
> project and the demo: 0. Field, on the user's save (demo = the user's project + "Howling
> Den", a new red room behind the GreatTree 2F Library door, NOT in their project): the
> den's own list only (Hork / DragonKid / Golem), the keeper's YES sets `den_night` → the
> night list (Gremlin / Spooky / Shadow), rate code 7 = a drain of 200 per step (1,700 → 8
> steps); Gate of Beginning floors 1-2 → a project list (DragonKid), floor 3 → the user's
> own list 0 (Anteater, Klamutra), with the flag every floor → the night list; the guide's
> YES returns to the GreatTree. **Found + corrected:** the draw = first running sum ≥ (or
> = 100) the draw, the draw = (wRNG2:wRNG1) mod 100 — the first slot +1 point;
> `encounters.json` floor ranges one floor late (tool rewritten + regenerated); the
> counter IS re-seeded at every room load (bank $0B Entry 0 → bank $16 entry 6; KEY_LESSONS
> S11 corrected); wC8A9 = the list's rate code at every step; a same-size fork must leave
> BC = 0 like the `Mul16x8To24` it replaced (KEY_LESSONS S114, caught by the census).
> **Hand-off:** every S114 change = the diff against `c37879e` (origin/master, the S113
> push), delivered as `DWM-S114-encounters-changed-files.zip`, the APPLY list pasted in the
> chat. **Next:** P3.13b Music tab (user); then ARC NG (new gates — questions asked S114).


> Last verified: 2026-10-02 (Session 113 — **ROADMAP P3.12: THE BREEDING TAB — EVERY
> RECIPE, EVERY MONSTER'S DEPTH, "TRY A CROSS", AN AUTO-ORDERED SPECIAL TABLE, A TREE
> GENERATOR — AND THE FX1 EGG-PLUS BUG FIXED** (user on the audit: "1) [mutation] No I
> have no idea where it came from. Monsters with + can have different breeding route,
> thats it. Scope: 1) Fold in [the generator] if possible … 2) No gifts. You can get egg
> from skydragon if it plops on your head. however, IN ROMHACK THERE WILL BE EGG REWARDS.
> 3) [plus in depth] you decide. 4) Auto order sounds good. Keep in mind I will mess with
> vanilla breeding table HARD in this romhack and try multiple iterations. Also we have
> new sprite family, this is important to be aware of! 5) [offspring skills] you decide").
> **Test ROM `DWM_S113_breeding_test.gbc` (`56b35922…`, patched) USER-CONFIRMED 2026-10-03 00:19 ("Tested, works")**; the
> editor half test_app-verified, not yet run on the user's Mac.
> Verifier PASS; clean `1ca6579…` byte-perfect (bank $16's breeding resolver annotated in
> both trees: `BreedCreateOffspring` / `BreedResolveOffspring` / `BreedResolvePreview` /
> `BreedFamilySearch` / `BreedFamilyScan` / `BreedPlusAndSpecial` /
> `BreedSpecialEntryCheck` / `BreedGenderThreshold` / `BreedClearRareFlag` /
> `BreedRareMutation_Unreferenced` / `CountSeenInRange` / `NthSeenInRange` /
> `InheritSkillList` / `InheritOneSkill`; labels / comments only — closes the Phase D
> "bank $16 breeding-determination internals" item); **patched pin `8cf0b93b…`
> (patched)**, was `9ce03bd0…` (patched, historical); the user's project (my-dwm-hack_5)
> as-is now builds `3a09e1b2…` (patched; was `c90a69c2…`, historical — the bank $16 fix
> only: it has no breeding edits). test_compiler --rom 773/773, test_app + test_app --rom PASS (GUI build == pin).
> `EDITOR_REVISION` = 'S113'.
>
> **Measured (BREEDING_SYSTEM "The resolver as measured (S113)"):** the Python model
> `editor2/core/breeding.py` == the game: `tools/census_breeding.py` stub-calls bank $16
> entry 2 for every ordered pair of parents (0-214 + new species), a plus sweep and a
> random sample (53,156 calls, 0 mismatches; negative control — no family second pass —
> 31,433 mismatches) and the EGG ITSELF through entry 0 with the real staging records
> (300 / 300). **No mutation:** `$16:$44DA` has no caller (ROM-wide call/jp search; 0
> executions in the census), so `$D9E6` is never set and the bank $0D "Wow! It's a rare
> breed!" line never shows (the old "~1-5 % mutation" doc claim was wrong).
> **FOUND + FIXED (FX1 regression, S71 → S112):** `BreedCreateOffspring` still put the
> parents' slot NUMBERS 20/21 in `$DA75/$DA76`; since FX1 those are farm slots 20/21 in
> SRAM (the staging records are indices 40/41), so every egg's plus + level bonus came
> from those slots — empty: every egg +1 and no "+N" recipe ever fired (the shrine
> PREVIEW, which passes the real slots, still showed the right answer). Now `$28/$29`
> (same size, `patches/bank_016.asm`). PyBoy through the real shrine menus on the user's
> save, MadCat × BattleRex with a +2 route: before Yeti +1, after GoldSlime +2.
>
> **Built (PROJECT_COMPILER §2.29, EDITOR_DESIGN §5.4 "As built S113", help
> `58_breeding.md`):** the special table is AUTO-ORDERED whenever a project edits it
> (species × species, species × family, family × species, family × family, higher min
> plus first — vanilla's own 825 sorted this way give identical results for every pair
> and plus); `special.removes`; `special.table` (the whole table, for heavy rework / the
> generator); two rows with the same parents + min plus refused. Analysis
> (`breeding.Analysis`): obtainable without breeding (wild joinable rows, starter, boss
> joins, vanilla script gifts — SkyDragon egg, farm Slime eggs, Watabou, StoneMan — and
> the project's `add_monster` egg rewards), depth from the resolver (vanilla: deepest
> DeathMore 9), what makes / what it makes, rows that never fire, library pages that do
> not give their monster. Generator `editor2/core/breed_gen.py` (the randomizer's
> depth-profile builder on the project: 11 families, new species, pinned monsters; S113b:
> any depth up to 40, one share box per depth — the ceiling is the number of monsters
> not obtainable without breeding).
> **Breeding** tab: By monster (depth, how you get it, Made by / Makes, add / change /
> remove), Try a cross, depth chart vs original, Problems; Special recipes (the whole
> table in scan order); Family recipes ("works for n of m"); Work on the whole table;
> Generate a tree….
> **Measured in PyBoy on the user's save, through the Old Man's BREED menu (S113 test
> ROM = the user's project + a demo overlay authored through the editor model, NOT in
> their project):** Healer × BattleRex → "I suspect Klamutra+2 will be born" → Klamutra
> +2 (a new species × species row beating the vanilla [Slime] × [Dragon] family recipe);
> MadCat × BattleRex → GoldSlime +2 (a +2 row; levels 23 + 23); Dragon × BattleRex →
> Dragon +2 (original row 755 [Dragon] × BattleRex → GreatDrak removed).
> **Open / to ask:** boss gender (the 15 boss species have female ratio 0 = always
> male by `BreedGenderThreshold`, yet vanilla recipes pair two of them — no gender rule is
> modelled); offspring skills / stats in "Try a cross" (bank $16 entry 4) = ROADMAP
> residual; family "last match wins" is code-read (no project data has exercised it).
> **Hand-off:** every S113 change = the diff against `56daf61` (origin/master, the S112
> push), delivered as `DWM-S113-breeding-changed-files.zip`, the APPLY list pasted in the
> chat. **Next:** the user's pick (P3.13 Encounters + Music is the next mandatory box;
> P3.11b AI ban-list optional).


> Last verified: 2026-10-02 (Session 112 — **ROADMAP P3.11e: SKILL ANIMATION EDITING —
> NEW BATTLE ANIMATIONS MADE FROM THE GAME'S FRAMES, AND WHAT EACH SKILL SHOWS** (user on
> the audit: "Sounds perfect. The in-built editor viewer and sound playback is the
> perfect way to do it. 1) New tile art later. 2) Stock tiles should all be fine, this
> will be 5-10 mashup skills at MOST on top of vanilla ones. 3) Same as vanilla. 4) yes I
> want to choose. 5) Preview in editor enough, I can assign to monster and build. 6) One
> session preferred. 7) No idea."). **Test ROM `DWM_S112_animations_test.gbc`
> (`16f7a43d…`, patched) USER-CONFIRMED 2026-10-02 18:29 ("Fantastic, everything checks out")**; the editor half test_app-verified, not yet run on the user's Mac.
> Verifier PASS; clean `1ca6579…` byte-perfect (the animation system re-sectioned and
> labelled in banks $00/$02/$17/$50/$5A/$5B/$5C/$5D/$5E/$5F by
> `tools/resection_battle_anims.py` + the debugger's shade copy `EffectDebugShadeTable`
> and the ROM0 tick / bank $50 `$DA80` comments by hand; labels / data / comments only);
> **patched pin `9ce03bd0…` (patched)**, was `5a1c5404…` (patched, historical); the
> user's project (my-dwm-hack_5) as-is now builds `c90a69c2…` (patched; was `c3499e39…`,
> historical) and plays exactly as on S111 (PyBoy A/B, RNG pinned). test_compiler --rom
> 754/754, test_app + test_app --rom PASS (GUI build == pin). `EDITOR_REVISION` = 'S112'.
>
> **Built (PROJECT_COMPILER §2.28, BATTLE_SKILL_SYSTEM §11.9, EDITOR_DESIGN §5.3 "As
> built S112"):** `custom.animations` = NEW animations $2D-$4C (≤ 32), each a list of
> steps — a frame of one of the 45 stock animations + how long it shows, a sound cue, a
> blank; ≤ 4 source animations (one OBJ palette each), ≤ 128 tiles. The compiler gathers
> the frames into bank **$6F** (engine template `bank_06f_head.asm` + generated tables)
> and their tiles into one sheet per animation in bank **$70**.
> `gamedata.skills.<id>.presentation` = an animation (stock or new) + motion (at the
> target / middle / each target / flies across), a screen effect (11), or nothing —
> regions `gd_anim_routine` / `gd_anim_cmd` (bank $5F, by real skill id), applied on the
> sides where the look shows something (vanilla sides, user). Forks: ROM0 two operands,
> NEW hand patch `patches/bank_002.asm` (`ReadSeqStepFork`), bank $50 `AnimLoadFork50`,
> bank $5F routine / number forks + the developers' viewer (mode 5) listing $00-$4C.
> Editor: NEW **Animations** tab (list, playing preview with the game's own sounds —
> `extracted/anim_sounds/`, recorded from the ROM's sound engine —, steps with
> thumbnails and frame counts, Add frames… from any stock animation, Add sound / blank)
> and the Skills tab's **Animation** section (with preview); help `57_animations.md`
> (new), `54_skills.md`, `00_start.md`.
>
> **Found (BATTLE_SKILL_SYSTEM §11.9 — corrects §11.1-11.5):** the per-skill
> `$56ED`/`$57D5` byte is the ANIMATION NUMBER (frames + timeline + tiles + colours), not
> "sound + flash"; the sounds are `$FD` cues in the timeline; the timelines are bank $02
> sequencer row $60 (`AnimTimelineTable` $46A1); the routine index (16 routines,
> measured) picks the motion / a screen effect / nothing; the OBJ colours pass through
> the DMG shade with the order [1,2,0,3] (identity $D2) — measured on SCREEN; game mode 5
> is the developers' "Effect" animation viewer. Stale: DOC_AUDIT #15's "map-script"
> blocker (bank $0F's labels at the same addresses); bank $50's "$DA80 master-intro" label; PROJECT_COMPILER's `StockPresentTable
> $7EEB` (it is $7EDA).
>
> **Measured in PyBoy on the user's save:** the developers' viewer census
> (`tools/census_battle_anims.py`): all 45 stock animations = the decoded model frame by
> frame (frames, timing, sounds, tiles, colours; negative control 45/45 fail) and the
> demo's $2D / $2E = the editor's model. Battles (RNG pinned, 14 cases, no stall): the
> demo overlay (NOT in the user's project, authored through the editor model) — Zap →
> "Spark storm" $2D (Zap's opening + bolt, then Bang's burst) on each foe, MetalCut →
> "Frost slash" $2E (TwinSlash's cut + IceStorm's shards) at the target, Scorching → the
> screen blink, EvilSlash → stock $26 (GigaSlash); IceStorm / Blaze / Firebal / Bang /
> HealMore / enemy Zap → party unchanged; an enemy's HealMore on itself showed $2D in the
> first demo build. **Test ROM `DWM_S112_animations_test.gbc` = that demo — USER-CONFIRMED 2026-10-02 18:29 ("Fantastic, everything checks out").**
> **Hand-off:** every S112 change = the diff against `a5f28f6` (origin/master, the S111b
> push), delivered as `DWM-S112-skill-animations-changed-files.zip`, the APPLY list pasted
> in the chat. **Next:** the user's pick (P3.11b AI ban-list is optional; P3.12 Breeding
> tab is the next mandatory box).


> Last verified: 2026-10-02 (Session 111 — **ROADMAP P3.11c + P3.11d: THE CUSTOM SKILLS AS
> PROJECT DATA, NEW CUSTOM SKILLS FROM STOCK ONES, AN ELEMENT FOR EVERY SKILL** (user on
> the audit: "1) Yes start with vanilla but given 3.11d is kind of tied, dont feel
> prohibited from diving into it as well. 2) New custom skills should also be able to be
> added from a) further sessions with you and b) from mix/matching existing skills and
> fiddling with their animations. These will be damage skills without new logic. 3) Are
> current skill elementals editable? If not, add that. Also consider quake elemental
> damage. 4) fix [the sound overshoot] 5) Sure, dont care just make sure its reasonable and
> consistent [the schema]"). **Test ROM
> `DWM_S111_custom_skills_test.gbc` (= the demo below) USER-CONFIRMED 2026-10-02 15:08
> ("Looks good")**; the editor half test_app-verified, not yet run on the user's Mac. Verifier PASS; clean `1ca6579…` byte-perfect
> (bank $50 `SkillNameSubst_5ae1` decoded as data + comments, bank $52 dead-pocket note;
> labels / comments only); **patched pin `4a2860cf…` (patched, historical
> since S111b — now `5a1c5404…`)**, was `534bfb62…` (patched, historical); the user's project (my-dwm-hack_5) as-is now builds `e7a0577f…`
> (patched; was `fc54da9b…` on the S110 tree, historical). test_compiler --rom 710/710,
> test_app + test_app --rom PASS (GUI build == pin). `EDITOR_REVISION` = 'S111'.
>
> **Built (PROJECT_COMPILER §2.27, BATTLE_SKILL_SYSTEM §13.9 + §15.3, EDITOR_DESIGN §5.3
> "As built S111", TEXT_SYSTEM battle-line codes):** `gamedata.skills.<224-233>` edits the
> ten built-in custom skills' DATA (name, text, MP, learn row / not learnable, record
> fields — not the power words —, looks, sounds, element, own announce line or a stock
> one, Tame meters, Quake power, the Quake / Mourn banners, Anchor's dialogs);
> `gamedata.skills.<234-254>` = NEW skills (`base` = the stock skill whose effect runs,
> 114 measured bases); `element` for any skill (stock too). 19 compiler regions over the
> custom skills' bytes in banks $07/$41/$4C/$54/$55/$56/$58/$5F/$72 (baseline
> `editor2/core/custom_skills.json` = the S110 pin's bytes; with no edits the regions
> reproduce them — tested, and `extract_custom_skills.py` reads them back out of the
> build). Engine: bank $72 `FarSkillFork` → `CustomBaseTable`, entries 5 `ElemLevel72` /
> 6 `CustomLearnRow72`; bank $52 24 ladder calls → `ElemLadder*` in the dead $51B3 pocket
> + `CustomElemTail52` (Quake etc. take an element); bank $06 learn scan through
> `wLearnRowBuf` $D10C; bank $58 `CustomTargetBaseTable`; per-id tables span $DE-$FE.
> Skills tab: custom / new kinds, New skill… / Delete, Learnable, Element, Sounds like,
> Announce, "Its own numbers and lines"; help `54_skills.md`.
>
> **Fixed (measured):** (1) `{skill}` in battle lines printed "CleanCut" for custom ids
> (bank $50 `SaveBtl_5ad2` indexed a 4-B table → code; now same-size bounded); (2) custom
> ids' cast sounds read past bank $55's 222-B SFX tables (next kind's rows; from the last
> table, code) → `CustomSfxTable`, default $09 = the party-side sounds they had.
>
> **Measured in PyBoy on the user's save:** element census (38 elemental skills; S110 and
> S111 builds identical with the RNG pinned — unpinned, CallHelp drifted: KEY_LESSONS
> S111); clone census (114 same / 41 differ / 67 not a skill); Blaze → Ice vs a level-3 Ice
> target = 0 damage, Quake → Fire on a level-1 target, Spark → Lightning; the 10 built-ins
> A/B vs S110 (same lines / acts / MP); a Blaze copy = Blaze; real level-ups learning the
> Rumble … QuakeMost chain and Scorching → FrostBite. The demo `b8a5b8ea…` (patched) = the
> user's project + an overlay NOT in their project: 229 Tremor → "Rumble" (MP 8,
> Explosion, own line "{name} makes / the ground rumble!", power 60-80, learnt after
> MetalCut), 234 "Thunder" (Zap's effect, Bang's look + sounds, power 60-75), 235
> "FrostBite" (Scorching's effect, IceStorm's look + sounds, IceBreath) — party and enemy
> casts, the SKIL menu (name, MP 8, text; "Cannot use now." in the field).
> **To mention / open:** 41 bases refused until traced (heals among them — possibly partly
> a rig effect); 21 new-skill slots; custom names share bank $41's spill extents with the
> renamed originals; new animations composed from frames = P3.11 residual (f), not built.
> **S111b (same session, user 15:20 "Fix it now"; built, test ROM
> `DWM_S111b_skill_ratios_test.gbc` NOT user-tested — user 15:38: "Not interested in rom
> give editor files"):** the built-in custom skills'
> fixed RATIOS are project data — MagicBurn `burn` (1/2) + `damage_per_mp` (1), Tame
> `damage_of_atk` (1/4, per tier), Anchor `mp_charge` (3/4), Quake `ally_damage` (1/3, per
> tier), Mourn `per_fallen` (1) → bank $72 `CustomRatioTable` (region `gd_custom_ratios`)
> read through `ScaleHL72` (floor(x·n/d), at most 999) + entry 7 `AnchorKeepMP72` (bank
> $73's arrival charge); Skills tab "Its own numbers and lines". PyBoy on the user's save:
> defaults == before (A/B identical); the test ROM's edits measured (MagicBurn spends 50 of
> 200, damage 3× before the foe's ladder; Quake allies 30 of 60; Tremor allies 0; Mourn
> with 2 fallen 500 instead of 750; Anchor keeps 101 of 203). **Found + fixed:** under the
> act-time AI (FIGHT / tactics / enemies) MagicBurn and Tame ×3 hit the CASTER'S OWN SIDE
> (their AI target row was the S84 self row $6367; measured, the same since S84) →
> `CustomTargetBaseTable` MagicBurn = Firebal's row, Tame = Blaze's. **Found, not
> changed:** with several foes MagicBurn spends again per foe on what is left (200 MP:
> 100 + 50 + 25), as since S49. Pin `5a1c5404…` (patched), was `4a2860cf…` (patched,
> historical); the user's project as-is builds `c3499e39…` (patched). test_compiler --rom
> 727/727, test_app + --rom PASS.
> **Hand-off:** every S111 change = the diff against `1e919dd` (origin/master, the S110
> push), delivered as `DWM-S111-custom-skills-changed-files.zip` (S111b: re-cut at 15:38 with the
> ratios, on the user's request without a ROM test), the APPLY list pasted in the chat. **Next (user 2026-10-02 15:08: "Yeah, make sure that's next"): ROADMAP P3.11e —
> skill ANIMATION editing** (new animations from existing frames; groundwork first: the
> frame-table re-section of banks $5C/$5D/$5E and the bank $5F per-skill tables, a PyBoy
> trace of frame timing and tile loading).


> Last verified: 2026-10-02 (Session 110 — **ROADMAP P3.11: THE SKILLS TAB — THE 222
> ORIGINAL SKILLS: NAMES, SKIL TEXTS, MP, LEARNING, POWER, TARGETS, AI, BEHAVIOUR BITS,
> "LOOKS AND SOUNDS LIKE"** (user on the audit: "Start with vanilla skills and add custom
> skills if there is scope and context / 2) in scope [names + texts] / 3) yes editable
> [target mode] / 4) show and give hover hints what they do; use help tab. If they are
> genuinely useful, let me edit [the poorly-understood record fields] / 5) Offer [looks
> like skill X] / 6) Edit in item tab [battle items] / 7) Your choice [announce line →
> read-only]"). **Test ROM `DWM_S110_skills_test.gbc` USER-CONFIRMED 2026-10-02 09:09 ("Excellent work. Give me editor files")**;
> the editor half test_app-verified, not yet run on the user's Mac. Verifier PASS; clean
> `1ca6579…` byte-perfect (bank $56 SKIL texts + pointer tables re-sectioned by
> `tools/resection_skill_desc.py`; 60 record-reader sites + the FIELD MAP header +
> bank $54 entries 3/4/5 relabelled by `tools/annotate_skill_record.py`; comments /
> labels only); **patched pin `534bfb62…` (patched)**, was `482c949f…` (patched,
> historical) — the two looks proxies + the example project's skill 215 rename moved out
> of a hand edit; the user's project as-is now builds `32133c7c…` (patched; was
> `f995cb88…`, historical). test_compiler --rom 650/650, test_app + test_app --rom PASS
> (GUI build == pin). `EDITOR_REVISION` = 'S110'.
>
> **Built (PROJECT_COMPILER §2.26 + §2.20, BATTLE_SKILL_SYSTEM §7 / §11.8, TEXT_SYSTEM
> "Skill text blocks (S110)", EDITOR_DESIGN §5.3 "As built S110"):**
> `gamedata.skills.<0-221>` gains `name` / `description` / `looks_like` → regions
> `gd_skill_names` ($41), `gd_skill_desc` / `gd_skill_desc_ptrs` / `gd_skill_desc_extra`
> ($56), `gd_present_proxy_5f` (`StockPresentTable`, read by `GetPresentId` for ids <
> $DE) and `gd_present_proxy_55` (NEW hand patch `patches/bank_055.asm`: the one SFX-table
> reader `$55:$4061` → `call SfxPresentId`). `mp` now writes both MP copies (field `$07`
> u16 + battle record +4); "ALL" for Farewell / MegaMagic only; `target_mode` from five.
> New **Skills** tab (sections: text with the game font, MP + learning, power, targets,
> AI, behaviour boxes with hover hints, looks, who has it; battle items read-only; the
> announce line read-only); help `54_skills.md`; other tabs follow skill renames.
>
> **Found (foundational — the RECORD READER CENSUS, BATTLE_SKILL_SYSTEM §7):** every
> byte / bit of the 19-byte record has a named reader or is proven unread: +0, +1 low
> nibble, +7 b2, +8 b3, +9 b6/b7 NOT READ; +4 is the BATTLE MP cost (menu, act time,
> deduct, AI veto — the old "reader untraced" warning retired); +5 is the AI's assumed
> element (not "status_id"); flags7/8/9 = breath / dance / spell seals, reflect,
> redirect, iron, crits, TwinHits, ChargeUP, dodge, TakeMagic, Imitate, confusion snap,
> airborne reach; +10 items only. Bank $54 entry 3 = the side power read ($52C7; docs
> said entry 5 / $535F = the item lookup); the $55 SFX reader is $4061 (docs $4067);
> S44 had renamed skill 215 by hand inside the names block (DOC_AUDIT S110).
>
> **Measured in PyBoy on the user's save:** (1) the LOOKS census
> (`tools/census_skill_present.py` → `extracted/skill_present_census.json`): 222 donors
> × 7 borrowers = 1,554 battles, every borrower acted 4-9 times, longest frozen action
> machine 157 frames — **no stall** (the first pass was void: the AI replaced the forced
> skill at act time — KEY_LESSONS S110); a cross-side look shows nothing (Heal with
> Bang's look); (2) the demo `ed8222b2…` (patched) = the user's project + a demo overlay
> NOT in their project: Zap → "Spark" (SKIL menu: name, "Sparks leap at / every foe",
> USE MP 1; battle "Slib casts Spark!" with Bang's look, 78/77/78 to three foes),
> MetalCut aimed at all foes (hits all three; one in the original), HealMore → "Cure" (+200 HP for 1 MP).
> **Test ROM `DWM_S110_skills_test.gbc` (= that demo) USER-CONFIRMED 2026-10-02 09:09 ("Excellent work. Give me editor files").** **Hand-off:** every S110
> change = the diff against `bf8bb5f` (origin/master), delivered as
> `DWM-S110-skills-tab-changed-files.zip`, the APPLY list pasted in the chat. The user also
> asked how hard building new skill animations from existing frames would be — answered
> in chat from BATTLE_SKILL_SYSTEM §11 (no new measurement; ROADMAP P3.11c residual).
> **Next:** P3.11c (the custom skills as project data) or the user's pick.

> Last verified: 2026-10-01 (Session 109 — **ROADMAP P3.10b: THE ARENA EDITOR — ENTRY
> FEES, MASTERS, TEAMS OF 1-3 MONSTERS** (user on the audit: "Agree with proposed scope.
> Its own tab. Yes include in scope [master sprites + fees]. Yes I want 1-2 monsters.
> agreed [bracket shape fixed]. Only flags progression [no prizes]. fine [text read-only].
> For now its fine, flags session will deal with it [victory cascade read-only]"). S108
> USER-CONFIRMED at session start. **Test ROM `DWM_S109_arena_demo.gbc` USER-CONFIRMED 2026-10-01 22:57
> ("Can confirm")**; the editor half (Arena tab) travels with this hand-off —
> test_app-verified, not yet run on the user's Mac. Verifier PASS; clean `1ca6579…` byte-perfect (bank $09
> arena class menu re-sectioned by `tools/resection_arena_menu.py`, both trees; the two
> master-sprite tables addressed by label; comments only); **patched pin `482c949f…`
> (patched)**, was `77ccdab8…` (patched, historical) — the two 6-byte tails + bank $6E;
> the user's project as-is now builds `f995cb88…` (patched; was `7f6df249…`, historical).
> test_compiler --rom 609/609, test_app + test_app --rom PASS (GUI build == pin).
> `EDITOR_REVISION` = 'S109'.
>
> **Built (PROJECT_COMPILER §2.25, SIDEQUEST_MAP "Arena authoring as built — S109",
> EDITOR_DESIGN §5.2b "As built S109"):** `gamedata.arena.<G..S|StarryNight|King>` = `fee`
> (classes) + `matches.<0-2>.{master, size}` → compiler regions `gd_arena_masters_04` /
> `gd_arena_masters_50` (the two master-sprite tables, `$04:$5E22` / `$50:$6778`),
> `gd_arena_fees` (`ArenaClassFeeTable` `$09:$5D23`) and `gd_arena_team_sizes` (bank
> $6E). The team members ARE enemy rows (`gamedata.enemies`, EID `$E0 + 9·class + 3·match
> + slot`; the King 481-483), edited in place. **Engine (NEW hand patch
> `patches/bank_06e.asm`, bank $6E = Arena systems):** the last 6 bytes of
> `ArenaBattleSetup` ($04) and `LoadArenaEnemyStats` ($50) far-call `ArenaTeamFixup`,
> which for a team of 1 / 2 writes `$DA02` = size − 1 and hides the absent slots' display
> entries (draw id `$FF`); size 3 = vanilla. Editor: new **Arena** tab (after Dialogue) —
> classes / Starry Night / King, fee, the victory cascade (read-only), per match the
> master (sprite picker: any room-NPC person or monster), Monsters 1/2/3, the three enemy
> rows (species + stats, grey "not fought"), back to the original match. Iron Rule 8:
> species 215-220 refused in a fighting slot or as master.
>
> **Found:** (1) the class menu (bank $09 `$5B64`, screen effect type 4 of
> `ScreenEffectTable09`; S67 had its fee table `$09:$5D23` and `$C0D8`) decoded and
> re-sectioned: 5 + 9-state machines on `$C905` / `$C906`, the won marks, the gold check
> and payment; (2) ROM0 **`AddGold` SUBTRACTS** (floor 0; measured 3800 → 3750 at the
> E class) — name kept, comments + DATA_STRUCTURES corrected; (3) the display list
> `$D7CA` order is master, slot 1, slot 0, slot 2; (4) measured: the King is one match
> (the room sets `$D9CD` = 3 — as arena_brackets.json says).
>
> **Measured in PyBoy on the user's save** (demo `3653b29d…` (patched) = the user's
> project + a demo overlay NOT in their project: Starry Night teams of 1 / 2 / 3, a
> Coatol monster master on match 3, the King with 2, the G class fee 20): through the
> real lobby flow Starry Night match 1 = one monster (entries 1 + 3 not drawn, one enemy
> in battle), won → match 2 = two, won → match 3 = three with Coatol standing; the King
> fought with two; the class menu showed "G CLASS 20" and took 20 (3800 → 3780); an
> unedited class still fights three. The demo project made through the GUI document
> model builds the same `3653b29d…`. **Hand-off (user 22:57: "Can confirm. Give handoff with all
> changes since last repo push"):** every S109 change = the diff against `81418d3`
> (origin/master), delivered as `DWM-S109-arena-editor-changed-files.zip`, the APPLY list
> pasted in the chat. **Next session:** the user's pick — the next unchecked item after
> P3.10b is P3.11 (Skills tab); P3.6 (dialogue editing) would also free the arena text.

> Last verified: 2026-10-01 (Session 108 — **ROADMAP P3.10 PART 3: RENAMING THE
> ORIGINAL MONSTERS — NAME, DEFAULT NICKNAME, LIBRARY DESCRIPTION — + EVERY
> DIALOGUE TEXT, MEASURED AND SEARCHABLE** (user 19:03 on the audit: "1) Yes, need to
> be able to rename everything. 2) 1-4 like new species is fine 3) Yeah I want to be
> able to pull all dialogue so I can inspect to see if needs changes or not … only
> system-related names (breeding, library, battle system, etc) have to be adjusted
> dynamically. 4) Doesnt matter 5) Ok to regenerate, fix typo"). S107 USER-CONFIRMED
> at session start. **Test ROM r2 USER-CONFIRMED 2026-10-01 21:07 ("COnfirrmed. Hand off
> please")**; the editor half (Monsters tab text fields, Dialogue tab) travels with
> this hand-off — test_app-verified, not yet run on the user's Mac.
> Verifier PASS 6/6 (+ `dump_dialogue.py` selftest); clean `1ca6579…` byte-perfect
> (bank $4D descriptions re-sectioned, bank $41 nickname labels renamed, 6,520 script-
> bank text previews + 70 bank-$47 id comments refreshed, bank $09 naming comments —
> comments / labels only); **patched pin UNCHANGED `77ccdab8…` (patched)** — every new
> region reproduces the original bytes; the user's project as-is still builds
> `7f6df249…` (patched). test_compiler --rom 575/575, test_app PASS. `EDITOR_REVISION`
> = 'S108'.
>
> **Built (PROJECT_COMPILER §2.24, TEXT_SYSTEM "Monster text blocks (S108)" + "Text id
> resolution (measured S108)", EDITOR_DESIGN §5.2 "As built S108"):**
> `gamedata.monster_text.<0-214>` = `name` (1-9), `nickname` (1-4), `description`
> (1-3 lines × 18 cells) → three compiler regions over the blocks the game reads them
> from — names `$41:$5B1F-$628D` (mode 5, 1,903 B), default nicknames
> `$41:$69F2-$6C76` (mode 7, 645 B), descriptions `$4D:$53D3-$7719` (mode 1, 9,031 B)
> — first-fit in id order, labels unchanged (no pointer moves); what no longer fits
> spills into the new-species text extents (names / nicknames) or the new region
> `gd_monster_desc_extra` (bank $4D tail). The library recipe lines naming a renamed
> monster are regenerated (Akubar's vanilla "Grenadal" typo goes with it); new species
> may have their OWN description (`custom.species[].description`). Names share one
> encoder (letters, digits, space, `' , . ! ? - &`). Editor: Monsters tab **Name and
> library text** (originals + new species; game-font preview; back to original;
> "Texts that name it…"), new **Dialogue** tab (every text, search, per-monster
> mentions under the old + new name, save as text file). Iron Rule 8 holds (215-220
> refused).
>
> **Found (foundational):** (1) the join naming screen PRE-FILLS the nickname with the
> species' 2-letter code — text mode 7, the table mgbdis called `FamilyCodePtrTable`
> (renamed `MonsterNickPtrTable` / `MonsterNick_NNN_XX`, both trees); the family name
> pools (mode 3) are only the random name for a blank name at END (bank $09
> `FuncFld9_621f` / `LoadFld9_688e` annotated; BREEDING_SYSTEM corrected). (2) **Text
> ids**: each corpus bank forwards the upper part of its index range to an OVERFLOW
> bank — $42→$1A, $43→$1A, $44→$1B, $45→$1F, $46→$1B, $47→$21, $48→$1F, $49→$18,
> $4A→$22, $4B→$3F, $4E→$4F (1,177 of the 2,560 ids). `extracted/text_id_map.json`
> modelled the cascade (fixed $400B base, guessed index rule, no overflow): **62 of
> its 2,061 entries matched the game** — so 6,520 script-bank previews and bank $47's
> TextStr id comments named the wrong text (DOC_AUDIT S108). New
> `tools/dump_dialogue.py` stub-calls the game's TextBankDispatch in PyBoy for all
> 2,560 ids (intro screenshot: id $0000 = "Milayou:Terry! Wait! It's time for bed!"),
> `text_id_map.json` is derived from it, the comments refreshed.
>
> **Measured in PyBoy on the user's save** (test ROM r1 `DWM_S108_rename_demo.gbc`,
> patched `6fc98013…` (historical) = the user's project + a demo overlay NOT in their project:
> Slime → Goober / GOOB / new description, Healer → Medic / MD, BattleRex → TyrantRex
> + description, Grendal → Grendel, Darkdrium → Doomdrium, Klamutra's own
> description, the wild Slime row always joins): INFO pages "Doomdrium" / "TyrantRex"
> / "Medic"; Gate of Beginning "Look out! Goober monster!", "Goober takes 506 damage
> pts!", "Please name Goober♂.", the naming field pre-filled "GOOB"; the running game's
> text engine (stub calls of bank $41 / $4D entry 0) returns the new name / nickname /
> description for every edited species, Akubar's recipe line "Grendel  Grendel" and
> Klamutra's own description.
>
> **S108 r2 (user 20:10 on the r1 ROM: "Slime didnt appear once in 20 battles and library
> inaccessible"):** both were the DEMO, not the build — (1) the user's own Gate of
> Beginning list gives the wild Slime 10 % (PyBoy, 20 encounters on r1: Klamutra 9,
> Slime 4, EID 3 4, EID 4 3), the demo never raised it; (2) the user's project routes
> the GreatTree Library door ($01 screen 8 (5,3)) to cities_fount (`entrance_redirects`)
> and the demo did not lift that (the S107 demo did). r2 demo = r1 + Slime 50 % in list 0
> + that redirect removed (both demo-only): PyBoy 20 encounters → Slime 11; through the
> real Library door → the librarian → the library list shows Goober / Medic (Slime
> family), TyrantRex (Dragon), Doomdrium (???); Goober's page = the new 3-line
> description; Grendel's page; Akubar's page parents "Grendel / Grendel". Test ROM
> **`DWM_S108r2_rename_demo.gbc`** (patched `dceafc5c…`; r1 `6fc98013…` patched,
> historical). No compiler / editor change. **USER-CONFIRMED 2026-10-01 21:07.**
>
> **Hand-off (user 21:07: "Hand off please, all files since last repo push. Also are there
> files in repo I should delete? Are these Python cache files part of repo?"):** every S108
> change = the diff against `8463831` (origin/master), delivered as
> `DWM-S108-monster-text-changed-files.zip`, the APPLY list pasted in the chat. Repo
> cleanup in the same list: the 23 tracked `__pycache__/*.pyc` files and the 39 tracked
> files of `editor2/example-project/build/` (regenerable compiler output — every test /
> build run rewrote them; nothing reads them) leave git; `.gitignore` gains
> `__pycache__/`, `*.pyc`, `*.ram` (PyBoy battery files next to a ROM),
> `editor2/example-project/build/`. **Next session:** the user's pick — the next
> unchecked Phase 3 item is P3.10b (Arena editor); P3.6 (dialogue editor) now has its
> data (`extracted/dialogue.json`) and a read-only tab to grow from.

> Last verified: 2026-10-01 (Session 107 — **ROADMAP P3.10 PART 2a: NEW ART
> FOR THE ORIGINAL MONSTERS + PART 2b: WALKING LAYOUTS + PART 2c: FAMILY ICONS** (user 15:52 on the audit: "I think we can do 2a-c
> this session but lets start with 2a and see how we go. 2) I probably WONT edit
> more than 50 monsters at most? 3) Terry and 216-220 ARE NOT MONSTERS. They are
> SPECIAL BOSS + Summons that the summon skill makes. I have told you this
> repeatedly. DO NOT MESS WITH THEM beyond giving the ability to change their
> moves and stats." → **Iron Rule 8**). S106 USER-CONFIRMED at session start.
> **2a USER-CONFIRMED 2026-10-01** ("great job, can confirm") with one note: a
> re-arted monster's library parent icon stood STILL where vanilla MOVES (layout
> 0 = pure mirror, no bob) → fixed by 2b (walking layouts, same session; below).
> 2a as built: Verifier PASS 6/6 (bank_010.asm in
> PATCH_FILES, art banks $7A/$7C/$7F in PATCH_NEW_FILES; extract_gamedata
> selftest checks the eight walking copies); clean `1ca6579…` byte-perfect
> (7 follower gfx-ID copies + bank $10 layout / attr tables re-sectioned, both
> trees); patched pin unchanged by 2a `f22f56e1…` (patched, historical — 2b
> moved it to `9740c1c9…`, below) — every new region reproduces the hand bytes;
> the user's project as-is built `47b38e5c…` (patched, historical) == their own
> Mac build. test_compiler --rom 507/507, test_app PASS.
> `EDITOR_REVISION` = 'S107'.
>
> **Built (PROJECT_COMPILER §2.23, MONSTER_DATA "New art for ORIGINAL species",
> EDITOR_DESIGN §5.2 "As built S107"):** `gamedata.art` for species 0-214 →
> compiler regions over the ROM0 battle gfx table (ONE table, 13 readers — ROM
> search), the $17 battle palettes, the EIGHT walking gfx-ID copies (identical for
> 0-214; all written), the bank $10 / $11 layout + attr tables (new walking art →
> the bank's own layout 0: Dragon `$10:$4E33` / Armorpion `$11:$4184`, no engine
> code) + compiler-owned art banks $7F/$7C/$7A (49,149 B; 50 fully re-arted
> monsters fit). Editor: the Name & art page opens for originals — **New art from
> a sprite sheet…** (the S106 dialog, mode `original`), battle colours and
> walking palette (also colours-only on the original art), back to original, art
> meter; TERRY? / the summons have no art page. Found: `$320F` is Darkdrium's
> battle art (not a "Durran placeholder"); the patched bank $0B walking table is
> at `$4914`; a picture using all 256 byte values cannot be stored (plain error).
>
> **Measured in PyBoy on the user's save** (test ROM **`DWM_S107_art_demo.gbc`**,
> patched md5 `bdc408a8…` = the user's project + a demo overlay NOT in their
> project: Healer / BattleRex / Darkdrium (their party), Slime, MadPlant re-arted
> from `bug.png`, Dracky colours only, wild Slime row always joins, the GreatTree
> Library door un-redirected): followers' VRAM `$8200/$8300/$8400` == the new
> streams, OAM palettes == the authored ones; party menu, INFO and the Healer
> library page show the new poses; Healer's lineage parent icon (bank $12 copy) =
> MadPlant's new walking art; Gate of Beginning: Slime = new art + colours, Dracky
> = its art in the new colours, Anteater / Klamutra unchanged; the Slime joins.
> **2a USER-CONFIRMED 2026-10-01** ("great job, can confirm") except: "When you
> changed healer parent sprint in library it is STILL. Vanilla behaviour is
> MOVING" (layout 0 = the A frames mirrored) → 2b; "Are we able to continue to 2b?"
>
> **2b — walking LAYOUTS: built S107, USER-CONFIRMED 2026-10-01 17:26** ("Can
> confirm everything works correctly. 2c next") (PROJECT_COMPILER §2.23
> "Walking layouts", MONSTER_DATA "Walking layouts as project data", EDITOR_DESIGN
> §5.2 "As built S107 2b"). `editor2/core/walk_layouts.py`: a packer fits the
> sheet's six frames to ANY of the 155 layouts and ranks them by differing pixels
> (exact for all 44 original monsters whose layout fits the 16 × 16 frame;
> bug.png: 20 of 26 monsters fit some layout pixel-exactly, layout 0 only 6);
> `follower.layout` in `gamedata.art` / `custom.species` (instead of
> `walks_like`); a layout the follower bank lacks is COPIED into its zero tail
> (regions `lay_copies_10` / `lay_copies_11`; only the frames the bank lacks).
> **Engine (bank $11, patches/):** both follower entries `call FollowerLayoutBase11`
> (same size as the `ld de` it replaces) → new species read their own
> `NewFollowerL1Table` row; `NewAttrHandler` no longer writes the S105 donor index
> to HRAM `$C7`; `NewFollowerAttrTable` 1 B / id. **Patched pin `9740c1c9…`
> (patched)**, was `f22f56e1…` (patched, historical); the user's project as-is now
> builds `b1097263…` (patched; Klamutra still walks like 128 — same frames).
> Extracted: `follower_layouts.json` regenerated with stored bytes / instances /
> bank frames + Y-flip (ids unchanged), the extractor's selftest now checks the
> JSON == ROM and runs in verify_integrity. Editor: the sheet dialog's **Walk
> style** list + the sheet's own frames walking beside the game's; the
> renderer draws entry 0 on top (CGB OAM priority — was underneath) with the
> entries' Y-flip. Verifier PASS 6/6 (+1 selftest tool); clean `1ca6579…`;
> test_compiler --rom 532/532, test_app --rom (GUI build == pin), test_canvas --rom
> PASS.
>
> **Measured in PyBoy on the user's save** (test ROM
> **`DWM_S107b_walk_layouts_demo.gbc`**, patched `f5bf7c12…` = the user's project
> + the 2a demo overlay re-cut with the best walk styles: Healer layout 2, Slime
> 143 (copied into bank $10), MadPlant 2, BattleRex / Darkdrium / Klamutra layout
> 0 = their best fit): the MadPlant parent icon on the Healer library page now
> alternates two poses (OAM tiles 114/115 ↔ 112/113), the icon's VRAM = all 16 new
> tiles; a scratch build (Klamutra layout 13 copied into bank $11, Klamutra +
> Slime poked into the party, gate floor): every follower OAM sample (112 each, all
> eight facing frames) == its layout's frames, palettes as authored, art in VRAM;
> vanilla Darkdrium (layout 10) / Healer (29) and a `walks_like` species draw
> their layouts on both the old and the new build.
> **2c — family icons: built S107, USER-CONFIRMED 2026-10-01 18:37 ("Great, can confirm works")** (user 17:26: "2c next if
> you are able context-wise else hand off"; BREEDING_SYSTEM "Family icons as project
> data", PROJECT_COMPILER §2.20, EDITOR_DESIGN §5.2a). `gamedata.families.<f>.icon`
> (8 × 8, shades 0-3) → the font glyph (region `gd_family_icons`, bank $4F; was an
> INCBIN) AND the gfx stream (`gd_family_icon_streams`, bank $2E — NEW hand patch
> `patches/bank_02e.asm`, PATCH_FILES; `gd_spirit_icon_stream`, bank $6D); no edits =
> the same bytes. Families tab: pixel editor + PNG import + previews in the two
> measured screen palettes + back to original. **Found + fixed (Spirit, S104
> leftover):** a ROM search for the `$2E03…$2E0C` word run found two more
> unclamped 10-entry icon tables — `$07:$62AB` (the JOURNAL screen's saved-party
> line) and `$0A:$6013` (its twin); a SAVED Spirit party member gave gfx id
> `$CDE5` / `$0A11`: PyBoy stalled on the JOURNAL screen, stub calls never
> returned. Same-size forks to bank $6D `FamilyIconGfxFromE` (patches/); the tables
> re-sectioned `SavedPartyFamilyIconTable07` / `0A` + the code after them labelled
> (`Fld_62bf`, `FldA_6027`) in both trees; `build_family_icon.py --selftest` now
> checks the regions == ROM. **Patched pin `77ccdab8…` (patched)**, was `9740c1c9…`
> (patched, historical). Verifier PASS (bank_02e in PATCH_FILES); clean `1ca6579…`;
> test_compiler --rom 544/544; test_app PASS.
>
> **Measured in PyBoy** (test ROM **`DWM_S107c_family_icons_demo.gbc`**, patched
> `a4bbceaf…` = the 2b demo + a heart Slime icon, a star Dragon icon, Slime species
> moved to Spirit): continue box `?/★/♥` for Slib / Wrex / Hale, field status bar
> VRAM `$8DA0+16·slot` == the authored tiles, Hale's INFO page "♥family"; the
> always-joining wild Slime joins with family byte 10; with a saved Spirit party
> member (the user's save, family poked + saved via JOURNAL) the JOURNAL shows the
> wisp, and both saved-party routines return when stub-called (before the fork:
> stall). Shades on screen: 1 = cream, 3 = black everywhere; 0 / 2 = greens on the
> INFO page, orange / gold in the continue box.
> **Hand-off:** user 18:37 "Hand off all changes since last repo push" — every S107
> change (2a + 2b + 2c) delivered as `DWM-S107-original-art-changed-files.zip`, the
> APPLY list pasted in the chat. **Next session:** the user's pick — ROADMAP P3.10
> part 3 (renaming original species + descriptions) is the next unchecked item.

> Last verified: 2026-10-01 (Session 106 — **ROADMAP P3.10 PART 1: THE MONSTERS
> TAB — SPECIES DATA, ENEMY ROWS, NEW SPECIES CUT FROM SPRITE SHEETS** (user
> 10:55 on the audit: "Yeah that seems fine" — the split P3.10 part 1 species
> data / part 2 art / part 3 renames — "Here I will give you spritesheets for
> followers and monsters — either build them in or make a reader that can import
> them. Happy to adjust squares on top manually. Proceed"; the 12 DWM2 family
> sheets `All_DWM2_monsters.zip`, ripped by The IT, are NOT committed — the
> reader imports any such sheet into a project's `assets/sheets/`). S105
> USER-CONFIRMED at session start. **Built S106; the r2 test ROM USER-CONFIRMED
> 2026-10-01 13:26 ("Ok perfect, this fixed it"; r1: "all enemies are there",
> "SPrite followers are also all correct"); the tab itself USER-CONFIRMED
> 2026-10-01 15:16 on the Mac (S106 r3, below).** Hand-off: all S106 work = the
> diff against `07594f1` (origin/master), delivered as
> `DWM-S106-monsters-tab-changed-files.zip`; from S106 on the APPLY list is pasted
> in the chat, not zipped (SESSION_PROTOCOL "Delivery format").
> Verifier PASS 6/6; clean `1ca6579…` byte-perfect (bank $00 LZ decompressor +
> bank $10 `HramScr2_406e` comments — both trees); **patched pin UNCHANGED
> `f22f56e1…` (patched)** — no engine / emitter byte change; the user's project
> as-is still builds `e84dff45…` (patched, = S105). test_compiler --rom 431/431,
> test_app --rom (GUI build == pin) + test_canvas --rom PASS. `EDITOR_REVISION`
> = 'S106'.
>
> **Built:** the **Monsters** tab (EDITOR_DESIGN §5.2 "As built S106"; model
> `editor2/core/monsters.py`): every species (your new ones, the 215 originals,
> the 6 combat-only) with its walking sprite; **Species** page = the 43-byte
> info row (family, level cap, exp curve, female, flying, metal, tier, 3 natural
> skills, 6 growth curves + chart, 27 resistances, reset) → sparse
> `gamedata.monsters` / `custom.species[].info`; **Where you meet it** = every
> enemy row of the species with where the game uses it (pools, gate bosses + join
> rows, arena, coliseum / random / mimic / script battles, starter, project
> uses), cells editable → sparse `gamedata.enemies` / `progression.enemies`;
> **Name & art** (new species); **New species from a sprite sheet…** =
> `editor2/core/sheet_import.py` (finds every pose + 2 × 3 walking frames,
> draggable / resizable boxes, live preview of exactly what the game draws:
> 48 × 48 battle pose with backdrop + black + 2 chosen colours, 4-direction walk
> in one of the 8 OBJ palettes) → `custom.species` + the art streams + the sheet
> + `source` boxes (re-cut later). One species source for the editor: NPC
> picker / canvas thumbnails of new species drawn from the project's art
> (`editor2/core/sprite_render.py`).
>
> **Found + fixed (foundational):** (a) **`dwm/sprite_codec.decode` was wrong
> since S22** — the game re-wraps EVERY copy source byte 4 KB down and writes 0
> for one below the destination (`TextMakeVisible`); the decoder returned 0 for
> whole copies, garbling 213 of 221 battle and 49 walking streams in
> `extracted/monster_sprites.json`. The S22 "shared VRAM tile pool" and "extracted
> sprites render correctly" claims were false (DOC_AUDIT S106). New
> `tools/census_lz_decode.py`: PyBoy stub-calls the real decompressor for all 442
> streams → 442 equal, none depends on prior VRAM. Data regenerated; extended
> copy length 8-bit (0 = 256) in decode / read_stream / encoder `MAX_COPY`.
> (b) `extract_monster_follower_layouts.py` read bank $11's attr bytes at bank
> $10's base (`$417F`); `$412D` now — every collectible species' attr is a palette
> 0-7. (c) MONSTER_DATA's resistance wording "0 = weak, 2 = normal" was wrong:
> level 0 = full effect … 3 = immune (the S78 ladders).
>
> **Measured in PyBoy** (the user's save, test ROM below): the sheet reader's
> boxes for the water sheet's blue dragon == the hand-picked S34 / S35 Gorbunok
> boxes and its walking payload == Gorbunok's committed in-game-proven art; the
> editor's walking frames == the S101 PyBoy census for 213 / 215 species (146 /
> 147: the census build's S105 attr bug); battles in the Gate of Beginning show
> the three sheet species with their chosen colours; Onidrak joins ("Onid"),
> goes to the party, VRAM `$8400` == its walking art, OAM palette 0 as authored;
> the edited wild Slime (EID 2) joins at Lv 20, H 225 (250 rolled), family byte
> 3 = Bird. Test ROM **`DWM_S106_monsters_demo.gbc`** (patched, md5
> `bcf7ec0d…`) = the user's project + a demo overlay NOT in their project (pool 0
> = Slime row Lv 20 / 250 HP / always joins + Onidrak / Wyrmlord / Goldhorn, all
> always join; Slime species family Bird + natural skills Blaze / Firebal /
> Beserker). **Next:** user test of the ROM + the tab; then P3.10 part 2 (art of
> ORIGINAL species: battle art + palette, walking art / layout / palette as
> project data, the 4-direction visualizer for them, G-P) or the user's pick.
>
> **S106 r2 (user 13:17: "all enemies are there. HOWEVER sprites got slightly
> messed up … goldhorn (estark FYI) … his sword is no longer gold/white but only
> gold … I am guessing you somehow minus background colour within the sprite?
> That should not happen. background colour is perfect. SPrite followers are also
> all correct."):** the battle colour fit used black + 2 colours inside the pose
> and kept the cream for the background only — but the cream ($6BFF, c1) is drawn
> INSIDE every original pose too (all 215 have enclosed cream pixels). Now every
> sheet colour goes to the nearest of {black, cream, c0, c2} with c0 / c2 fitted
> (`sheet_import.battle_colors`): a black + white + 2-colour pose is exact (white
> → the cream). PyBoy on the user's save: all three poses == the editor preview
> 2304 / 2304 px; Goldhorn keeps its white sword edges, Onidrak exact; Wyrmlord
> (6 sheet colours) merges its red flame. Test ROM **`DWM_S106r2_monsters_demo.gbc`**
> (patched, md5 `42d13e71…`; r1 `bcf7ec0d…` patched, historical). test_compiler
> --rom 432/432, test_app --rom PASS. **USER-CONFIRMED 2026-10-01 13:26 ("Ok
> perfect, this fixed it").** Followers (user question): no shade lost — walking
> frames have 3 colours + transparent and the sheets' frames use exactly 3; the
> light one is always the shared OBJ cream (yellow / orange tints become cream).
>
> **S106 r3 (user 14:50: "1) What is 'start from: 0 Drakslime' 2) How to put it
> into gate? 3) Have you been updating the help?" → "either signpost or
> implement"):** implemented — "Where you meet it" gains **New enemy row for this
> monster** (`monsters.new_enemy_for_species`: a project enemy copying the species'
> first original row, else the wild Slime EID 2) and **Put the selected row in a
> gate…** (`app/pool_dialog.py`; `monsters.gate_pools / pool_slots /
> set_pool_slots` → sparse `gamedata.encounters`, project enemies by id): gate
> floors list, the five slots with chance codes + the REAL chance (running sums cut
> at 100), "max in a group" only for 2-3 monster lists, exactly 100 % required —
> all 128 original lists are exactly 100 (measured); the compiler now WARNS on a
> list over 100 (its last slots are never drawn). "Start from" → **Copy data
> from** with an explanation, default Dragon (28), family follows it. Help: the
> Monsters topic's "Putting a monster in a gate". PyBoy on the user's save: the
> user's project + Goldhorn made only through these paths (sheet → species → new
> row → gate list 0 at 50 %) → Goldhorn battles in the Gate of Beginning.
> test_compiler 337 / test_app PASS. `EDITOR_REVISION` = 'S106r3'. **USER-CONFIRMED
> 2026-10-01 15:16 ("Ok worked. Can confirm inserting enemy works perfectly. Please
> hand off.") — the editor ran on the user's Mac, built their project, the gate
> insertion worked.** Also r3 (user's first build on a fresh clone: "BUILD FAILED:
> crash-config validation failed:" with no reason): `tools/validate_custom_data.py`
> crashed (FileNotFoundError, stderr only) when `data/DWM-original.gbc` is missing;
> it now reports that as an error, and `builder.build_rom` runs it with the editor's
> own interpreter and shows stderr too.

> Last verified: 2026-09-30 (Session 105 — **ROADMAP P3.9b: PURGE THE
> PROOF-OF-CONCEPT CONTENT FROM THE HAND OVERLAY, KEEP EVERY MECHANISM** (user
> 16:21: "Yes let's clean all this stuff it wont make it into real romhack
> except for mechanics, other than custom skills which need to fire without
> pre-existing custom rooms"; 16:35 "sounds great" to the scope) **+ G3:
> NEW-SPECIES CAPACITY 1 → 19 (ids 221-239)** (user: "Wait hang on so I can
> only have 16 new monsters max? I DONT LIKE THAT." → "Alright, 19 monsters it
> is. The rest I'll edit existing ones. Lets do it."). S104 USER-CONFIRMED at
> session start. **USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected")** on the S105 G3 test ROMs (user project as-is + the
> 3-species demo).
> Verifier PASS 6/6; clean `1ca6579…` byte-perfect (bank $11 `$407F-$4183`
> re-sectioned into `FollowerLayoutL1Table11` / `FollowerAttrTable11` + bank
> $04 router note — both trees where the bank is patched); **patched pin MOVED
> `15f21834…` → `f8a71485…` (patched, historical: the capacity-1 build, never
> user-tested) → `f22f56e1…` (patched, G3)**; test_compiler --rom 402/402
> (new: a BLANK project builds the original ROM's bytes at every purged /
> new-species site; every new-species fork EXECUTED from the built ROM's bytes
> over ids 0-239 for the example and a 19-species project); test_app --rom
> (GUI build == pin) + test_canvas --rom PASS. `EDITOR_REVISION` = 'S105'.
>
> **Purged (no project gets them any more):** (1) **Gorbunok** (new species
> 224) — now project data `custom.species` (editor2/core/species.py,
> PROJECT_COMPILER §2.21): 17 `ns_*` compiler regions in banks
> $00/$01/$06/$07/$09/$0B/$11/$12/$16/$17/$18/$41/$4D/$59/$6A + the
> compiler-owned bank $7E; an empty `custom.species` writes the original ROM
> bytes into every one (bank $7E all zero). The example project re-expresses
> Gorbunok byte-identically (art = `assets/species/*.bin`, reproducible from
> the PNGs with `bake_follower_overflow.py --stream-dir`); its wild row moved
> from the bank-$14 EID-518 slot to an ordinary project enemy (520). (2) **the
> S21 Dracky → "Clam" battle sprite** (`patches/bank_036.asm` deleted — it was
> in every build since 2026-06-19; the S103 audit missed it). (3) the S12
> dead-table mirror (bank $16 special entries 693 / 803). **Kept:** every fork
> (they read the project data), the custom skills. **Anchor needs no custom
> room any more:** its 4 dialog scripts + texts moved from the example's
> medal_vault (`$71`, scripts 2-5) to the compiler's built-in
> `editor2/core/skill_scripts.json` (bank $60 `SkillScriptPtrTable`, script
> type `$FF`; template `CustomScriptRead` +9 B, re-pinned; bank $72 arms `$FF`,
> ids 2-5 unchanged).
>
> **Found + fixed (measured in PyBoy on the user's save, old build `53338a16…`
> vs new `e8e30264…`, both patched):** (a) casting Anchor in the user's project
> SOFT-LOCKED the game — room `$71` does not exist there, the script read past
> the master table, stayed active with counter 8 and the player could not
> move; new build: all four dialogs through the real SKIL menu (no anchor →
> "No anchor is set!"; gate 1 floor 1 → YES → Castle, anchor 1/1 stored; Castle
> → YES → gate 1 floor 1, MP 916 → 229, anchor cleared; the user's custom gate
> room `$6F` → "The anchor fails here!"). (b) since S34 every build wrote the
> new species' layout pointer at `$11:$413F` = the follower attr bytes of
> **ChopClown (146) / Grendal (147)**: OAM attr `$A4` / `$41` (green palette,
> Grendal upside-down) → vanilla `$22` / `$02` again; Gorbunok's follower OAM
> (tiles + attrs, 8 walk samples) identical old vs new in the example (bank $11
> NewAttrHandler writes the layout donor's index to HRAM `$C7`). (c) Dracky
> fights as Dracky again (battle screenshot A/B). Also: the gamedata shadow
> checks treated a Spirit parent as no family (`fam_code` stopped at 9) —
> fixed, test proves old-fails / new-catches.
>
> **G3 — 19 new species, ids 221-239 (PROJECT_COMPILER §2.21).** The range
> is the game's own ceiling (seen bits 0-239, family codes $F0-$FA in the
> recipe scanner, $FE/$FF markers, follower router wrap at 240). The eight
> follower forks now COMPUTE the gfx-ID `$7E00+(id-221)*2` into WRAM
> `wNewSpeciesGid` ($D10A) — no per-bank tables (same fork size); every other
> fork gates on id ≥ 221 with 19-row tables (info $03/$6A, attr $11, battle
> palette $17, recipe pair $16, detail text $4D, nickname redirect $00 → base
> $7D39); ROM0 battle gfx table tail re-sectioned; bank $41 names/nicknames
> PACKED into 7 free extents (292 B: 19 × 8-letter names fit, 19 × 9-letter
> each with its own nickname do not — validation error); bank $12's trailing
> nops → `ds` so the library grouping can grow; a library tab over 32 members
> is now a validation error. **Also fixed:** (d) `SpellUseText_11`
> ("…knocked out monster!") had its last 16 bytes zeroed since B9 S28 (commit
> `e97b6da`) — restored; (e) stale files in a project's `build/patches` from an
> older editor silently overrode the hand overlay (write_outputs deletes them).
> **Measured in PyBoy** (fixture = example + 221 "Invertus" (colour-inverted
> art) / 239 "DrakSlimy" (tile-reversed art) + Gorbunok 224, user save):
> follower gid $7E00 / $7E06 / $7E24, the exact 256-B art in VRAM, OBJ palette
> 4/2/5; battles: the exact 576-B art, the declared BG palette, "Look out!
> Invertus / DrakSlimy monster!"; joins: naming screen suggests "Inve" / "Drak";
> library pages: Invertus "????? ?????" + species 10's text, Gorbunok Snaily +
> BattleRex, DrakSlimy DrakSlime + Healer with parent icons. User project as-is
> vs `e8e30264…`: 17 room/menu screenshots + 3 battles pixel-identical.
> Test ROMs: **`DWM_S105_G3_user.gbc`** = the user's project as-is (patched,
> `e84dff45…`); **`DWM_S105_G3_demo.gbc`** = the user's project + 3 demo
> species in Gate of Beginning pool 0 (patched, `0b65dc01…`; demo only, not
> for the real hack). **USER-CONFIRMED 2026-09-30 ("Confirm all three appear as expected").** Hand-off: all S105 work = the
> diff against `4e7f7ea` (origin/master), delivered as
> `DWM-S105-species-capacity-changed-files.zip`. **Next:** the user picks the
> next editor item (P3.10 Monsters tab would start from `custom.species`).

> Last verified: 2026-09-30 (Session 104 — **ROADMAP P3.10a: SPIRIT AS THE
> 11TH FAMILY** (user 13:07: "1) Custom skills absolutely stay!! … All data
> related to them must also be in editor. 2) Yeah please fix ??? and make
> spirit separate. Wisp is fine just make it look nicer. 3) Breeding table will
> utilize spirit extensively … Plan for it. 4) Of course spirit is in library.
> Given all this, please proceed. Make your own mockups for spirit and Ill
> pick"). S103 USER-CONFIRMED at session start. **Built S104 (r1-r5);
> r5 USER-CONFIRMED 2026-09-30 15:51 ("perfect. Hand off.").** Verifier PASS 6/6 (check 5 now also runs
> `build_family_icon.py --selftest`; `bank_06d.asm` in PATCH_NEW_FILES); clean
> `1ca6579…` byte-perfect (bank $41 `$4000-$4338` re-sectioned into the mode
> list + mode 0-4 tables, bank $0A `FamilyIconGfxTable0A` + `LoadFldA_46c9`,
> bank $09 default-name and bank $07 pedigree annotations — both trees);
> **patched pin MOVED `5d1dbc5f…` → `eee9f5b0…` (patched)**; test_compiler
> --rom 233/233; test_app --rom + test_canvas --rom PASS. `EDITOR_REVISION` =
> 'S104'.
>
> **Engine (BREEDING_SYSTEM "Spirit — the 11th family (S104)"):** new
> hand-authored bank **$6D FAMILY SYSTEMS** — entry 0/1 family-icon gfx id
> (families 0-9 = `$2E03+fam`, Spirit = `SpiritIconStream`, gfx id `$6D04`),
> entry 2 farm-dialogue text group (11 entries; Spirit = group D),
> entry 3 naming-screen default name (Spirit → mode-3 ids `$A0-$A7`) — behind
> same-size forks in banks $01 (was ClampFamIdx → ??? tile), $0A (the
> UNCLAMPED twin table: family 10 read code as a gfx id), $04 (opcode $2D read
> garbage) and $09 (names ran into the next table); bank $16 family scan `$FA`
> wildcard `jr z` → 2 nops (`$FA` = Spirit); bank $4F ??? glyph restored at
> `$41A0`, Spirit glyph at `$41B0` (byte `$1A`); bank $41 mode-4 Spirit string
> `"$1A"`, 8 Spirit names in the dead `$4323` words + tail fill; bank $07
> pedigree "unknown parent" icon id 10 → 11 (**found S104: vanilla id 10 is
> the empty "no family" string; since B9 every unknown parent drew the Spirit
> icon**). The B9 "$1A is not fill-immune" note did not reproduce (DOC_AUDIT
> S104). Editor: `"Spirit"` family / matcher everywhere, library token
> `<$1A>family`, `"AnyFamily"` refused, help topic updated.
>
> **PyBoy (stub-calls from WRAM + real screens; old build vs new):** INFO page
> `$1A` glyph for family 10, "?" for 9; HUD tiles `$8DA0-$8DCF` = Spirit stream,
> identical to S103 for 0-9; bank $0A list (stub `LoadFldA_4610`) Spirit tile
> at `$88B0`, identical for 0-9; default names identical 0-9, Spirit WISP /
> NOVA / ECHO; dialogue ids identical 0-9, Spirit `$7C` (group D; was `$EA3C`);
> breeding (`$16` entry 3) identical over every pair of non-Spirit species,
> `[Spirit × Dragon]` → MadSpirit and `[Dragon × Spirit]` → Spooky fire;
> pedigree unknown parents blank again; library tab strip page 3 = Spirit
> icon, page 2 ??? = "?". Test ROM **`DWM_S104_spirit_test.gbc`** (patched, md5
> `a7cf5159…`) = the user's project + a demo overlay (NOT in their project):
> Healer / Spooky / Shadow / MadSpirit in Spirit + those two recipes; the
> user's project as-is built `d17633de…` (patched, r1).
>
> **S104 r2 (user 14:35: "1) Ghost whisp is the best BY FAR, use that. 2)
> Doesnt matter. Just make option in editor. 3) Huh wtf is this? What eight
> placeholders? ALSO: I cant enter library on your map because it leads to
> custom room. The rest works fine.")** — r1 test ROM passed except the
> Library door, which the USER'S project redirects to its own room
> (`entrance_redirects` GreatTree scr 8 (5,3) → cities_fount; test overlay r2
> drops that redirect only). Icon = mock-up B ghost wisp; new
> `gamedata.families` (per-family dialogue voice A-D, Spirit's 8 default
> names = the naming screen's random pre-filled name) as compiler regions in
> banks $6D / $41; the editor's new **Families** tab (members, move / add,
> voice, Spirit names). Pin **`eb153510…` (patched)**; test_compiler --rom
> 241/241; test ROM **`DWM_S104r2_spirit_test.gbc`** (patched, md5
> `008435d6…`; PyBoy: the Library door enters `$12`, INFO / HUD / library tab
> show the ghost wisp); the user's project as-is builds `48edddfc…` (patched).
> `EDITOR_REVISION` = 'S104r2'. Built, NOT yet user-tested.
>
> **S104 r3 (user 14:56: "Nope when looking up spirit family in library it
> freezes"):** reproduced in PyBoy — and it was not Spirit-specific: since FX1
> (S71) the B7 library writer `LibScanByFamily` filled `$C0D8` while FX1 had
> moved every bank-$12 reader to `wMonList`, so every tab showed the roster
> list (DrakSlime… on every tab) and a lookup opened species = the list index;
> on the Spirit tab that index was an unseen species → text id `$FF` → the
> text engine never finished. Fix: the writer targets `wMonList` (same size,
> `patches/bank_012.asm`). PyBoy: Spirit tab lists Healer (the other demo
> members are unseen on this save = blank, as vanilla), its page opens; the
> Dragon tab lists its own (unseen = blank). Pin **`d7b762db…` (patched)**;
> test ROM **`DWM_S104r3_spirit_test.gbc`** (patched, md5 `acfd4ea9…`); the
> user's project as-is builds `ec4df754…` (patched). Verifier PASS,
> test_compiler --rom 241/241, test_app / test_canvas --rom PASS.
>
> **S104 r4 (user 15:13: "It wiped my sav file … when I reload it 1) make top
> row of screen glitchy, and b) wipes sav file again if I press reset"; sent
> `rom.s1` + `rom.sav`):** NOT an S104 regression — an FX1 (S71) bug,
> PyBoy-reproduced on the S103 test ROM too, and from a clean save: save at
> the farm, save again in the castle, CONTINUE, reset → new game. The R4
> snapshot's 94th chunk carries 28 bytes of the tile image `$BCC8-$BCE3`,
> committed BEFORE SaveGameState writes that block, so it is the PREVIOUS
> save's top row; CONTINUE restored it (the glitchy top row) without a new
> checksum (segment 3 covers `$BCC8`) → the next boot found no save. Fix:
> bank $73 R4 restore = 93 chunks + `CF3SnapTail4` (`$B124-$BCC7`). PyBoy on
> r4: the user's sent `.sav` CONTINUEs in the castle with the right top row
> and survives a reset; farm → castle save → CONTINUE → reset keeps the save
> (r3: lost); unsaved farm edits still rewind (incl. the 4 tail bytes);
> library visit + save + reload keeps party and farm identical. Pin
> **`e994173e…` (patched)**; test ROM **`DWM_S104r4_spirit_test.gbc`**
> (patched, md5 `5e25799e…`); the user's project as-is builds `52e13c28…`
> (patched). **USER-CONFIRMED 2026-09-30 15:34 ("Great that fixed it!").**
>
> **S104 r5 (user 15:42: "Just a display reorder. Feel free to do it now if
> small"):** Spirit shown BEFORE ??? — bank $12 `LibTabToFamily` +
> `LibTabOrder` (tab position → family) for the tab-strip icons
> (`SaveItem_6184`, same-size call) and `LibScanByFamily`; 39 tail fill nops
> consumed; editor `gamedata.DISPLAY_ORDER` drives the Families tab. No
> family byte / code changes. PyBoy: page 2 = Bug, Devil, Zombie, Material,
> Spirit (its list = Healer, page opens), page 3 = ???. Pin **`15f21834…`
> (patched)**; test ROM **`DWM_S104r5_spirit_test.gbc`** (patched, md5
> `67d32535…`); the user's project as-is builds `53338a16…` (patched).
> Verifier PASS, test_compiler --rom 242/242, test_app / test_canvas --rom
> PASS. **USER-CONFIRMED 2026-09-30 15:51 ("perfect. Hand off. Everything
> that has been changed since last repo push.").**
>
> ROADMAP revised this session: P3.9b (custom skills are NOT content to
> purge), new **P3.11c** (custom skills as project data), **P3.12** planning
> for the Spirit-heavy breeding redesign (11-family randomizer / optimizer as
> a proposer writing `gamedata.breeding`, depth read-out). **Next:** the user
> picks the next editor item. **Hand-off: all S103 + S104 work = the diff
> against `f2d9ece` (origin/master), delivered as
> `DWM-S103-S104-changed-files.zip`.**

> Last verified: 2026-09-29 (Session 103 — **ROADMAP P3.9: LAYER A-LITE —
> THE VANILLA DATA TABLES BEHIND project.json `gamedata`** (user: P3.3g "No
> fuck this. Bank and come back later if tiles become a problem … Move on to
> next editor item" → P3.3g BANKED with its S103 static audit in ROADMAP;
> then "Sure lets do 3.9 and if its ends up very fast lets do P3.7b part 2
> also" — P3.9 was not fast, P3.7b part 2 not started). S102 not re-confirmed
> this session. **Built S103; USER-CONFIRMED 2026-09-30 (test ROM: "Rom - all
> correct").** Verifier PASS 6/6 (check
> 5 also runs `extract_gamedata.py --selftest`; PATCH_FILES + the new hand
> patch `bank_013.asm`); clean `1ca6579…` byte-perfect (bank $04D recipe-string
> block and bank $01 `EncounterChancePercent` re-sectioned, bank $01 encounter
> code annotated — both trees); **patched pin MOVED `0d60486e…` → `5d1dbc5f…`
> (patched)**; test_compiler --rom 227/227; test_app --rom PASS (GUI build ==
> pin); test_canvas --rom PASS. `EDITOR_REVISION` = 'S103'.
>
> **What changed (PROJECT_COMPILER §2.20):** `gamedata` is implemented as
> SPARSE overrides — `monsters`, `enemies` (EIDs 0-486), `encounters`,
> `skills` (mp / learn / record), `exp_curves`, `growth_curves`,
> `breeding.family` / `.special`, `boss_joins` — emitted into twelve same-size
> compiler regions in banks $01/$03/$06/$07/$12/$13/$14/$16/$4D/$54/$69 from
> the committed vanilla base `extracted/gamedata_vanilla.json`
> (`tools/extract_gamedata.py`); an empty `gamedata` == the ROM, table by
> table (test_compiler; `--rom` against the original ROM). The compiler keeps
> coherence: library recipe TEXT regenerated **in place** (the bank $4D mode
> table overlaps the recipe pointers — TEXT_SYSTEM correction), library tabs
> regrouped from the family bytes, Set 2 / Set 3 warnings, the B5 shadow
> validator ported. The pre-S103 hand edits (Spirit Dracky / Darkdrium, starter
> EID 1 harness, Gorbunok pool 0, B4 recipes, B5 overrides + appends) are now
> the **example project's `gamedata`** — byte-identical, except that its 4 B4
> recipe strings now match (17 B in bank $4D). Tool emit paths that wrote these
> bytes are retired (KEY_LESSONS S103).
>
> **Decoded (DATA_STRUCTURES "Encounter pool entry"; annotated bank $01):**
> pool +0 rate code → wC8A9, +2..+4 chance of 1/2/3 monsters, +5..+9 slot
> chances (codes → `EncounterChancePercent` $01:$69C0 = 0-100 %), +20..+24
> **max count** per slot (1 = only alone; NOT a weight), +25 maze size → $C93D.
> **Measured freeze:** a pool that can draw 2 monsters whose first draw has max
> 0 and no slot allowed twice re-draws forever (28,257 passes, no battle) — the
> compiler refuses it.
>
> **PyBoy on the user's save** (their project + the example's gamedata + demo
> edits = `DWM_S103_gamedata_test.gbc`, patched, md5 `1dbae0a5…`): Gate of
> Beginning = always one Slime; its battle row `$DA18` = the edited EID 2
> (HP 250, ATK 1, 500 exp, always joins) → 167 exp to each of 3, the Slime
> joins; HealMore USE MP 1 (5 on the same project without the demo edits);
> Snaily's encyclopedia page reads "Zombie family / Zombie family"; the Dragon
> tab lists 26 (Slime moved in), the Slime tab 20. The user's project WITHOUT
> gamedata now builds the vanilla tables (the POC edits are no longer
> inherited).
>
> **User sign-off 2026-09-30 12:53: "Rom - all correct"** (test ROM passed).
> Decisions: "Start off hack with original table. patches are POC trash" (the
> user's project keeps NO gamedata = vanilla tables); "Please do not include any
> patches in the editor, they are all trash (in terms of custom monsters, custom
> rooms, etc. The mechanisms are obviously vital)" → ROADMAP **P3.9b** (purge
> POC content from the hand overlay, keep the mechanisms); "I still want the
> FAMILY [Spirit], but for now no monsters assigned … assign to families …
> propagates to breeding … a new sprite for the spirit family" → ROADMAP
> **P3.10a** (Spirit as a first-class 11th family). Both audited (read-only)
> S103; not started. **Hand-off: all S103 work = the diff against `f2d9ece`
> (origin/master), delivered as `DWM-S103-gamedata-changed-files.zip`.**

> Last verified: 2026-09-28 (Session 102 — **ROADMAP P3.3f: OWN ANIMATED
> TILES, FROM SCRATCH — any tile, drawn frames, any speed, a plain budget**
> (user: "CAN I animate more than a single tile? … If I animate 1 it stops
> the second one. Also is this budget expandable"; "can we control speed of
> tile movement?"; then "This is NOT UI friendly. I dont … understand the
> budget, how it works … I just want animated tiles and for the UI to tell
> me wtf is happening … I want to mostly make them myself"; "offer both"
> [flip and drift]; "Keep button" [vanilla copy]; "if I can set speed that
> would be great"; "CAN animation slots be expanded? Can you poke around
> briefly?"). S101 r4 not re-confirmed this session. **Built S102; signed
> off 2026-09-29 (in-game ROM test not separately reported).** Verifier PASS 6/6; clean `1ca6579…` byte-perfect (bank $00
> `LCDCStateTable` re-sectioned to bytes + comments, both trees); **patched
> pin MOVED `9c813041…` → `0d60486e…` (patched)**; test_compiler --rom
> 170/170; test_app --rom PASS (GUI build == pin); test_canvas --rom PASS
> incl. the rewritten v6 (Animate tab + --rom own flip). `EDITOR_REVISION` =
> 'S102'.
>
> **Why the user's two-part cloud stopped:** room $6C borrowed `$47`
> (Hargon room), whose animation has 2 flip pairs; the cloud's right cell
> used both, so animating the left cell TOOK OVER them (S99 r6 take-over).
> Measured in PyBoy that a 4-pair source (`$23`) moves both halves — the
> answer to "can I animate more than one tile" was always "yes, up to the
> borrowed animation's slots" (GreatTree sways 16). The S99 model itself
> was the problem, so S102 replaced it.
>
> **Engine (PROJECT_COMPILER §2.19; ROOM_DATA_FORMAT "Own tile animations
> (S102)"):** new compiler-owned bank **$6C** — bank $71 entry 3
> `CustomAnimSource` far-calls entry 0 `CustomTileAnimate` first (custom
> rooms only, vanilla dispatch guards). Per room, groups `[period, phase,
> seqlen, nslots, dw seq, dw VRAM dests]`; every step copies a WHOLE frame
> (16-aligned blocks in bank $6C) into the slot with GDMA at the start of
> HBlank (or VBlank lines 144-151), ≤ 8 tiles per frame, line 127 skipped
> (the LYC=127 STAT job hides sprites under the status bar — decoded +
> annotated: bank $00 `LCDCStateTable`, field state 1 measured). State:
> wCustomPool carve `wTileAnim*` $D0C5-$D109 (32 groups). Measured on the
> user's save: 13 tiles / 4 motions → every tile shows only authored frames
> on every one of 600 frames in **PyBoy and SameBoy** (new
> `tools/sameboy_anim_check.py` + `tools/sameboy/dwmcheck.c`), ≤ 8
> scanlines, no dropped frame; negative control (HBlank wait removed): 631 /
> 581 bad tile-frames (SameBoy / PyBoy — both block mode-3 VRAM writes);
> leave-and-return heals. Budget facts measured: vanilla GreatTree sway ~65
> scanlines and Zoma ~50 drop a frame per 32, 34 do not; the game never uses
> HDMA/GDMA, runs normal speed, its VBlank VRAM work ends at LY 148; **VRAM
> bank 1's tile area is empty in the field** (6 rooms + menu; battles not
> checked) → ROADMAP P3.3g (128 more tiles per room).
>
> **Editor (EDITOR_DESIGN §5.1 "As built S102"):** the **Animate** tab
> replaces "Make animated": select cells (Select tool drag / Shift+click /
> double-click) → Use the selected cells → Flip through frames (painter,
> 2-8 frames, loop / back-and-forth, shift / mirror / copy previous / undo)
> / Drift right / Drift left (as one picture ≤ 2 cells, or per tile) / Sway
> (1-3 px) → speed (presets + exact frames per step, "≈ N per second") →
> "only the selected cells" (own copies; the only thing that costs free
> tiles) or "every place drawn with these tiles" → Create; list + Edit (one
> undo step, keeps its place) / Remove; plain box: load %, free tiles, frame
> storage, groups; "How does this work?". The inspector's vanilla combo
> moved behind "Copy a vanilla room's animation…" (+ Make the selected cell
> still). Canvas: rectangle selection, preview plays own + vanilla, Anim
> outline includes own slots. Help topic *Animated tiles* (+ limits). Test
> ROMs **`DWM_S102_tile_anim_engine_test.gbc`** (patched, md5 `37194b4d…`)
> and **`DWM_S102_animate_tab_test.gbc`** (patched, md5 `394b5ee7…`, made
> through the GUI code paths): the user's project, room $6C — cloud (0,0)-
> (1,0) screen 0 drifts right, cloud (0,1)-(1,1) screen 1 drifts left, every
> tree sways, the screen-4 blue floor flips; the old `$47` flip still runs
> next to them. Bugs caught before delivery: KEY_LESSONS S102.
>
> **S102 r2 (user 18:30: "Wait wtf I cant have frames side by side
> anymore?? How can I paint them?"; editor-only, built, NOT yet
> user-tested):** the Animate tab shows every frame side by side (one
> painter each, wrapping to the panel width, frame 1 = the map, fixed);
> paint straight on any frame; the clicked frame is the yellow one the
> tools act on; Size − +. test_canvas v6 asserts it. `EDITOR_REVISION` =
> 'S102r2'. Pin unchanged `0d60486e…` (patched).
>
> **S102 r3 (user 18:51: "Can I still copy or shift individual
> quadrants?"; editor-only, built, NOT yet user-tested):** Ctrl+click picks
> one 8×8 tile, Ctrl+Shift+click a 16×16 cell (outlined on every frame);
> Shift / Mirror / Clear / Copy previous act on it; Copy (any frame incl.
> the map) / Paste (repeats to fill); test_canvas v6 asserts part-only
> edits + exact undo. `EDITOR_REVISION` = 'S102r3'. Pin unchanged.
>
> **Session sign-off 2026-09-29** (user: "Good work. We'll check expanding
> tileset next session(s) so make sure thats on roadmap. Hand off please");
> the in-game test of the two S102 ROMs was not separately reported. **Next:
> ROADMAP P3.3g** (VRAM bank 1 → 128 more tiles per room; first the
> full-game bank-1 census). **Hand-off: all S102 work = the diff against
> `f4b0ec1` (origin/master), delivered as `DWM-S102-tileanim-changed-files.zip`.**

> Last verified: 2026-09-27 (Session 101 — **ROADMAP P3.7b PART 2 (first
> half): CUSTOM BOSS FLOORS — per-gate floor count / boss floor / hand-made
> gates, MONSTER NPCs, CONVERSATION TREES (flags, YES/NO, battles of 1-3
> enemies, the vanilla helper exit), PROJECT ENEMIES with a weaker JOIN
> VERSION** (user: "I want custom boss floors"; "boss rooms WILL BE
> MULTISCREEN … a custom room hookable as an end boss room with all that
> entails (music, script, etc)"; "The event is still the same (fight,
> optional join, WAROBOU - NOT WATABOU - takes you away)"; "every monster
> has follower sprite, we can use that as BOSS NPC"; "New weaker join
> version … 'always/sometimes/never' join flag settable"; battles "1, 2 or
> 3"; vanilla boss rooms reusable; "Want to set floor count for all gates";
> "Fight starts on arrival - want that option"; "Dont forget fully custom
> gates"). S100 confirmed passed at session start ("1) yes passed").
> **S101 USER-CONFIRMED 2026-09-27 23:44 ("Can confirm everything works as
> intended") except the helper (point r2 below); r2 built, NOT yet
> user-tested.** Verifier PASS 6/6; clean `1ca6579…`
> byte-perfect (banks $04/$0B/$16/$54 comments only, both trees); **patched
> pin MOVED `7cd7257b…` → `9c813041…` (patched)**; test_compiler --rom
> 151/151; test_app --rom PASS (GUI build == pin); test_canvas --rom PASS
> incl. the new **v8** (a boss floor authored entirely through the GUI code
> paths, then played in PyBoy). `EDITOR_REVISION` = 'S101'.
>
> **Engine (all PyBoy-measured on the user's save unless noted):**
> `GateFloorDataTable` ($16:$70A6, 32×8) is a compiler-owned region fed by
> `custom.gates[]` (floors 2-99 incl. the boss floor, boss = a custom room —
> arrival on its "Inside gates" cell — or `vanilla:$xx`, `hand_made`);
> gates without settings keep their vanilla bytes (the example: all 256 B
> vanilla). The boss floor itself needs no code (entry 5 `jr_016_5be1` reads
> byte 4/5/6, no RNG). Hand-made gates: rules may take floor 1. **Monster
> NPCs**: NPC sprite ids $F0-$F3 read the display list $D7CA ([species+$10,
> 1]) and draw that species exactly like its follower; bank $60 entry 8
> starts with `CustomMonsterCast` (per-screen cast, ≤4 species, written
> before the NPC parse — survives scrolls). Census: 218 species captured
> (`extracted/monster_npc_sprites/`); 216 draws blank, **217-220 hang or
> crash** (refused by the compiler). **Project enemies**: `LoadEnemyStats`
> head → bank $14 `LoadEnemyStatsExt` → EIDs ≥ 519 come from the new
> compiler-owned **bank $6B** (`CopyEnemyRowExt`, 640 rows max);
> `LookupBossRedirect` reads `BossRedirectTableExt` (project `join_as` rows,
> then the vanilla 34). Joins measured: tier 0 = always joins; the JOIN
> VERSION's stats arrive (Court Dragon joins with the join row's stats); in
> a 2-3 enemy battle the join candidate is the LAST enemy knocked out
> (vanilla `$DD61`). **Music**: on the floor before a custom boss map, bank
> $71 `CustomRoomBGMResolve` plays that room's song (or $34).
>
> **Conversations** (`talk.steps`, PROJECT_COMPILER §2.18): say / ask
> YES-NO / if flags / set / clear / battle (1 enemy = `$5A`, 2-3 = DA03/05/07
> + DA02 + `$5B`; the steps after it run only on a WIN — a loss is vanilla:
> castle, half gold) / helper (a hidden NPC at a fixed slot is revealed,
> flies in with `$1C $16NN` to a screen-local cell next to the player, spins
> with `$47-$4A`, can speak, hops, then the `$3B` wavy fade to the
> destination) / move / end. `on_arrival` = the room's entry script (the
> fight-on-arrival option; `screen` limits it). Measured in the demo: talk →
> ask → 3-enemy battle (EID 520 + 327 + 327) → win → join prompt → flag →
> helper → Warden's Rest → walk off → GreatTree; the screen-2 DragonKid's
> blessing flag changes the lord's branch (1-enemy fight); hand-made Gate of
> Beginning floors 1/2 served, the stairs descend, Thorn Arena's fight on
> arrival → helper → Castle throne (14,5); Talisman's boss floor = the
> Villager Dragon room at its vanilla spawn (1,6). **Observed, not yet
> traced:** after a battle started by TALKING to a monster NPC, that NPC is
> not drawn again until the screen reloads (slot active, cast intact —
> the sheet reload path; after an arrival fight the monster NPC stays).
> Corrections (Iron Rule 6, both trees): opcodes $06 close text, $0D reveal
> NPC, $1C NPC animation ($16 fly-in, distance / curve in D8E3/4 — r2), $47-$4A face up/down/left/right
> (were "npc_buffer_write / npc_hide / npc_show"), $3B fade warp, $58
> FloorSkip; the helper's text says "Watabou:" (sprite $21; the FAQ agrees)
> — sprite and text are the author's choice per helper step.
>
> **Editor (EDITOR_DESIGN §5.1b "As built S101"):** Gates tab "Gate
> settings" (floors spin + Vanilla, boss floor combo = vanilla / another
> gate's vanilla boss room / any custom room + Open room + readiness, hand-
> made checkbox, Project enemies…), project-aware list (♛ boss, ✎ hand-made),
> floor plan and rule dialog (floor 1 on hand-made gates). Enemies dialog
> (from a vanilla row; stats, skills, AI, always / sometimes tier / never,
> join version, Make join version). NPC sprite picker **Monsters** tab
> (thumbnails from the census; canvas and NPC panel show the species).
> **Conversation dialog** (tree of steps with branches; per-kind editors;
> battle 1-3 enemy pickers; helper destination / landing cell / sprite /
> text; problems list gates OK) from the NPC panel ("New conversation…",
> "Edit talk…") and the "Inside gates" group ("Arrival conversation…", boss
> floor line; boss rooms default to no saving; boss rooms need a way out,
> not stairs). Test ROM **`DWM_S101_boss_floors_test.gbc`** (patched, md5
> `ec9cbc96…`, example project + 5 brand-new rooms, built through the
> Document API): Villager 4 floors → EMBER COURT (2 screens; GreatDrak
> lord, DragonKid blessing on screen 2, a sign NPC) → WARDEN'S REST; Gate
> of Beginning hand-made 3 floors: MOSS STAIR HALL → LANTERN STAIR HALL →
> THORN ARENA (fight on arrival); Talisman ends in the Villager Dragon
> room. Deferred (ROADMAP P3.7b part 2 rest): private floor-type rows,
> per-gate monster pools / floor bands, per-room encounters inside dives,
> > 32 gates, gate entrances, the maze look in the editor.
>
> **S101 r2 (user 23:44: "for romhack I want WAROUBOU the darker version …
> Its just a sprite swap"; "Watabou … faces THE WRONG WAY … Can I change where
> he lands so he lands left of player? Ideally always?"; built, NOT yet
> user-tested).** Warubou = NPC sprite **$39** (the dark twin next to $21 in
> the bedroom cutscene step; PyBoy frames) — now the helper default. The
> fly-in was mis-read: `$1C $16NN` moves the NPC from its CURRENT pixels,
> `$D8E3`·8 frames at +2 px right, down along the curve `$D8E4` picks — not a
> target tile (swept with a handler hook: (3,1)→y 24, (3,2)→38, (3,3)→51,
> (3,4+)→61 px from a (8,8) start). The compiler now flies a fixed +48/+43 px
> from start pixels it writes into the helper's slot, and by default computes
> the landing at RUN time: the player's LEFT (right on a screen's column 0),
> facing them (vanilla lands left of Terry and ends its spin facing right).
> PyBoy: Ember Court — player (4,4)… lands (3,3)/(3,4) exact pixels, facing
> byte 3 = right, toward the player; Thorn Arena — player (4,6), lands (3,6).
> test_canvas v8 --rom asserts the landing pixel + facing; test_compiler --rom
> 153/153, test_app --rom PASS, verifier PASS. Test ROM
> **`DWM_S101r2_warubou_test.gbc`** (patched, md5 `2934c12a…`; same demo,
> Warubou, landing beside the player). Pin UNCHANGED `9c813041…` (patched —
> the example has no helper). `EDITOR_REVISION` = 'S101r2'.
>
> **S101 r3 (user 11:18: "The editor needs a help tab … flag in docs that
> this a) needs to be built out and b) always kept up to date"; editor-only,
> built, NOT yet user-tested).** Help tab + Help → Editor help (F1): 10
> Markdown topics in `editor2/help/`, search; `_revision.md` stamp checked
> by test_app against `EDITOR_REVISION` ('S101r3'); ROADMAP **P3.H** (build
> out) + SESSION_PROTOCOL wrap-up item 7 (keep current). Also recorded: the
> editor's monster lists are VANILLA-sourced until P3.9/P3.10 (ROADMAP P3.10
> "S101 requirement"). Pin unchanged `9c813041…` (patched).
>
> **S101 r4 (user 11:38: helper "where is the conversation tab? I sometimes
> want it to say something"; castle options "teleport to castle and king is
> NOT there (priest says hi, heals you, gives herb); or king IS there and
> does a little speech … I want option of both"; World tab zoom + drag;
> built, NOT yet user-tested).** The helper's text was there but hidden
> behind an unticked checkbox at the bottom — now a "Warubou says something
> first" box at the top, and the step's tree line shows the text. **Castle
> arrival decoded** (GATE_GENERATION §7.7): `$D92B` 6/8 = priest blessing +
> heal, 7 = the King's speech chosen by `$D9E3` (33 gate speeches, none
> changes a saved flag — PyBoy on the user's save; `$D9E3` = the speech
> selector, not a "story counter": ROM scan, 2 readers). Helper option *at
> the Castle*: nothing / priest heal / King's speech (pick the gate).
> PyBoy (demo): Thorn Arena win → castle → priest heals (HP 1 → 999);
> second visit → the King's Villager speech. **World tab**: wheel zoom
> around the mouse (clamped), drag empty canvas to pan at any zoom, Fit / +
> / −. test_compiler --rom 156/156, test_app --rom (+ World zoom/pan check) PASS,
> test_canvas v8 --rom (King speech after the helper) PASS. Annotated (both
> trees, comments only): bank $0C castle dispatch / speech chain / NPC
> reader, the `$D92B` writers in banks $06/$07/$50. `EDITOR_REVISION` =
> 'S101r4'. Test ROM `DWM_S101r4_castle_test.gbc` (patched, md5 `7ec987df…`;
> the r2 demo + Thorn Arena: win → priest heal, return visit → King speech).
> User 12:36: "Fantastic job" + direction for P3.8 (the cutscene editor should
> edit / extend the King's cutscenes — ROADMAP P3.8); r4 in-game test not yet
> reported. **Hand-off: all S101 work = the diff against `833f56e`
> (origin/master), delivered as `DWM-S101-bossfloors-changed-files.zip`.**

> Last verified: 2026-09-27 (Session 100 — **ROADMAP P3.7b PART 1: CUSTOM
> ROOMS SERVED ON GATE FLOORS — data-driven rules (gate, floors, chance, flag
> conditions, once per dive), gate-room settings (arrival, Stairs down,
> saving, battles that follow the gate, gate or own music), Gates tab v1**
> (user: "we cant insert them into gates and trigger upon floor, or floor +
> flag, or assign % chance"; answers: gate rooms are mostly special-function /
> boss rooms without battles; "at most once per dive is useful"; "CANNOT save
> in random floors, ALWAYS CAN in special rooms inside gates. CANNOT save in
> boss rooms. I want that mechanic replicated"; floor 1 not needed; music
> "option for BOTH"; part 2 later "but give a sense of how much work" — ≈3-4
> sessions, ROADMAP; example "floors 2-3, 50%"). S99 not re-confirmed this
> session. **Built S100, NOT yet user-tested.** Verifier PASS 6/6 (check 5 now
> also runs `map_gate_names.py --check`); clean `1ca6579…` byte-perfect (banks
> $01/$06/$07/$16 labels, comments, re-sections — both trees); **patched pin
> MOVED `d072eb51…` → `4f13d2af…` → `91202c74…` (patched; S100 r2: the example
> gate rule gains `once_per_dive` — user 14:39 saw `gate_rotation` on floor 2
> AND floor 3 of one dive; PyBoy 40 dives: floor 2 19x, floor 3 12x, never
> both; new rules in the Gates tab now start as once per dive)**; test_compiler --rom 124/124;
> test_app --rom PASS (GUI build == pin); test_canvas --rom PASS incl. the new
> v7. `EDITOR_REVISION` = 'S100'. Test ROM `DWM-S100-gates-test-v2.gbc`
> (patched, md5 `d29e34b2…`; the first demo `398b1b5c…` is historical — it hid
> its switch in an invisible examine spot, user-rejected → Iron Rule 7): Gate
> of Villager — floor 2 always the REST STOP (island; a guide NPC says so, asks
> "Unlock the VAULT below?" — YES sets `demo_vault`; saving allowed, gate
> music), then THE VAULT (night palette, a sign NPC; no saving, own song,
> Villager battles) once per dive after the YES: 50 % on floor 3, else 50 % on
> floor 4 (PyBoy, 24 dives: 11 on 3, 8 of the other 13 on 4, never both). PyBoy on the user's .sav: real gate entry (the pedestal
> exit's bytes) → floor 2 served at (4,6) → lever YES → the real stairs → vault
> on floor 3, JOURNAL refused, song $A1, a pool-2 battle. **Caveat (user
> 14:39):** v2 still REUSES rooms — the rest stop is `gate_rotation` (the
> room the user already knew from the overworld) and "THE VAULT" is an
> island copy whose name clashes with the project's own medal vault room;
> the next demo uses brand-new rooms (Iron Rule 7). The user's "merchant" was
> the VANILLA merchant special room ($50/$51 family, floor 3), not a clone.
>
> **S100 r3 (user 15:11, three points; built, NOT yet user-tested).** Pin
> `91202c74…` → **`7cd7257b…` (patched)**; test_compiler --rom 126/126,
> test_app --rom PASS, verifier PASS. (1) *"Going into 'step down' from custom
> well — background is not CREAM but room-tile coloured"*: the descent
> transition (bank $06 `MapTransitionMachine` states $10-$17) blanks with tile
> $E0 (colour 1) under the room's attrs and then fades every colour to the
> palette BUFFER's colour 1 — both cream only because vanilla forces colour 1;
> rooms with own colour 1 (the Import tab default) showed their own colour.
> Fix: `MapTrans_S10_InGate` + `MapTrans_S12` same-size rewrites far-call bank
> $73 **entry 19 `GateWipeAttr`** (the 20×14 blank rows → attr 7) and **entry
> 20 `GateLeaveFreePal`** (once the room is squeezed to a line: buffer + HW
> colour 1 := cream). PyBoy (brand-new imported room, before/after): own
> colour around the shrinking room + own-colour blocks for ~2 s of loading →
> cream, room keeps its colours while shrinking; vanilla $50 pit: same
> pictures (single-scanline timing jitter only). (2) *"I can't seem to import
> the next gate floor icon from anywhere … by default it should always be
> displayed as the 'next floor down'"*: "Stairs down here" now PAINTS the
> vanilla well ($51 Priest room slots $2C-$2F, its plain surround replaced by
> the floor already on the cell) and adds it to the room's metatiles
> (`gates.WELL_*`, `Document.paint_well`). (3) *"separate the gate stuff from
> 'room/screen/selection' with its own arrow button … needs to be scrolled
> both down and to the right"*: own foldable section "Inside gates (gate
> floor)"; the sideways scroll was the animation combo (~1,400 px — one item
> is a 130-char sentence): every inspector combo now sizes to a short minimum
> (`inspector.narrow_combo`), popups keep full texts. **Found on the way —
> compressor bug:** `tools/compress_tiles.py` allowed copies of 257-274
> bytes, but the game adds the 19 in 8 bits → those wrap and the rest of the
> sheet lands 256 B early (a blank imported sheet drew as flat colour blocks).
> MAX_COPY = 256; `decompress_tiles.py` now decodes 8-bit like the game (the
> example sheet re-encodes — its old stream happened to decode right). Test
> ROM **`DWM-S100-r3-crystal-well-test.gbc`** (patched, md5 `5295a028…`):
> brand-new "Crystal Well Room" (imported purple floor / teal walls / pink
> crystals, own colour 1, a sign NPC that says what it is) on Villager floor
> 2, 100 %, once per dive; step into the well → cream wipe → floor 3.
>
> **Engine (GATE_GENERATION §7.6; PROJECT_COMPILER §2.16):** bank $16
> `GateDecisionFork` rewritten — the S41 hard-coded gate-1 → $6D branch and
> `CustomGate1Setup` removed; after the anchor check it calls **bank $71 entry
> 4 `CustomGateInsert`** (push/pop BC around the far call); the generated
> `GateInsertTable` is walked in list order, a rule rolls `RNG16 mod 100` only
> after its gate / floor / once bit / flag terms hold, so a gate without rules
> draws no RNG (A/B vs S99 on the Gate of Reflection: 18 decisions identical);
> a hit writes `wMapID`, `wInGateworld = 0`, the spawn pixels (the vanilla
> special handler's contract). **Once per dive**: `wGateDiveGate/Mask`
> ($DEBC-$DEBD) reset on floor 0 / another gate, saved via SRAM `$BFCA/$BFCB`
> in bank $73 entries 5/6 (PyBoy: save in the room → reload → not served
> again). **Saving**: bank $07 `SaveAllowCheck` same-size rewrite (vanilla
> verdict identical over all 256 mapIDs — byte interpretation of original /
> S99 / S100) + entry 5 `CustomRoomFlags` (`can_save`). **Battles**: entry 1
> gate byte $FF = follow the dive (pinned pools refused for gate rooms — they
> would re-route the dive). **Music**: no change needed — an unassigned custom
> room takes the gate path ($34; the boss theme on the floor BEFORE the boss
> floor, exactly like a maze floor — measured). Template 164 → 395 B,
> re-pinned. Bug caught before delivery: entry 4 returned a stale E at the
> table end (every floor load hung) — KEY_LESSONS S100.
>
> **Measured / corrected (DOC_AUDIT S100; Iron Rule 6 annotation same
> session):** vanilla special rooms appear only on floors 3, 6, 9 … (~50 %) —
> `Div8x8` divides B = `wCurrentFloor`, not an RNG value (GATE_GENERATION §3
> was wrong since S37); the game's floor N = `wCurrentFloor` N−1 and
> `last_floor` = the FAQ's floor count for all 32 gates; **gate names**:
> `extracted/gate_names.json` was one gate late for 23-31 (its tool read the
> boss redirect table as gate-indexed) and `gate_reference.py` had 12-17 in
> FAQ order — `map_gate_names.py` rewritten on `GateFloorDataTable` (floors +
> boss map, FAQ-checked), bank $01 comments fixed; **`SkillLearnReqTable` is
> 218 rows** — $06:$6034 is bank $06 entry 6 `FieldStateDispatch` (the S51
> re-section had swallowed it as rows $DA-$DD), re-sectioned back to code +
> `MapTransitionMachine` / 24-entry `MapTransStateTable` (the $C905 "gate-like"
> state = the transition STYLE of the room being left); SOUND_SYSTEM's boss-
> music floor was off by one; PROJECT_COMPILER §2.7's 32-flag pool stale (16).
>
> **Editor (EDITOR_DESIGN §5.1b "As built S100"):** **Gates tab** — the 32
> gates (ROM names, floor counts, ★ rules), rules table (Add / Edit / Remove /
> ▲▼ / Open room; readiness per room), **Floor plan** (per floor: each custom
> room's chance of being served, then the vanilla remainder / special-room
> floors / boss); rule dialog (room, floors 2..N−1 or any, chance, once per
> dive, flag conditions + new named flag). **Rooms tab** — inspector group
> "Inside gates" (served in, arrival Selected cell / Clear, stairs count,
> saving, battles off / follow the gate, music gate's / song, readiness,
> Gates tab…), Selection → More ▾ → "Stairs down here", canvas S↓ / G markers
> (draggable). Residuals: ROADMAP P3.7b part 1.

> Last verified: 2026-09-27 (Session 99 — **ROADMAP P3.3e ANIMATED TILES:
> the room tile-animation system measured end to end, made per-room for
> custom rooms, and surfaced in the editor** (user: "Animated tiles next";
> "indicate currently animated tiles (in vanilla)"; "Can preview animation
> (maybe button …)"; "Clones SHOULD get soure animation … Also yes migrate";
> borrowing "fine as long as it's clear whats happening"; "Gate floors do NOT
> have animation … interesting to add. but not necessary"). S98 not yet
> re-confirmed this session beyond its doors. **Built S99, NOT yet
> user-tested.** Verifier PASS 6/6 (check 5 now also runs
> `census_room_animation.py --check`); clean `1ca6579…` byte-perfect (bank
> $01 labels + comments, both trees); **patched pin MOVED `ce24de8b…` →
> `d072eb51…` (patched)**; test_compiler --rom 106/106; test_app --rom PASS
> (GUI build == pin); test_canvas --rom PASS incl. the new v6.
> **Session sign-off 2026-09-27** (user: "Fantastic job. Package everything
> up."), after seven rounds (r2 borrowed water moves — user: "Excellent.
> Looks good."; r3 Make animated tab + frame pads; r4 unintended-animation
> repair + Make still; r5 per-quarter part tools; r6 take-over + the count;
> r7 still quarters, automatic split move, numbered tab — each block below).
> Rounds r3-r7 are editor-only (pin unchanged); r7's palm path is verified
> on the user's project + PyBoy, not yet re-tested by the user in-game.
> Final `EDITOR_REVISION` = 'S99r7'. Round-1 `EDITOR_REVISION` = 'S99' (historical). Test ROM `DWM-S99-anim-test.gbc` (patched, md5
> `d01a08e5…`, historical — superseded by r2 below): GreatTree 2F Library door → a Castle clone hub (fountain
> water rolls — its source animation) → four doors on the hub: Room of
> Beginning clone (swirl frame swaps), Digster arena clone (pool rolls),
> "Fountain water, NO animation" (Castle-sheet room, animation none — the
> painted water stands still) and "Castle art + GreatTree sway (borrowed)"
> (the Castle art in slots 64-79 sways). PyBoy on the user's .sav: walked in
> through the Library door; every room's VRAM after 300 frames == the census
> schedule's prediction, byte for byte.
>
> **Measured (Iron Rule 6 annotation same session; ROOM_DATA_FORMAT
> "Animated tiles"; DOC_AUDIT S99):** the bank-$01 `PerRoomVRAMDispatch`
> table has **112** entries ($00-$6F, not 107); 65 handlers (labels
> `RoomAnim_<room>` / `RoomAnimNone_<map>`) ROLL 2 tiles 1 px (3 R : 1 L per
> 128 frames; Castle 77-78 and 9 more), SWAY 64-79 (GreatTree), or SWAP a
> shown tile with a hidden second frame in the same sheet (every 32 frames;
> Orochi 64, Coliseum 25/32, Arena Battle 16/32); map $08 only pulses the
> DMG palette; Secret Passage and Goopy 1/2 are INERT (blank slots). The
> ONLY BG tile animation in the ROM; gate floors never animate. **The "bare
> `ret` handler corrupts the palette" premise (KEY_LESSONS v8, CROSSBANK §6,
> ROADMAP P3.3e (c)) is FALSE** — measured: identical screen and palette
> buffer; only the 77/78 roll stops. Census tool: every handler forced
> through the dispatch (hook sets A) over a patterned VRAM → `extracted/
> room_animations.json` incl. an exact per-counter `schedule`.
>
> **Engine + compiler (PROJECT_COMPILER §2.15):** same-size rewrite of
> `PerRoomVRAMDispatch` $60F9-$6118 (six `bit/ret nz` guards → `and $fe /
> cp $10`, equivalent over all 65,536 (wGameState, $C8EF) pairs) funds the
> custom-room path: `cp $6B / jr c` → bank $71 entry 3 `CustomAnimSource`
> (E := `CustomAnimSrcTable[mapID-$6B]`) — replaces `call
> MapIDClampForDispatch` (every custom room ran Castle's roll on 77-78;
> clones never animated). `custom.rooms[].animation` = `none` ($6B, the
> table's own `ret` row) / `source` / a vanilla map id; absent = legacy
> Castle + warning; $08 and non-vanilla ids are errors. Template head 142 →
> 164 B, re-pinned. Vanilla rooms: A/B vs the S98 build from one savestate —
> final VRAM / screen / counter identical, sub-frame tile-load timing only.
> Also: `audit_mapid_range.py` selftest fixed (failing since S73: 9 overdue
> verdicts + 2 new).
>
> **Editor (EDITOR_DESIGN §5.1 "S99 additions"):** canvas **Anim** layer
> (dashed outline of animated areas — vanilla rooms show their own
> animation), **▶ Play** on the screen/state row (replays the measured
> schedule at game speed), inspector **animated tiles** (None / Same as
> source / Borrow + a plain-language line, warns when the borrowed room's
> sheet is not this room's), slot map teal (dashed = hidden frame) + "also
> protected for rooms sharing this sheet", picker teal corner; slot
> protection follows each room's animation (77/78 free in `none` rooms);
> clones = `source`; projects migrate on open (source when the room still
> draws with its source room's sheet, else none). Residuals: ROADMAP P3.3e.
>
> **S99 round 2 (user: "I borrowed the moving water from castle and put it
> into my custom room but it doesnt move"; built, NOT yet user-tested):** the
> Borrow-tab import copied the water GRAPHIC into a free slot, and the game
> animates SLOTS — now an animated vanilla tile is imported into its own
> slot indices (+ swap partner frames; tiles in the way relocated) and the
> room switches to that room's animation (asked when it would replace
> another animation; status line reports walkability of the fixed slot).
> Editor-only — pin unchanged `d072eb51…` (patched). `EDITOR_REVISION` =
> 'S99r2'. Test ROM `DWM-S99r2-anim-test.gbc` (patched, md5 `f3f27d7e…`,
> historical — superseded by r3; r1 `d01a08e5…` historical) = the r1 demo + a 5th hub door "To Farm +
> Castle water" (a Farm-sheet room that borrowed Castle's water — it moves;
> PyBoy on the user's .sav: VRAM == census prediction).
>
> **S99 round 3 (user: "please make the 'make animatable' tab … re-paint a
> second tile in a paint-like manner"; "Double clicking on the tile doesnt
> bring up any animation info"; built, NOT yet user-tested):** the **Make
> animated** tab (EDITOR_DESIGN §5.1 "S99 r3") — double-click a cell, pick
> slide / two-frame flip, pick among the animations that can host it
> (ranked; FULL / no room / walkability / what a switch stops), paint frame
> B in a 16×16 pad in the tile's palettes, preview, apply (one undo step).
> Found while building: switching a room's animation starts EVERY slot of
> the new one moving, so unrelated tiles in those slots are moved out first
> (also applied to the r2 borrow path). Editor-only — pin unchanged
> `d072eb51…` (patched). `EDITOR_REVISION` = 'S99r3'. Test ROM
> `DWM-S99r3-anim-test.gbc` (patched, md5 `859b46cc…`; r2 `f3f27d7e…`
> historical) = r2 + a 6th hub door "To Made animated": Farm water made to
> slide and tree stumps made to flip (mirrored second frame), both on Zoma's
> animation; PyBoy on the user's .sav: VRAM == census prediction.
>
> **S99 round 4 (user: "Why is the mirror in $6b moving? I never wanted it
> to move. It also didnt move in earlier editor versions."; built, NOT yet
> user-tested):** cause = the S99 migration (clone → `source`) checked the
> room's SHEET but not the art in the animated slots — a pre-S99 import had
> put an Arena-Rooms mirror into the Servant clone's hidden flame slots
> 62-63. Fix: the editor finds such tiles on open and offers to move them
> to still slots (source art restored; one undo step); **Make still** in the
> Make animated tab; Make animated stores explicit ids. User project
> verified: prompt lists the mirror, fix moves 62->79 / 63->78, PyBoy: no
> on-screen tile of $6B moves (before: 62/63). Editor-only — pin unchanged
> `d072eb51…` (patched). `EDITOR_REVISION` = 'S99r4' (historical).
>
> **S99 round 5 (user: "allow copy of quadrants separately not just a -> B.
> Make it easier to edit"; built, NOT yet user-tested):** Make animated
> frame pads get part tools — Whole tile or one 8×8 quarter (buttons or
> Ctrl+click), acting on the edited frame (yellow border): Copy / Paste,
> A → B, B → A, A ⇄ B, flips, 1 px shifts, Clear, local Undo / Revert.
> test_canvas v6 exercises each on one quarter (others untouched) and
> undoes back exactly. Editor-only — pin unchanged `d072eb51…` (patched).
> `EDITOR_REVISION` = 'S99r5' (historical).
>
> **S99 round 6 (user: "Make animated is greyed out … Surely it should
> allow me to shift animation to tile I'm editing??" + "Would be good to
> have a count"; built, NOT yet user-tested):** a full room animation can
> be TAKEN OVER (the tile moving there keeps its look in a still copy of
> the taken quarters; asked first); slots the tile gives up count as free;
> the grey button's note names the limit (animation too small / N more
> free wall or walkable slots needed); a count box in the Make animated tab
> + Selection panel ("slide 2 of 2 slots used — FULL", moving tiles).
> Verified on the user's project: fountain room ($6E) and GreatTree
> take-overs keep every cell identical at frame A, start only the chosen
> tile's cells; PyBoy $6E: new tile's slot 77 moves, the water's taken
> quarters draw still slot 115. Test ROM `DWM-S99r6-takeover-test.gbc`
> (patched, md5 `1afa30a9…`) = the user's project + that fountain-room
> take-over. Editor-only — pin unchanged `d072eb51…` (patched).
> `EDITOR_REVISION` = 'S99r6' (historical).
>
> **S99 round 7 (user: "I go to fountain room, click on palm, and want to
> make it animated but button is GREYED OUT"; built, NOT yet user-tested):**
> reproduced on the user's project (fountain tileset: 0 free wall slots,
> 11 walkable; palm = 4 different quarters). Fixes: unchanged quarters stay
> still (no slot, same walkability); the wall/walkable split moves
> automatically when one side is short; the check counts every slot a
> switch moves (Zoma's roll 49-50 too) and frees the old animation's; the
> tab is numbered ①-④ with the grey reason above the button. User project:
> palm top quarters + fountain water both on Zoma (after Tileset → purge
> unused) — look + walkability identical, only palm + water cells move;
> PyBoy $6E: palm/water slots move on screen. Test ROM
> `DWM-S99r7-palm-test.gbc` (patched, md5 `6176f21f…`) = user project +
> purge + palm (demo frame B: top quarters 1 px right) + water on Zoma.
> Editor-only — pin unchanged `d072eb51…` (patched). `EDITOR_REVISION` =
> 'S99r7'.

> Last verified: 2026-09-26 (Session 98 — **rooms group C = ROADMAP P3.7:
> DOOR OBJECTS, one-way teleports, EXAMINE spots + STEP-ON triggers, TALK
> scripts that set flags, World graph v0 — plus a user-driven round of
> tileset / walkability tools** (user: "Let's finish room work"; "mostly
> two-way but I want the option of having a one-way teleport … a separate,
> rare object"; "happy with state rules as long as they're flexible
> enough"; "I just need the flag system to work so I can make an NPC set a
> flag"; P3.4 PyBoy preview left aside). S97 USER-CONFIRMED at session
> start ("Can confirm s97 pass"). **User-tested in part 2026-09-26:** doors
> in the user's own project work both ways ("Works now") and arrive ON the
> door ("Its now fixed"); walkability flip / purge used on the user's
> project. **Built, NOT yet user-tested:** talk scripts (YES/NO, flags,
> move), examine / step spots in game, World tab. Verifier PASS 6/6; clean
> `1ca6579…` byte-perfect (bank $0B/$01/$06 renames + comments, both
> trees); **patched pin UNCHANGED `ce24de8b…` (patched)** — no engine,
> template or example-project bytes changed; test_compiler --rom 97/97;
> test_app --rom PASS (GUI build == pin); test_canvas --rom PASS (v5 doors
> / spots / talk / teleport + the tileset checks, pixel-position arrival).
> `EDITOR_REVISION` = 'S98r3'. Test ROMs (all patched): demo
> `DWM-S98r3-doors-test.gbc` md5 `72cd22fe…` (GreatTree 2F Library door ⇄
> "Door Lab": examine book facing up, step-on tile, YES/NO NPC that sets
> `lab_flag` and reloads the room in its rule state ⇄ Room B with a one-way
> teleport back; earlier builds `56e407cf…` r1 / `e55b0651…` r2 are
> historical); the user's own project `my-dwm-hack-S98r3-doors.gbc` md5
> `2537a593…` (patched).
>
> **Measured (Iron Rule 6 annotation same session; ROOM_DATA_FORMAT
> "Interact entries ≥$80" + "Arrival and edge rules"; DOC_AUDIT S98):**
> the "$8F spawn point" never existed — `$80-$83/$8F` are EXAMINE spots
> (A press on the own or faced cell; low nibble = required facing, F =
> any), `$90` is a STEP-ON trigger (walk onto the cell; not on arrival);
> byte 4 = a room script index; both bank-$0B scans STOP at the first NPC
> entry (spots must precede NPCs — vanilla 157/160; `$1F`'s trailing
> `$81` is dead). Arrival = the exit row's bytes 4-6 only; arriving on an
> exit cell never re-fires it; screen-byte bit 7 = +8 px = drawn HALF A
> CELL below (pixel-measured r3: vanilla Library → GreatTree `$88` lands at
> y=320, standing positions are ≡ 8 mod 16); x=0/9 / y=0 exits bordering
> another screen never fire (the push scrolls); a custom y=7 exit blocks
> scrolling down. MapTransitionFull takes absolute pixel coordinates;
> YES/NO answer in `$C83C` (0 YES / 1 NO). Labels:
> `RoomEntry4_TalkTargetLookup`, `RoomEntry5_StepTriggerLookup`,
> `SearchStepTriggers`, `InteractEntryAtPos`, `TalkScanNPCSlots`,
> `NPCSlotAtPos`, `TalkScanExamineSpots`, `ExamineSpotMatch`.
>
> **Compiler (PROJECT_COMPILER §2.14):** `examine` / `step` npc kinds
> (emitted before NPCs); door OBJECTS = exit rows with `door` + `name` +
> `link` (vanilla doors `vdoor_MM_k_x_y` via tagged `entrance_redirects`,
> `twin_of` for double doors), an unconnected door emits nothing (warning);
> `talk` scripts (text, optional `question`, then / yes / no blocks with
> `text`, `set`, `clear`, `move`) lowered to ops; validators: spawn-script-0
> warning replaces the spawn error/warning, exit to a missing destination
> screen = error, edge-vs-scroll warnings, talk and door-link checks.
>
> **Editor (EDITOR_DESIGN §5.1 "S98 additions" + "S98 r2" bullets, §5.8):**
> round 1 built pair-doors through a coordinate dialog; the user called it
> "bad design" → **round 2/3 (the user's design):** select a cell →
> **+ Door (D)** puts an unconnected named door there; double-click → name
> + connect to any door object (yours in any room, or a vanilla door) from
> a searchable list — no coordinates; links two-way; delete leaves the
> partner unconnected; doors arrive ON the partner door (whole tile —
> user: "You arrive on tile fully always"); doors on a scrolling edge are
> refused / drawn red **D!**; **+ Examine (X)**; double-click an NPC / spot
> = edit its talk; talk editor with Ask YES/NO and per-answer say / flags
> ON / OFF / move; More ▾ → one-way teleport / step-on trigger; World tab.
> Tiles (user reports): the Walk toggle = walkability mode, refused flips
> say why (silent since S95); copied rooms get their OWN tileset copy
> ("stop sharing by default"), a shared sheet is flagged with "Give this
> room its own copy"; a full walkable side offers moving the wall/walkable
> split down one slot (asked; PyBoy: the cell walks, a control wall blocks,
> screen pixel-identical); Tileset tab **Purge unused borrowed / own**
> (user project: 15 unplaced borrowed metatiles held 30 walkable slots).
> Rect / Fill off the tool bar. S98 r1 projects migrate on open (door
> pairs → linked objects; step-out arrivals → on-door). Door-arrival STATE
> (S97 carry-over) closed by user decision: state rules keyed on a flag
> the talk sets. Signposted for next session at the user's request:
> **ROADMAP P3.3e animated tiles**. Residuals: ROADMAP P3.7.

> Last verified: 2026-09-25 (Session 97 — **rooms group B: P3.5a flag
> STATE RULES + P3.5 NPC INSPECTOR, with the NPC behaviour engine decoded**
> (user: "all of B"; rule terms AND-ed — "Flag A set and Flag B set but C
> NOT set"; door-arrival state moved to P3.7). Built S97; **USER-CONFIRMED
> 2026-09-26** (S98 start: "Can confirm s97 pass" — r1 + r2). Verifier PASS 6/6; clean `1ca6579…` byte-perfect (bank $06
> jump tables re-sectioned + bank $00B/$01/$06 comments, both trees);
> **patched pin MOVED `5db25d15…` → `6e97fd37…` (patched)** — hand-staged
> patches/ == compiler build == GUI build (`--apply`'d); test_compiler
> --rom 74/74; test_app --rom PASS; test_canvas --rom PASS incl. the new
> v4 acceptance. Test ROM `DWM-S97-npc-rules-test.gbc` (patched, md5
> `2da054a7…`, a fresh demo project — NOT the example content): GreatTree
> 2F Library door → an NPC "zoo" (8 behaviours, each NPC says its type) →
> east edge → a Servant-room clone that burns until the firefighter NPC
> sets flag $0158 (YES → the room reloads cleared; the arsonist in the
> cleared state relights it). PyBoy: both directions via real talk + choice.
>
> **Decoded (Iron Rule 6 annotation same session; ROOM_DATA_FORMAT "NPC
> behaviour types" + "NPC RAM slot"):** the NPC type byte = facing (bits
> 4-5) | HIDDEN (bit 6: not drawn, not solid, no behaviour, not talkable —
> measured) | behaviour (bits 0-3) dispatched every frame through bank $06
> `NPCBehaviourTable` ($4050, 16 dw — was misassembled as code, plus 9
> sub-tables and 2 byte tables). 13 behaviours measured by poking a live
> Bazaar slot: stand (keep facing) / stand_return / stand_fixed / spin /
> pace ±1, ±2 (right-first, left-first) / right-3 / 2×2 square / figure 8 /
> sway / gate wanderers E-F (act only on the `$C926` gate screen). Walkers
> never test tiles (walk through walls and off-screen); the player blocks
> them (bank $06 entry 0 + $01 AdvanceNPCPointer undo the step, pause $20).
> Corrections: DOC_AUDIT S97 (npc_names.json type_names were guesses;
> BANK04 "+$05 bit 0 = interacting" = walking; $48/$49 hide/show unverified;
> stale Key Constants).
>
> **Engine + compiler (PROJECT_COMPILER §2.13):** `custom.rooms[].
> state_rules` (ordered, first match wins, optional `screens`, trailing
> unconditional rule = "Otherwise") → generated `CustomStateRulePtrTable`
> (bank $60) → template entry 8 `CustomStateRules` (head 383 → 492 B,
> re-pinned), called from bank $17 `CustomAttrCheck` FIRST via
> `StateRulesHook17` (3 B from the `ds 12` reserve) and from
> `CustomReadStep`. **Measured S97:** at a custom-room load the bank-$17
> attr/palette walk reads the step counter BEFORE bank $0B Entry 0 — rules
> only in Entry 0 gave the cleared layout with the burning palette (A/B,
> KEY_LESSONS S97). Rules make custom-room state persistent across
> save/reload (counters are transient, flags are saved). NPC entries gain
> `behaviour` / `hidden` / int `script`; validators warn on gate-only
> behaviours and walker paths leaving the screen. The example project's S92
> rank demo moved from the `entry:medal_vault` prelude to
> `arena_clone.state_rules` (PyBoy: same NPC sets; vault entry unchanged).
>
> **Editor (EDITOR_DESIGN §5.1 "S97 additions"):** State rules group
> (+ Otherwise combo, flag picker incl. vanilla story flags, New named flag,
> "State shown when" line); NPC panel (sprite picker, facing, behaviour with
> measured descriptions, hidden, talk script / New talk text / Edit text,
> per-state presence, delete), Add NPC here, drag-to-move, walk-path overlay
> (red dots on walls/off-screen), facing ticks, read-only form for vanilla
> NPCs; stale selection cleared on navigation. `EDITOR_REVISION` = 'S97'.
> Residuals (ROADMAP P3.5): hidden-entry reveal mechanism unmeasured; the
> named-flag pool is 16 flags; walkers ignore walls (warned); sprite-sheet
> budget still a count warning.
>
> **S97 round 2 (user test of r1: 4 issues; USER-CONFIRMED 2026-09-26).**
> Patched pin MOVED again `6e97fd37…` → **`ce24de8b…` (patched)**; test ROM
> `DWM-S97-r2-textbox-test.gbc` (patched, md5 `02c05364…`, the r1 demo with
> own-colour-1 palettes in the zoo (magenta) and the servant room (green)).
> (1) **Text boxes in free-colour rooms took the room's colours** — the
> dialog box (bank $06 states 2/6/9, close 12/15/19) and the YES/NO box
> (bank $56 `SetB56_4855`/`48a1`, bank $00 `ClearTextBitsRedraw`) write tile
> ids only; the room's GBC attrs stay under them. Same-size far calls to
> bank $73 entries 14-18 save the covered attrs (`wBoxAttrSave`/
> `wChoiceAttrSave`, 132 B carved from `wCustomPool`) and set palette 7
> while the box is up, then restore them cell by cell — only in custom rooms
> whose palette carries a free-colour marker. PyBoy: box + choice cream in
> both rooms, top and bottom box positions, attrs restored after close;
> vanilla Bazaar + non-free custom rooms pixel-identical to r1. (2) **Talk
> text per box**: measured — a box = 2 lines × 18 cells, "*:" leaves 16 on
> box 1 line 1 ($EA opener: no indent; the vanilla indent is $EB); cells
> past an edge wrap and are overwritten (lost); a 3rd line scrolls without
> waiting. New `boxes` dialogue form ($FA $F7 $EF $EE between boxes, vanilla
> choice tail `…? $E7 $F0`), auto `text` now flows into boxes; editor
> `talk_editor.py` = one editor per box with an in-game preview drawn with
> the ROM font (bank $4F $4010, glyph = code) — red split word, lost cells,
> Fit / Fit all. (3) Right panel: NPC is its own section; every launch opens
> with only Metatiles expanded; selecting an NPC opens the NPC section.
> (4) New named flag in the rule dialog is now a real item of every flag
> list (the new row showed the name while its list pointed at item 0).
> **Still true: nothing in the editor SETS a flag yet** (script ops only) —
> a new flag stays clear in game until a script sets it.

> Last verified: 2026-09-25 (Session 96 — **"Finish out the rooms stuff":
> group A = tiles & tilesets — P3.3c slot map + vocabulary release, tileset
> switching / blank sheets, the IMPORT ART tab (DWM2 PNG rips → room tiles,
> palettes, metatiles, stamped screens), per-subtile metatile palettes,
> bank space meters — and "Make editable" fixed for ALL 98 vanilla rooms.**
> Round 1 changed no patch bytes (bank_004 patch/disassembly gained
> comments + alias labels only — clean build `1ca6579…` byte-perfect), example
> project regrouped (same words — pin `fc1caa98…` held); round 2 added the
> FreeColor1Hook engine patch (pin → `07a71f20…`, patched, see below);
> verify_integrity PASS 6/6 (check 5 now also selftests the new opcode
> arity table); test_canvas --rom PASS incl. v3 + the all-clones sweep.
> Round 4 (menu fix) moved the pin to `5db25d15…` (patched). **USER-CONFIRMED
> 2026-09-25** ("Everything works"). Test ROM: `DWM-S96-pei-import-test.gbc`
> (patched, md5 `f3d45a42…` round 1, superseded by `fe5f3f9d…` round 2 and
> `023b7c65…` round 4 — all historical) — the GreatTree 2F Library door leads into DWM2 Pei imported
> from the user's PNG (6 screens, 87 slots, auto-marked walls); an exit on
> the left path returns to GreatTree 2F. PyBoy: door → Pei at the authored
> cell, VRAM == canvas, walls block, scroll between screens, exit returns.
>
> **Built (owning: EDITOR_DESIGN §5.1 "S96 additions"; PROJECT_COMPILER
> §2.11 S96 notes + §11; TOOLS_AND_DATA S96 rows):**
> - **Tileset tab (P3.3c):** 128-slot map (placed / my metatiles /
>   vocabulary / released / animated / free, changed-graphic dot, threshold
>   line, hover users, click = canvas highlight), per-side free counts
>   everywhere, "Release unused vocabulary" (persisted `_editor.
>   released_vocab`), picker flags. Vocabulary now DERIVED from the source
>   room (`Document.tile_usage`), not session-registered — which also fixes
>   a latent hole: the first import after localizing a sheet did not
>   protect the vocabulary.
> - **Change tileset** (vanilla / project / new blank) + New room "blank
>   tileset"; `Document.set_room_tileset`, `new_blank_tileset`,
>   `tileset_origin`.
> - **Import art tab** (`editor2/core/png_import.py` + `app/import_tab.py`):
>   the user's spec — open PNG, per-panel grid (auto from each panel's
>   corner; nudge with arrows; Auto-align), mask, walls (same tile
>   everywhere), key colours, palette fit to 4 slots under the engine rule
>   (colour 1 cream / 3 black forced → two free colours per slot; DWM2 art
>   has three, the one nearest cream is folded), "keep" slots, "Show as
>   GBC", budget, Add to My metatiles, Stamp with spill onto new screens.
>   `Document.import_png_cells` reuses identical graphics, keeps wall BRs
>   below / walkable BRs above the threshold, fails before writing.
> - **Metatile `pal` per subtile** (int or list of 4): 7.5% of vanilla
>   cells mix slots; painting them used to flatten them.
> - **Space meters** $60/$64/$67/$71 (`compiler.measure_banks`).
>
> **Found + fixed (DOC_AUDIT S96; KEY_LESSONS S96):** cloning was broken for
> most vanilla rooms — `extract_room.py` read every room's scripts from bank
> `$0D` (clones of Castle/GreatTree/Farm… carried filler), parsed only 8
> attr screen slots (GreatTree → KeyError 8), and used decompile_script's
> opcode arity, wrong for 36 opcodes; the command table has **102** rows
> (`$64` BranchIfPartyHealthy, `$65` WaitDD80), not 100. New
> `tools/script_param_counts.py` derives every opcode's arity from the bank-
> $04 handler code (counter increments per path; tails $55F5 / $7212 /
> ret) → `extracted/script_param_counts.json`, used by extract_room,
> compile_script, decompile_script and scriptgen; bank_004 catalog
> annotated in both copies. Clones also get per-screen step-0 palettes
> (Labyrinth screen 1), and screens outside the record's scroll area are a
> warning (vanilla sub-room screens). Result: 98/98 rooms clone, 211
> screens / 526 states pixel-identical, every clone compiles; nine clones
> (Castle, GreatTree, Bazaar, Farm, Arena Lobby, Starry Shrine, Library,
> Healer boss, Labyrinth) load and render in PyBoy with VRAM == canvas.
>
> **S96 round 2 (user feedback on the intermediate files — "imports
> perfectly", "GreatTree make-editable works, copying, teleporting"):**
> - **Own colour 1 (engine, byte-changing):** the forced cream is bank $17
>   `LoadPal_4102` copying system slot 7's colours 1/3 into slots 0-6 at
>   palette load (GATE_GENERATION §7.1). `FreeColor1Hook` (same-size jp +
>   bank-tail code) skips slots 0-3 for custom rooms whose palette carries a
>   bit-15 marker in slot 0 colour 3 (`free_color1` in project.json; no
>   vanilla palette sets it). Import tab defaults to it (Pei: 1417/1440
>   subtiles exact vs 632). **Reference patched pin → `07a71f20…`**
>   (test_compiler 61/61, test_app --rom == pin, example rooms' palette RAM
>   unchanged in PyBoy). User SameBoy test FAILED the menu (washed out
>   after closing) → fixed in round 4 below.
> - Right panel: foldable sections in a vertical splitter; palettes show
>   slots 0-3 by default. Import list: "Remove" + tooltips (every opened PNG
>   stays in the project).
> - Test ROM `DWM-S96-pei-import-test.gbc` rebuilt with own colour 1
>   (patched md5 `fe5f3f9d…`).
> **Round 3 (user):** "not enough free tileset slots in ts_24_00" (a Servant
> clone's sheet already full of earlier imports) → the import no longer binds
> unmarked cells to the walkable side (walkability is the author's; strict
> mode optional), the tab offers "New room…" (blank tileset) and the error
> names release / blank-tileset; foldable right panel "not visible" = the
> delivery folder rsync'd without a trailing slash (landed in a subfolder)
> → `EDITOR_REVISION` now shows in the title bar and build log.
> **User result 2026-09-25: "Great job. Everything works."** — rounds 1-4 of
> group A USER-CONFIRMED (menu / battle return in a free-colour room included).
>
> **Round 4 (user SameBoy report: "opening menu then going back … everything
> becomes blinding white … permanently, including when screen shifting";
> "coloured background squares as it opens"):** reproduced in PyBoy (a
> legitimate menu needs a non-empty party — `give_party_monster` — the
> old "hijacked state cannot open menus" note was just an empty party).
> Cause 1: the field menu calls `LoadPal_4102` standalone (via $17 entry 6)
> and nothing reloads the room palette on close; round 2's marker was
> cleared by the first load, so the menu re-forced cream into slots 0-3 for
> good. Cause 2: the menu blanks the BG to tile $E0 (colour 1) under the
> room's attrs for ~8 frames before its palette-7 attr fill. Fix: per-slot
> markers that survive in the buffer (FreeColor1Hook) + bank $06 A-press
> tail same-size far call to bank $73 entry 13 `MenuOpenFreePal` (hardware
> colour 1 := cream for marked slots; the close push restores). PyBoy:
> cream wipe, own colours after close, after INFO sub-pages, screen
> scrolls and a won battle; vanilla-room menu 619/620 frames identical to
> round 3. **Pin → `5db25d15…` (patched).** Test ROM
> `DWM-S96-pei-import-test-r4.gbc` (patched, md5 `023b7c65…`).
> Intermediate files are always delivered for GUI testing (user rule). The attached .sav has its save-exists
> flag ($A002) = 0, so PyBoy could not continue from it.

> Last verified: 2026-09-24 (Session 95 — **user feedback round on S94b:
> the metatile VOCABULARY, borrowing tiles from other rooms, and the
> old-project build failure.** Editor-only session: no patches, no
> disassembly, example project.json untouched; patched pin stays
> `fc1caa98…` (GUI build == pin; verify_integrity PASS 6/6; test_compiler
> --rom 61/61; test_app --rom PASS; test_canvas --rom PASS incl. the new
> import checks). NOT yet user-tested.
>
> **User points answered/built:**
> 1. **"This room's tiles" never shrinks.** The picker's first section is
>    now the room's whole vocabulary: every metatile on ANY screen/state of
>    the room plus everything its vanilla source room uses (cached per
>    source map). Painting over a tile no longer removes it; the vocabulary's
>    sheet slots are PROTECTED from reuse (`Document.protect_tiles` /
>    `used_tiles`, which now also counts author metatiles and 77/78).
> 1.5 **Borrow tiles from another room, drawn with THIS room's palettes** —
>    "Borrow tiles from:" combo above the picker adds a "From <room>"
>    section. Same tileset (byte-identical sheet): click = brush. Other
>    tileset: click IMPORTS the 4 subtiles into the room's tileset
>    (`Document.import_metatile`: localizes the vanilla sheet into the
>    project if needed, reuses identical graphics already present, else
>    copies into free slots — the bottom-right subtile keeps its wall/
>    walkable side of the threshold, the others take any free slot — and
>    the result lands in "My metatiles"). Free-slot budget = 128 − used −
>    protected vocabulary (median vanilla room leaves ~75 slots; GreatTree
>    8, Arena Rooms 1 — the import says so when it fails). PyBoy: a Castle
>    brick metatile imported into a Farm clone renders in-game under the
>    Farm palette (test_canvas --rom, sheet bytes + VRAM indices asserted).
>    `SnapshotCommand` now rolls back and drops itself (`setObsolete`) when
>    its op raises, so a failed import leaves no trace.
> 2. **Teleport → specific state:** not possible as data yet — a door only
>    carries destination/screen/spawn; the state shown is whatever the
>    destination screen's step counter holds at LOAD (S92 load-order rule),
>    and vanilla sets counters from flags via scripts. Designed, not built:
>    declarative **state rules** `{flag → state}` per screen evaluated in
>    bank $60 entry 0 (`CustomReadStep`) before the counter read — one
>    small engine hook + compiler table — which gives flag-driven room
>    versions without any script; a door-specific state then = the source
>    door setting a flag. Queued as ROADMAP P3.5a.
> 3. States confirmed good by the user.
> 4. **Build failure "mapID $6B requires a 'record'"** = an S93-era
>    project.json (the Desktop checkout) opened by S94b editor code (the
>    Downloads checkout). `Document` now MIGRATES on open: rooms `$6B-$6D`
>    without a record get the legacy hand-patched `$26DD` rows
>    (`LEGACY_RECORDS`), logged as "MIGRATED … Save to keep it". The CLI
>    compiler stays strict.
>
> **Round 2 (same session, user feedback on the clone workflow):**
> 5. **New screen lost the palette** (servant clone: burning state deleted,
>    second screen came up in the burning colours): a screen without
>    states[] had no place for a palette, so it fell back to `render.
>    palette`. Schema: **`screens[k].palette`** — resolution is now
>    `states[n].palette › screens[k].palette › render.palette › vanilla`
>    (compiler `state_palette_ref`, renderer `state_palette_id`,
>    `Document.effective_palette`). Add-screen copies the palette the author
>    is looking at into the new screen. Example-project bytes unchanged
>    (pin `fc1caa98…` holds); a fresh-project build proves the row lands in
>    `ScrAttr_6C_1` (test_canvas --rom).
> 6. **Per-screen/state palette selector** ("palette here" combo in Screen
>    & state) and **"copy from vanilla $xx <room>"** entries in BOTH palette
>    combos: copies that room's derived palette into `custom.palettes`
>    (`Document.add_palette_from_words`, id `pal_from_<mid>`) as an editable
>    item — the user's "use a pre-existing room's palette".
> 7. **Exits from custom rooms (staircases / doors), minimal:** Select a
>    cell → Selection panel "Add exit at this cell…" → `ExitDialog`
>    (destination custom or vanilla room → screen → arrival cell, preview,
>    wall warning; edge cells explained as push exits) → an ordinary
>    `exits[]` row on the current state (`Document.add_exit`); select an
>    exit marker → "Delete this exit". PyBoy: a GUI-authored (5,5) exit in
>    the servant clone walks the player into the Farm clone at the authored
>    cell. This is the custom-room half of routing; the full routing view
>    (both ends of a door as one object, return doors, world graph) stays
>    P3.7.
> 8. Borrowed tiles moved to their own **"Borrow" tab** beside "This room"
>    (two pickers; the foreign one shows only the chosen room).
> **NEXT (user direction, end of S95): ROADMAP P3.3c — tileset slot map +
> "release unused vocabulary"** (the 128-tile budget is hard and per ROOM;
> the protected source vocabulary is the biggest occupant; an "0 free"
> report on a small room would be a bug — a fresh Servant clone shows 51
> free after one import).
> Answers in prose: screens scroll automatically when adjacent (record dims
> auto-synced) — no exit needed; a building interior should be a SEPARATE
> room (own tileset/palette/states, no 4×4 budget — what vanilla does),
> sub-screens are for outdoor continuity.
>
> Owning: EDITOR_DESIGN §5.1 as built S95; PROJECT_COMPILER §2.11 (import
> + migration + screens[k].palette + GUI exits) + §11; TOOLS_AND_DATA S95;
> KEY_LESSONS S95; ROADMAP P3.3b residual + **P3.3c (next)** + P3.5a + P3.7.)

> Last verified: 2026-09-20 (Session 94 — **ROOM CANVAS v2 + the room
> model done right, then (same session, "S94b") ENTRANCE REDIRECTS + true
> per-STATE rooms** (user direction: "don't build the editor around POC
> trash; vanilla vs custom columns; the player walks in 4-subtile cells;
> Select is the basic tool; walkability mode; why 4×2?"; then "next logical
> step = functional gate redirects so you can test a room by hooking into
> an existing entrance", and "some rooms have multiple versions — servant
> boss room on fire or clear — the editor must display that"). Verifier
> PASS 6/6; clean `1ca6579…` unchanged; **patched reference pin MOVED to
> `fc1caa98…`** (S94 interim pin `cdadf834…` superseded in-session; engine
> + compiler changes below; hand-staged patches/ == compiler build,
> `--apply`'d, verify_integrity's own patched build == the pin);
> test_compiler --rom 61/61; test_app --rom PASS; test_canvas --rom PASS
> (v1 + v2 acceptance incl. the redirect walk-through). NOT yet
> user-tested. Test ROM: `DWM-S94b-test.gbc` (example content, patched
> `fc1caa98…`). Earlier S94 ROMs (`DWM-S94-test.gbc` `b3277cda…`,
> `DWM-S94-fresh-farm.gbc` `033d1b35…`, patched) are superseded.
>
> **Engine + compiler (patches/, deliberate, byte-changing):**
> - **Per-(screen, STATE) attr + palette tables in the VANILLA format
>   (S94b).** Vanilla varies attr AND palette per step (Servant room `$3F`:
>   221 attr cells + a different palette between its two steps). Bank $17
>   now emits `CustomAttrPtrTable` (dw per custom room) → `RoomAttr_<mid>`
>   (16 dw, one per screen) → `ScrAttr_<mid>_<k>` = `dw <step counter>` +
>   per state `db attr_entry, attr_bank / dw pal_ptr` — the same walk the
>   vanilla `AttrPtrTable` code does, so `CustomAttrCheck` just substitutes
>   the table base and `CustomPalCheck` keeps slot 7 (PROJECT_COMPILER
>   §2.11). Resolution: `states[n].attr › state layout item attr ›
>   screens[k].attr › screen layout item attr › render.attr`; palette
>   `states[n].palette › render.palette › vanilla source`. Supersedes the
>   S94 interim 17-byte per-screen map. PyBoy: a fresh-project Servant-room
>   clone renders both states pixel-identical to vanilla (only sprites
>   differ); example-project screens A/B pixel-identical 12/12.
> - **Entrance redirects (S94b, the user's "fastest way to test").**
>   `custom.entrance_redirects[]` = `{mapID, screen, x, y, dest,
>   screen_byte, spawn_x, spawn_y}` re-points ONE vanilla door. Lowered
>   (project.py `_lower_entrance_redirects`) to a `vanilla_exit_extensions`
>   entry keyed by **(mapID, screen)** whose per-step lists are rebuilt
>   from `extracted/map_table.json` (new PIL-free `editor2/core/vanilla.py`
>   valid-step reader shared with the renderer) with only the named row
>   substituted — the other doors keep their vanilla rows in EVERY state
>   (the S92 wholesale-replacement trap is closed). `VanillaExitExtTable`
>   rows are now `db mapID, screen` (`$FF` = any screen; S70 semantics);
>   template `VanillaExitResolve` compares `wScreenIndex` (head 358 → 383
>   B, re-pinned). **bank $0B `RoomEntry9` (boundary push exits) is
>   diverted through bank $60 entry 7 too** (same-size rewrite, 5 nops), so
>   y=0/7 extension rows are LIVE. **`Exit_GreatTree_s8` is restored to
>   VANILLA bytes**: the S92 Library-door POC repoint (`$72`) and the
>   S1-era `(4,5)→$6B` entrance are now example-project DATA
>   (`entrance_redirects`). Validator: one override per (room, screen),
>   'any' rows may not shadow per-screen rows, screen must exist, dest
>   room must exist, screen_byte never guessed. PyBoy: Library door → `$72`
>   scr 1 (14,7); `(4,5)` → `$6B` (7,6); untouched GreatTree screen-12 door
>   → `$0D`; MedalMan south edge (ext row via Entry 9) and OldManGate south
>   edge (vanilla fallback) identical to the original ROM; fresh project:
>   Farm clone + Library-door redirect walked through, neighbouring door
>   still → `$18`.
> - **ROM0 `$26DD` rows `$6B-$6F` are compiler-owned** (`@BUILD_PROJECT
>   rom0_room_records` in patches/bank_000.asm, emitter `rom0_records`,
>   jump-target labels kept at their addresses) — `record` is now REQUIRED
>   for every room; the legacy "$6B-$6F are hand-patched" special case is
>   gone (GATE_GENERATION §7).
> - **4×4 screen grid schema** (keys 0-15, sub-table width per row, dims
>   validated ≤4×4); **empty projects compile** (placeholder $6B synthesized).
> - MEASURED (PyBoy, 16/16): **collision samples the BOTTOM-RIGHT subtile
>   of the target cell** from every approach direction
>   (ROOM_DATA_FORMAT "Walkability: the bottom-right subtile decides").
>
> **Editor (editor2/, canvas v2 — EDITOR_DESIGN §5.1 "As built S94"):**
> vanilla column (98 rooms / 211 screens live, read-only, **every valid
> vanilla step browsable as "vanilla state i of n"**) + custom column
> (New / Copy / Rename / Delete) + **Make editable = clone with confirm**
> (clone is paintable at once; **clones carry ALL valid vanilla steps as
> `states[]`** with per-state layout/attr/palette items and the vanilla
> counter rewired to `wCustomStep_<rid>_S<k>` in the cloned scripts); File
> → New project from `editor2/templates/blank-project`; **metatile** = 4
> subtiles + palette slot as the unit (picker: found-in-room + my
> metatiles; metatile editor = the only subtile surface;
> `custom._editor.metatiles`); **Select is the default tool** with a real
> selection outline; paint/rect/fill/eyedrop on cells; **Walkability mode
> (W)**: red/green cells, click flips one cell by swapping its BR subtile
> for a cross-threshold twin (`Document.ensure_twin`; vanilla tileset
> copied into the project first as `assets/<id>.2bpp`; animated indices
> 77/78 skipped; wall-side-full fallback moves the threshold by one and
> remaps); 4×4 mini-map; fixed inspector width; `name` field. **S94b:
> inspector "Entrances" group + "Route a vanilla door here…" dialog
> (`rooms/redirect_dialog.py`: room → screen → door with previews,
> arrival screen + cell with a wall warning) and, from the vanilla view,
> select an exit marker → "Route this door into a custom room…"; markers:
> magenta `R` = redirected vanilla door, green `IN` = arrival cell.**
> User-reported fixes: palette double-click on a borrowed palette now
> OFFERS to copy the palette into the project (or clone the vanilla room)
> and opens the picker; the maximised window no longer slides off-screen
> (the status/banner labels asked for the width of their hover text —
> now `QSizePolicy.Ignored`; tab minimum 1106 px); NPC thumbnails knock
> out the throne-room floor (border flood-fill over the per-pixel mode of
> the 137 S91 crops — bosses remain 16×16 composite FRAGMENTS, one crop per
> NPC entry, ROOM_DATA_FORMAT S91). Structural edits = `SnapshotCommand`
> (whole-doc + asset-file snapshots; exact undo — a captured ordering bug
> fixed in-session, KEY_LESSONS S94).
>
> **Acceptance (test_canvas.py --rom):** fresh project → Farm cloned to
> `$6B` (renders pixel-identical to vanilla on all 6 screens) → water
> metatiles painted → grass cell (5,3) walled, fence cell (3,4) opened →
> Library door routed to the clone (dialog defaults + `add_redirect`) →
> exact undo/redo incl. the asset → build → PyBoy: screen-4 VRAM ==
> canvas 320/320 (scroll-aware read), the player is BLOCKED by the new
> wall, WALKS THROUGH the opened fence, and **walks through the GreatTree
> Library door into the clone at the authored cell** while the door beside
> it still leads to `$18`; plus the S93 vault-states check. Residuals:
> ROADMAP P3.3b. Owning: EDITOR_DESIGN §5.1 as built S94; PROJECT_COMPILER
> §2.11 + §2.12 + §11; ROOM_DATA_FORMAT (walkability, states);
> GATE_GENERATION §7; TOOLS_AND_DATA S94; KEY_LESSONS S94; ROADMAP P3.3b.)

> Last verified: 2026-09-19 (Session 93 — **P3.3 ROOM CANVAS v1 + the
> editor SHELL — the first session where the editor is built as a product,
> not a backend with a viewer bolted on** (user direction S93: "when is the
> actual EDITOR getting built?"). Byte-neutral for the repo (no patches, no
> disassembly, example project untouched — GUI build still == pin
> `df321962…`); verifier PASS 6/6; test_compiler 46/46; test_app --rom
> PASS; NEW `editor2/tests/test_canvas.py --rom` PASS = the ROADMAP P3.3
> acceptance. NOT yet user-tested (test ROM
> `DWM-S93-canvas-2state-test.gbc`, patched md5 `fd5de1b5…`, delivered).
>
> **As built (owning: EDITOR_DESIGN §5.1 "as built S93"; files in
> PROJECT_COMPILER §11):**
> - `editor2/core/render_project.py` — LIVE renderer straight from
>   project.json + original ROM (custom layouts/tilesets/palettes, vanilla
>   bank refs, derived palettes, the (then) base/base+2 attr stride, forced
>   idx1/idx3). **Validated pixel-identical to the ROM-built renderer on
>   all 12 example-project screens** (Tier-1 rule, EDITOR_DESIGN §7). ~1 ms
>   per screen ('P'-mode compose), so paint previews without a build.
> - `editor2/core/document.py` — the editable model: load/save that
>   reproduces project.json BYTE-FOR-BYTE (indent detection + trailing
>   newline; verified on the committed example), tile/attr cell edits,
>   states (ensure/collapse/add/remove — the schema's states[]
>   conversion is automatic), layout localization (vanilla {bank,entry} →
>   editable custom.layouts item), add/remove screen with record
>   width/height auto-synced (KL S10), 8-NPC capacity readout. New layout
>   items ALWAYS append — inserting mid-list would shift later bank-$64
>   entries and (until S94) broke other rooms' base+2 attr stride.
> - `editor2/app/` — Session (doc + renderer + QUndoStack + signals);
>   shell = §5.0 tab strip (Rooms live; Gates/Monsters/…/Balance stubs
>   naming their P3 box; Build & Play), Save ⌘S, Undo/Redo, Build ⌘B
>   (saves first), Play ⌘R, Validate (compile-only), History dock.
> - **Rooms tab** (`editor2/app/rooms/`): room browser (screen/state
>   counts) + 4×2 mini-map with live thumbnails (click = page, + = add
>   screen, right-click = remove) | tool bar (pencil/rect/fill/eyedrop/
>   select, brush = tile or palette slot, layer toggles grid/palettes/
>   walkability/markers, zoom 1-6×) + state bar (◀ ▶, add: duplicate /
>   duplicate-with-OWN-layout / empty; remove; NPC n/8 meter) + banner
>   (read-only vanilla ref → "Make editable"; shared-layout warning;
>   attr-stride WARNING) + canvas (one screen native, pixel-exact,
>   sprite crops from the S91 catalog on NPC markers, spawn/exit/walk-on
>   markers, hover readout incl. marker names) | 128-tile picker in the
>   room's real palette with the collision threshold drawn as the wall
>   boundary + palette panel (8 rows, idx1/idx3 locked, dbl-click edits
>   project palettes) + inspector (Room: tileset/size/threshold spin/
>   palette combo/attr base/encounters/music; Screen & state: layout ref,
>   attr grid in effect with stride note, step counter, states, NPC
>   slots; Selection: clicked marker fields read-only; Layout: users).
>   Keys: B R F I V, right-click eyedrop, ⌘/Ctrl+wheel zoom, space-drag
>   pan, G grid, , . / PgUp PgDn state, 0-7 screen.
> - ENGINE FACT the UI surfaces (KEY_LESSONS S93): attr/palette-slot grids
>   are per SCREEN (CustomAttrCheck: mapID + screen), NOT
>   per state — painting palette slots in one state changes every state
>   of that screen; only the tile layout is per state.
>
> **Acceptance (test_canvas.py --rom, on a scratch COPY of the example
> project):** pencil/attr/rect strokes + a second state with its own
> layout copy painted differently + a screen added, all through the real
> GUI code path; exact undo (full undo → project.json byte-identical to
> disk); save; compiler accepts; build; PyBoy warp into $71 with the step
> counter at 0 and at 1: **VRAM tilemap == canvas grid 320/320 tiles in
> both states** (chained warps repeat-stable). Same check re-run on the
> user's .sav for the delivered ROM. Owning: EDITOR_DESIGN §5.1/§9 (G-G
> CLOSED), PROJECT_COMPILER §11 + §2.10 note, TOOLS_AND_DATA S93 rows,
> KEY_LESSONS S93, ROADMAP P3.3 (+ residuals).)


> Last verified: 2026-09-19 (Session 92 — **P3.2 [G-A] + P3.2b [G-J] +
> states[] backend [G-G half] (user-directed pairing).** Banks $64/$67
> are compiler emitters: `custom.layouts[]` (16×20 tile+attr grids,
> tile_layout_compiler path, declaration-order tiles/attr interleave
> matching CustomAttrCheck's base/base+2 stride) + `custom.tilesets[]`
> (multi-tileset editor-export `spec` form = the S6-S10 import pipeline,
> or committed `raw2bpp` sheets; the orphaned S6 combined sheet carried
> forward byte-identically — compress_lz roundtrip proven). Fold is
> ZERO-DELTA (verified vs pin a17bff8e… before clone content).
> `screens[].states[]` first-class: N step entries per screen, engine
> already counter×6 (NO template re-pin), byte-identical when absent,
> per-state validation (8-NPC HARD cap = error). `custom.script_preludes`
> {script_id: ops} prepended post-lowering (generated entry:/quest: ids
> valid targets). Placeholder rooms ≥$70 emit zero 26DD rows.
>
> **P3.2b:** `tools/extract_room.py` — vanilla→custom clone with a
> segmentation-PROOF decoder (every branch target must land on an op
> boundary; merged param table = decompiler overridden by verified rows).
> MEASURED corrections: **$27 MonsterPartyOp2 = 0 params, NOT a branch**
> (PyBoy ctr trace 2F→30 linear; scriptgen's (0x27,1) row was WRONG —
> corrected, old name aliased; DOC_AUDIT S92), **$21 = 1 param**, and
> **bare non-$FFxx words are text displays** (the compiler's ["text",id]
> naked-dw form). Arena Lobby ($06: 3 horizontal screens ONE step each —
> the "9-step lobby" in the S92 audit was Castle) cloned to $72:
> record/layout-refs (vanilla bank $29 entries)/attr (re-emitted $64)/
> palette (derive_room_palette)/12 scripts (780+ ops, scr10→scr11
> fall-through duplicated)/BGM $1E; raw 5-byte interact pass-through for
> $8F-param/$90/$82 entry classes. island_copy $73 = custom→custom.
> PyBoy-VERIFIED on the user's .sav: clone renders pixel-identical to
> vanilla (byte-identical PNGs, walk + 3-screen horizontal scroll);
> **full path walk: medal_vault (entry cutscene→around MedalMan→
> authored staircase metatile (8,3))→clone lands (14,7) screen 1**; rank
> mechanic live: D9CE=3 → vault prelude arms wCustomStep_ArenaClone_S1=1
> → clone loads state V1 (NPC buffer holds the $3A swap — the two rank
> screenshots are pixel-same only because both sprites draw alike here;
> buffer diff is the proof). KEY MECHANIC (measured): state selection
> reads the counter at destination LOAD, BEFORE its entry script — the
> hub arms the destination (hence script_preludes); counters SURVIVE room
> transitions (zeroed at save-restore only). Arena literal-mapID audit:
> exactly 2 sites — bank $01 cp MAP_BATTLE1 ("arena entrance"
> special-case; clone gets default behavior) + bank $07 cp $06 &&
> screen 0 (trophy-room party-display setup; silent no-op in the clone).
> Pin (patched reference build): df3219623203cf5bc272cb6155f07a01
> S92v5 — USER-TESTED: entrance repoint works ('teleports to arena');
> all 3 clone screens accessible (normal save); the postgame
> right-screen crash was the USER'S SAVESTATE, not the ROM; rank state
> (flag $0030, visible-by-removal: the (7,6) $12 attendant leaves at
> G+) user-confirmed vanishing. $54's empty render is VANILLA-FAITHFUL
> (user: real lobby = 2 bunnies + 2 desks; the $54 entry is the desk
> talk-point). Remaining NOT-user-verified: NPC dialogue/script parity
> across all clone content, north-door round trips, island_copy. Old
> v4 pin was
> S92v4: rank trigger = event flag $0030 (the v3 $D9CE key was the
> transient coliseum var — user-caught). Seam-cross re-read applies a
> newly-armed state mid-visit (measured); postgame right-screen crash
> NOT reproduced headless (three isolated probes clean) — awaiting user
> SameBoy data. Old v3 pin was
> S92v3 ENTRANCE (user-directed, supersedes v2 — the gate room sits
> behind the 100-monster gate): the GreatTree→Library door is REPOINTED
> to the clone (in-place same-size bytes, patches/bank_00b.asm $0B:$4FE6,
> restore note at the site; S70v2 precedent). No injected triggers; both
> ext rows removed. PyBoy: real transitions both ways. The Library is
> unreachable while the repoint stands (testing stance). Old v2 pin was
> (46/46 tests; supersedes interim S92 pins 9e5b592f/c3513d85, both
> patched builds). S92v2 ENTRANCE (user-directed): Library Gate Room
> ($13) door at (8,6) — bottom-right corner, mirror position of the
> vanilla gate — via a vanilla_exit_extensions row (single sub-room, so
> no cross-screen replacement hazard; Library $12 itself is 2 screens
> sharing ONE wholesale-replacement list and was rejected — any tile
> choice cross-fires on the other floor). Vanilla gate + return door
> rows mirrored verbatim; return door PyBoy-regressed; corner door
> PyBoy-verified end-to-end (lands clone (14,7) screen 1). The vault
> staircase route remains but is NOT the advertised entrance. Also fixed at
> HEAD: test_compiler crash-config ran unconditionally (fresh-machine
> fail without --rom) — now guarded. Built S92, NOT yet user-tested.
> Owning: PROJECT_COMPILER (schema §), TOOLS_AND_DATA (extract_room row),
> KEY_LESSONS S92, DOC_AUDIT S92, ROADMAP P3.2/P3.2b/P3.3 note.)


> Last verified: 2026-09-18 (Session 91 — **P3.0 CAPACITIES + P3.1 NPC
> SPRITE CATALOG (both boxes, user-directed pairing).** Byte-neutral
> (tools + extracted + docs + one comment fix in bank_004; byte-perfect
> rebuild verified); verifier PASS 6/6; clean `1ca6579…` unchanged. NOT
> yet user-tested (the sprite sheet WAS user-classified in-session).
>
> **P3.1 (G-B CLOSED):** every candidate sprite id ($00-$7F, $E0-$E3,
> $F0-$F3, $FF) solo-rendered in PyBoy (binary-poked temp ROM, Castle
> throne-room block, real-.sav savestate) → `npc_sprite_catalog.json` +
> labeled sheet + 137 crops (`npc_field_sprites/`), generator
> `dump_npc_sprite_catalog.py` (`--render/--finalize/--census`). ZERO
> ids crash — the S70 "$11 hard-crashes" was custom-room context; $23
> ("draconic") = a boss_composite_fragment (bosses are multi-tile
> composites of several NPC entries — user). Categories (user, S91): 72
> normal / 17 boss fragments / 6 aliases of $00 ($4E,$4F,$F0-$F3,
> pixel-identical, deterministic under VRAM priming) / 37 empty / 5
> glitch. Names+classes live ONLY in npc_names.json (hand-curated) and
> merge at --finalize. Guardian cosmetic: no GoldSlime icon exists;
> closest = blue slime $3A; project.json left untouched (byte-neutral)
> — swap next project-touching session.
>
> **P3.0 (G-M core CLOSED):** `extracted/capacities.json` (ceiling +
> evidence + measured/documented status per entry). MEASURED: NPCs per
> screen-state = **8 HARD** ($0B:$470F fills exactly $101 B at $D7D2;
> vanilla valid-step census max = exactly 8; a 9th entry silently
> corrupts $D8D9 + $D8E2-$D8E8 script state vs an 8-NPC control — no
> crash) — and a SECOND ceiling: the per-screen **distinct-sprite-sheet
> VRAM budget** (order-filled at init; 8 light sheets fit, ~2-3 heavy
> exhaust; overflow renders blank). Screens/room: engine 16 (4×4
> scroll clamp), vanilla max 12-declared/9-valid (mt $54-$59),
> screen_idx 8 PyBoy-verified; custom schema currently 4×2=8.
> Residuals in `_deferred_measurement_boxes` (E6 text budget, gate
> slots, per-sheet tile counts, 4×4 schema).
>
> Also: `npc_catalog.json` is CONTAMINATED by phantom-step rows (its
> dumper walks past each screen's real step list; engine validation
> only checks bank ∈ (0,$80)) — filter rules in the new tool's
> --census; dumper regen = residual. bank_004 "40 NPCs" banner comment
> fixed (both copies, byte-perfect). Owning: ROOM_DATA_FORMAT "NPC
> capacity & sprite-sheet budget (S91)"; capacities.json;
> TOOLS_AND_DATA S91 rows; EDITOR_DESIGN gap register G-B/G-M;
> DOC_AUDIT S91; KEY_LESSONS S91; ROADMAP P3.0/P3.1.)

> Last verified: 2026-09-18 (Session 90 — **EDITOR_DESIGN v2: the
> UI/use-perspective revision + Phase 3 re-sequencing (user-directed).**
> Byte-neutral (docs only); verifier PASS 6/6; clean `1ca6579…` unchanged.
> NOT yet user-tested (doc review = the acceptance).
>
> Strategic adjudications made this session (user conferred first):
> - **Simulator arc = DONE for purpose.** Full suite green (S89 rows);
>   the four residuals are BANKED, non-blocking boxes ($DB42 bit6 setter,
>   +8/+9 defensive-flag consumers, meta-actions real-menu drive — needs
>   a CLEAN-build save or franken-state, the hacked .sav is rejected by
>   the clean build — and the guard-validator main-runner polish).
> - **Next major arc = Phase 3, the editor**, entered through a design
>   revision rather than blind UI building.
>
> EDITOR_DESIGN rewritten as **v2** (owning doc; § refs below are its):
> full tabbed UI spec (§5) — Rooms (one-screen canvas w/ explicit screen
> boundaries + mini-map, room-STATE switcher over the step-counter
> system, tileset/palette [pick-or-upload w/ forced idx1/idx3 shown],
> NPCs, dialogue WYSIWYG, triggers, cutscene storyboard + PyBoy
> playback, per-room encounters + music), Monsters (stats/AI-weights w/
> sim-backed preview/learnset/battle+follower sprites over GFX-1..4),
> Skills (S74 knob surface as forms), Breeding (edit + the randomizer's
> tree/depth/reachability analytics live), Encounters, Music (library +
> MIDI import + audition), Progression & Flags, World graph, **Balance
> (the S78-S89 simulator as a product feature: TTK sweeps, what-if
> deltas, obedience curves; unvalidated = greyed)**, Build & Play.
> Decisions: **Layer A-lite** (§6 — vanilla DATA-TABLE editing via
> same-size compiler emitters + randomizer/romdata.py readers, ahead of
> full extraction; unedited gamedata ⇒ zero byte diffs is the
> regression); backend **gap register** (§9, G-A..G-I); milestones
> re-cut, M2 bifurcation re-slotted as M2R INSIDE the editor (World
> tab, dogfooding Layer A). Stale v1 §7 (sprite sketch) + §8 (bank
> table) retired with a ledger (§11; DOC_AUDIT S90 addendum).
> ROADMAP Phase 3 replaced with one-session boxes **P3.1-P3.17**, each
> with an acceptance test; recommended entry point = P3.1 (NPC sprite
> catalog) or P3.2 (the $64/$67 project.json fold, the canvas
> prerequisite). Owning: EDITOR_DESIGN v2; ROADMAP Phase 3 + S90;
> DOC_AUDIT S90; this file (status row below).
>
> **v2.1 (same session — user workflow decisions):** FORK-DON'T-FIDDLE
> (clone-to-custom + repoint is the default; in-place vanilla edits only
> under capacity pressure — Layer A proper shrinks to exit repoints +
> M2R) + CANVAS-FIRST (click-to-edit everything where you see it).
> Added: P3.0 CAPACITIES reference + meters, P3.2b clone extractor
> (arena first, per-island literal-mapID audit), P3.7b Gates tab,
> Triggers-as-sentences (+G-O flag-keyed pool variants), P3.10b Arena
> editor + P3.13c Shops (E8) promoted from Phase E, P3.11b AI ban-list
> (optional), family-icon editor + follower visualizer + the sprite
> background white-vs-cream DEFECT (Open defects). Headroom audit: 11
> free banks/176 KB + ~128 mapIDs + 24 KB SRAM (S69) + 32 species slots
> = fork-first affordable at campaign scope; ROM 2→4 MB assessed +
> banked as contingency (grep-verified: NO prior session claimed ROM
> expansion — the expanded thing was SRAM).


> Last verified: 2026-09-17 (Session 89 — **SIMULATOR WRAP-UP PART 2:
> Group B residuals closed.** Byte-neutral (Python + docs + disassembly
> annotation only); verifier PASS 6/6; clean `1ca6579…` and patched
> `a17bff8e…` verified. NOT yet user-tested.
>
> Four residuals CLOSED by measurement on the user's real .sav (Slib L1,
> WLD 5, skills $E9/$E5/$E4):
> - **$DB07 bits7:6 "stun" writer = the IRONIZE counter** (Ironize $2A /
>   IRONIZE $DC; `SkillIronize` walks the whole side on a party cast).
>   Sets $C0, phase-9 ticks $C0→$80→$40→$00, forces action $11, and
>   makes the monster immune to all incoming resolution (physical+magic,
>   measured under Attack+Blaze) via the flags8-bit2 $56E1 gate (= the
>   S85 `target_unreachable`, semantics now named). WarCry-family
>   EXONERATED (they write +5 one-shots).
> - **"Interception redirects" = the Cover $88 / Guardian $89 guard
>   system.** One-round mark at $DB08+8t bit4 (protected) / $DB09+8t
>   hi-nibble (protector), read one slot shifted; consumers at
>   $53:~$552x/$567x (flags8 bit1) rewrite target + queue to the
>   protector. Model `battle.guard_redirect`, corpus
>   `s89_guard_events.json`, validated **14/14** incl. dead-protector
>   fall-through. New `guard_redir` waypoint ($53:$5544) in
>   measure_battle.py.
> - **WLD level-up writer = NONE.** Measured L1→L13 in one post-battle
>   scan, record +$60 unchanged; static writer set closed (creation /
>   breeding-zero / field items).
> - **Corpus fields:** `board_from_event` now consumes per-event
>   `ai_bases` ($DC44..$DC63) + `wld` ($DC23 words); the
>   PARTY_FALLBACK_BASES/default_wld stand-ins retire on S88+ corpora.
>   Defensive-set sweep folded into status.py (+0/+1 flags: Imitate
>   $7F/Dodge $8C/SuckAll $8F/Defence-class $8D/$8E/$90).
>
> Meta-actions = **PARTIAL** (named ROADMAP box, NOT guessed): the $E9
> flee class is the HERO slot's MENU verb space (option-list obs), not
> an enemy-AI outcome — queue-forcing never reaches it (readiness gate),
> an empty-list enemy emits none, an outleveled wild never fled. NEXT =
> drive the real menu on the CLEAN ROM (the hacked .sav is rejected by
> the clean build — S75 build-specificity — so franken-state there).
>
> The LOW-STAT CALCDEF EDGE is **SOLVED S89 (PyBoy)** — and it was never
> a calcdef bug. Hooking all 75 `ld [$db56],a` sites caught the writer:
> `$53:$59CD` applies an unmodelled **×1.5 damage boost gated on the
> ATTACKER's `$DB42` bit 6** (`dmg + (dmg>>1)`, half truncated, 16-bit
> srl/rr/add), running AFTER CalcSkillDefense and AFTER the slot-2/zero
> -floor adjust and stacking on them. Correlation 8/8 across a battle.
> This closed BOTH long-standing repros: s89_fresh **426/1 → 426/0** and
> the S88 rider anomaly **3422/1 → 3422/0**. Model: `battle.db42_boost()`
> in the physical AND record damage paths; `Board` carries `db42`.
> ALSO completed: full per-victim guard integration — marks written when
> Cover/Guardian resolve, cleared per round, side sweeps start at the
> QUEUED target and walk forward, each victim redirecting independently
> without dedupe (s89_guard 20 → 1 mismatch).
> **Full suite green**: battle 6614/0, 802/0, 2824/0, 3083/0, 3422/0,
> 426/0, guard 826/1; damage all 13 categories 0; obedience 889/0; rules
> 240/240; order 143/0; ai 26/26; pacing level-1 UNIFORM KS 0.042;
> verifier PASS 6/6.
> Open items (NON-user, none blocking): the `$DB42` bit6 SETTER (observed
> set in phase 5, cleared in phase 9; not a plain set/or/ld form in banks
> $50-$5F), one s89_guard waypoint-grouping edge, the +8/+9 defensive-flag
> CONSUMERS, and meta-actions (PARTIAL).
>
> Annotation (byte-neutral, MD5 re-verified): $670E dispatcher
> re-sectioned (7-state rst table, `InterceptGate_6720`); GuardMark
> writer, $4BD3 checker, `SkillIronize`/`SkillCover`/`SkillDodge`/
> `SkillBladeD_Defense` comments; `SacrificeEntry_670e` attribution
> corrected (DOC_AUDIT S89). Full validator suite green on the final
> layout: battle 6614/0 + 802/0 + 2824/0 + 3083/0 + 3422/1(known) +
> s89 426/1(flagged) + guard 14/14; obedience 889/0; rules 240/240;
> order 143/0; ai 26/26; damage all-exact; pacing level-1 UNIFORM
> KS 0.042. Owning: BATTLE_SKILL_SYSTEM §15.6/§15.9; status.py; battle.py
> `guard_redirect`/`target_unreachable`; MONSTER_DATA "Party Monster
> Structure"; known_RAM_map [S89]; TOOLS_AND_DATA S89 rows; ROADMAP S89;
> DOC_AUDIT S89.)


> Last verified: 2026-09-15 (Session 87 — **COMMIT-MODEL CLOSE-OUT:
> party category bases + obedience gate EXACT; the WLD identity.**
> Byte-neutral (Python + docs + annotations); verifier PASS 6/6; clean
> `1ca6579…` and patched `a17bff8e…` both verified after every batch.
>
> PARTY category bases DECODED+MEASURED: bank $51 `LoadBtlS_44cb` fills
> $DC44/$DC54/$DC5C/$DC4C from the party monster's OWN instance record
> +$5B..$5E (hook-verified on the user's hacked .sav: Slib 80/186/189/85
> landed exactly; swap-in re-sync $53:$6236 = 3rd confirmation). Source =
> enemy-stats ai_weights through the one-time CREATION ROLL (bank $14
> `SaveEnem_47fd`/`_4821`: ($CD + RNG mod $34)/256; $100-overflow =
> exactly 1.0×; Div8x8 convention pinned B=B//A, rem in A) — Slib's
> tuple is a legit roll of EID 1's [100,200,100,200]. No mid-battle
> drift (writers: creation, breeding, field item adjusters).
>
> OBEDIENCE gate EXACT, **889/889** (measure_obedience.py, 127
> decisions → validate_obedience.py): band table {5,7,9,11,13,15}, the
> RNG&$3F mod-b with nonzero-multiples→b quirk (LCG-step replayed),
> the COMPLETED inequality — carry iff WLD/4 + bandedRNG >
> tacticSeed/10 + w3/10 + $db53 (S84's note dropped the last two
> terms). $7997 consumption point CLOSED ($db53 IS a decide addend);
> table re-sectioned (`ObedienceThreshTable_7997`, byte-identical).
> TRUE loaf RUNTIME-SIGHTED: plan-$81 Command carry-divert; all three
> codes $98/$3A/$8D live; `SetBtlAI_7f5f` exact (cat1-dominance).
>
> **wBattleLVL = the WLD (wildness) stat, NOT the level** — INFO-screen
> verified ("WLD: 5" for the L1 Slib); record slot+$60; init =
> 5×level − 10×arenaTier($CAB4), clamp 0..255; breeding ZEROES it
> (bank $16 `label16_474a`); Add/SubMonsterWLD item adjusters. Display
> level = $db9b (slot+$4B). Instance-record map CORRECTED in
> MONSTER_DATA (old rows were missing the MaxHP/MaxMP words; the S36
> "±2 WLD-style" prose was the LEVEL-CAP roll, slot+$4C). Mislabels
> fixed both trees: SetMonsterSkill*/ClearMonsterSkill* →
> Add/SubMonsterAIWeightCat1/3/2; ClearMonsterAGL → SubMonsterWLD.
>
> pacing.py upgraded (exact obedience on WLD; real bases via
> `ai_weights`/`party_bases_from_row`/`default_wld`; tactic-3
> always-Attack shortcut corrected — Command w/o menu is
> obedience-gated). Regression: 6614/0 + 802/0, rules 240/240, ai
> 26/26, idle CHECK OK, level-1 PIT unchanged (KS 0.039), level-2
> 72/44/89/77/46 winners consistent (S86's 75/46/85/82/48 =
> `--pskills 0xe9,0xe5`, invocation now recorded + `--pbases` added),
> profile_check --ttk PASS 1.00×. Owning: BATTLE_SKILL_SYSTEM
> §15.10.1/.7a + §15.9 + §15.8c; MONSTER_DATA "Party Monster
> Structure"; known_RAM_map [S87]; TOOLS_AND_DATA §2.10 + S88 rows;
> ROADMAP S88; KEY_LESSONS S87; DOC_AUDIT S88; BATTLE_SKILL_SYSTEM
> §15.8c/§15.9 [S88].)


> Last verified: 2026-09-15 (Session 86 — **PACING LAYER DONE: the S80
> RNG-policy question ANSWERED BY MEASUREMENT, full-battle TTK driver
> built, aggregate-validated at round AND battle level, wired into
> `randomizer/profile_check --ttk`.** Byte-neutral (Python + docs only);
> verifier PASS 6/6; clean `1ca6579…` unchanged.
>
> RNG idle model: the live RNG is a FULL-PERIOD 16-bit LCG, so the idle
> step count between any two captured states is uniquely recoverable
> offline — `simulator/measure_idle.py` recovered all 5,636 consecutive-
> waypoint counts in the S85 corpus → `s86_idle_model.json` (8 measured
> per-class pools). Structure: same-frame pairs move only the model's own
> deterministic k∈{0,1}; the gate/curse block and the whole MISS→core
> sequence are same-frame (NO idle); phase-9 consecutive DoT rolls carry
> an IDENTICAL state (222/222 at k=0 — the wait loop doesn't step there);
> idling lives at actor boundaries/animations (med ~10²–10⁴ steps).
> `battle.simulate_round` restructured to idle at exactly those sites
> (validate_battle regression intact 6614/6614) + the decoded §15.10.10
> front-weighted target pick replaces the "first live" stand-in.
> `simulator/pacing.py`: IdlePolicy (empirical/uniform, O(log k) affine
> stepping), commit machine (category machine + S81 chains for $dd0b 1/2,
> decoded lightweight picker for 0, tactics bias + obedience gate),
> `simulate_battle`, `ttk`. **Aggregate validation
> (`validate_pacing.py`): level 1 = PIT over 197 clean corpus rounds ×200
> sims — engine outcomes rank UNIFORM (KS 0.038 < 0.097 crit, coverage
> 87.8% in [5,95], KO sets always ≥5% model events) — and empirical vs
> uniform idle policies are statistically indistinguishable (ROADMAP's
> "both work" hypothesis is now a finding). Level 2 = 5 FRESH unforced
> real-save battles (S86 .sav, patched a17bff8e) — validate_battle on
> them: 802/802 on never-seen data; engine battle outcomes at sim
> percentiles 75/46/85/82/48, no tail outliers.** `sweep_ttk.py` sweeps
> gate pools per ROM (vanilla/romhack/randomized) with level-scaled
> reference parties, both party policies; `profile_check --ttk` gates
> pool-TTK ≤2× vanilla (identically-seeded → vanilla-vs-vanilla exactly
> 1.00×; default run unchanged). Commit-model stand-ins (party category
> bases, obedience mid-band, chain element→resist mapping) are ROADMAP
> S86 residuals. **USER-CONFIRMED S86: the S85b Anchor rewrite (patched
> ROM `a17bff8e…`) works — no orphan-line recurrence** (user-reported).
> Owning: BATTLE_SKILL_SYSTEM §15.8c (new) + §15.9; TOOLS_AND_DATA
> §2.10; KEY_LESSONS S86; ROADMAP S80/S86.)

> Last verified: 2026-09-05 (Session 85 — **LOOP-LEVEL DIFFERENTIAL VALIDATION
> OF THE ROUND CORE: DONE — `simulator/battle.py` 6614 comparisons / 0
> mismatches** over 25 complete engine battles (real-save unforced
> tactics-AI fights vs 1/2/3 enemies + forced status/coverage runs, both-
> side KOs, heals, curse, stun, MP-veto): `simulator/measure_battle.py`
> (31 waypoint hooks, full 8-slot board per event) → corpus
> `simulator/s85_battle_events.json` → `simulator/validate_battle.py` (37
> check kinds: order, gates, dup-conversion, veto, target, MISS/dodge,
> damage cores, HP/KO, victims, decay, DoT, status rolls…). The live RNG is
> idle-stepped between waypoints (`MainWaitLoop`; `BattleRNG` uses the
> $C1ED chain only in LINK), so validation is by injection — a seed-to-end
> replay is impossible by construction (KEY_LESSONS S85). Owning:
> BATTLE_SKILL_SYSTEM **§15.8b** (new) + §15.7/15.8/15.9 updates.
>
> CLOSED with it (byte-read + measured): the S84 "2nd group cast → Attack"
> rule = `EnemyDupCastConversion_4e63` — per-EID flag table
> `EnemyDupConvFlagTable_41df` (181/487 set; ex-"BattleHPLookupTable",
> misnamed) + 77-id list `GroupDupSkillList_4ee4` (re-sectioned to db,
> byte-identical, extracted by `tools/dump_dupconv_table.py` →
> `extracted/enemy_dupconv_flags.json`); the scan self-matches, so an
> enemy converts iff ANY enemy precedes it in the order ($DD0B!=2 keeps);
> **DoT cap was documented WRONG** (Div16x8To16 leaves the remainder in A
> → 10+RNG16%6 / 30+RNG16%11; status.py corrected; heavy 13/13); +2 bit1
> applier = PoisonAir $6D; curse self-hit = 4 RNG2 branches (turn lost /
> HP−MaxHP/6 / MP−MaxMP/6 / confusion), actor still acts after HP/MP;
> act-time re-resolve + MP/seal veto rules; status-spell ladders (all
> $6710); KO transient full-HP; flying Quake victims are visited, not
> damaged (§13.7 corrected); LoadBtlC_5857 = skill-$41 exemption; phase-9
> sub 0 = byte-exact status decay. Annotated in source (bank $050/$052/
> $053 comments + the 5 dup-conv labels; clean `1ca6579…` unchanged).
>
> **PATCH (item #4 test): two AI-commit bugs found on the real save and
> fixed** — AI-committed Tremor/Quake swept the PARTY (S84 stub row $6367
> = own-side base; vanilla $E5 slack row too) → $E5-$E8 now route to
> `Jump_058_62bf` (the vanilla group-attack service); AI-committed Anchor
> was a self-inflicted MegaMagic (CustomDispatch52's damage setup precedes
> the "no-op" ret). **USER-TESTED S85 (ROM `4c8de38a…`): AI-committed
> Tremor, Mourn, Infernos work**; the no-op Anchor turn showed an orphan
> "Has no effect on Slib!" line → **S85b: AI-committed $E4 is rewritten in
> the queue to $3A by DispatchBoundsStub** = vanilla behaviour (vanilla's
> AI commits StepGuard/MapMagic and they run as Attack — measured), PyBoy-
> verified 5/5 turns "Slib attacks!". **Patched test ROM md5
> `a17bff8e67f3043fbff653c65128ea16` (S85b), USER-CONFIRMED S86.** The
> player-menu path was never affected (why S74's test passed). editor2
> `test_compiler --rom` re-pinned to `a17bff8e…` (39/39; S84's move was
> never recorded there). Verifier PASS 6/6.)
>



> Last verified: 2026-09-03 (Session 84 — **S81-remainder measurements +
> CRASH FOUND AND FIXED in the S74/S75 custom-skill dispatch.**
> BtlSkillTargetDispatch_401d (230 rows, $00-$E5, abuts the $41E9
> service) has NO bounds check in BtlQueueFetchService_5498; AI-committed
> ids > $E5 far-jump through code bytes (E6→$5621, E7→$01DB, E8→$0008,
> E9→$CDAF = WRAM execution — reproduced live: tactics AI committing
> Mourn from the hacked save's starter). S74/S75 verification missed it
> because rigs FORCE queues, bypassing the commit-time dispatch.
> **Fix: DispatchBoundsStub** — same-size call-site replacement $54C2 →
> stub at $694F free space ($E6-$E8 → $6367 like E5's slack row; $E9 →
> $41E9 attack service; $EA+ → $6367). 40 changed bytes in bank $58 + 2
> header checksum bytes; byte-diff verified surgical. Emulator-verified
> (forced E9-only and E6-only movepools → clean AI commits, correct
> targets, full battles with damage). Patched test ROM (S84, "patched"
> md5 `b99455d67012e2f451cd5ed96a5020a1`) delivered. **USER-CONFIRMED
> S84: Mourn activates via tactics AI under Charge on the real save**
> (the pre-fix hard-freeze path). Quake ranks $E6-$E8: fix built +
> PyBoy-verified, NOT yet user-tested. Enemy-side uses the identical
> shared service (not reachable in normal play — no vanilla enemy
> movepool holds ids > $E5).
>
> S81-remainder decodes (measured + byte-verified; owning §15.9/15.10.7a-
> .10.10, KEY_LESSONS S84, known_RAM_map rows DD03/DD0B/DB50-53/DB61):
> commit-time target write site = entry 8 itself (frame-exact; the S83
> $50:$4C87 breadcrumb was the player Massacre path; $6379 side-blind BY
> DESIGN); $dd0b per-slot INT ladders both sides incl. the enemy lo-byte
> quirk (boundary-measured 20/21/65/185); the TACTICS mechanism ($DD03
> nibble = tactic 0-3, +20/+45 category bias via $6F8C, obedience level
> gate <21/≥$F0, score formula, $7997 4x27 table extracted); MISS/dodge
> act-time gate machine in bank $53 (Surround 62.5%, $db07&3 37.5%,
> Dodge-status 50%, AGI ladder 2/8/43 per 256; flags7/flags8 record bits;
> $52 twins DEAD CODE; $DA33 = presentation countdown only); plain-attack
> targeting $41E9/$441B full decode, rolls verified 4/4 (50/33/17
> front-weighted); lightweight picker full decode incl. self-healing
> empty-category cursor walk; 77a4 = "tactic==Cautious". Group-cast→$3A
> round-conversion rule observed, MP-gate hypothesis FALSIFIED, rule
> untraced. Loop-level battle.py validation still OPEN (ROADMAP).
> Verifier PASS 6/6; clean `1ca6579…` unchanged.)


> Last verified: 2026-08-14 (Session 81 — **combat-simulator arc part 4:
> the EVALUATOR RULE CHAINS, decoded end-to-end and differentially
> validated 240/240; target resolution ~2/3 traced.** Byte-neutral: no
> patches touched; verifier PASS 6/6; clean `1ca6579…` and S75v4 patched
> pin `ce1e7369…` both unchanged. Built S81, NOT yet user-tested. Model
> `simulator/ai_rules.py`; rigs `measure_rules.py` + `sweep_rules.py`;
> validator `validate_rules.py` + corpus `s81_sweep_corpus.json`; prose
> BATTLE_SKILL_SYSTEM §15.10.5 (rewritten) + §15.10.6 target note; RAM
> rows $DD1B/$DB8B in known_RAM_map [S81].)
>
> Chain architecture (falsifies S80's "indexed by effect_class"): $4302
> → per-CATEGORY $0000-terminated dw chains $4308/$4358/$4404 (39/**85**/40
> rules — this block originally said 61 for cat2, a miscount corrected
> S82 (byte-verified; DOC_AUDIT S82) — 131 unique); the whole chain runs
> per tag-matched skill, rules
> self-select. $DD26 BONUS / $DD27 PENALTY pair (not 16-bit) via
> saturating adder $455F; veto = $45E4 mid-chain OR end-of-chain borrow,
> both → $788B cell-zero; else dce4[cell] += (26−27), 8-bit. Live walker
> = state 7 at $7865. Semantics measured by a full 160-skill sweep
> (forced option lists $DC64 + forced bases) across a board-state matrix
> — highlights: $5D4D needs-an-ally gate (whole support class vetoes
> solo), $67B1 processed-death revive gate ($DD1B==1, silent HP=0 pokes
> don't count), symmetric cure rules +15, heal bonuses cap at +20 = the
> cat3 weak-heal threshold, $4BCC element-awareness, $4E18 caster-profile
> (+10 CurMP<MaxMP/2, +10 MaxMP≥MaxHP — 4-point MP matrix), $6C8C
> ENEMY-SIDE-ONLY +20, family-cut veto/bonus pair $6848/$4C41 (CleanCut =
> anti-MATERIAL 8; Smashlime = anti-Slime 0). **VANILLA BUG (verified,
> user-flagged as romhack AI-fix candidate): $4E36's AoE "+20 iff 2+
> targets" never increments its scan cursor → +20 iff first opposing
> slot alive (≈always); twin $5D8E (−20 vs lone target; RainSlash hard
> veto) is correct.** False alarm caught in-session: an off-by-one in
> the $6848 handler-table decode briefly produced a "$db4c clobber"
> claim — retracted, lesson filed (KEY_LESSONS S81).
>
> Target resolution (partial): queue target byte = SIDE BASE at commit
> (bank $50 $4B6B for commands); act-phase machine bank $53 $51E8
> sub-state 0 far-calls **$58 entry 4 ($6379)** iff byte==$FF — RNG-slot
> fishing (RNG1&7 → RNG2&7 → mixes → decrement scan) over $2FA5
> validity; $53:$4799 = re-resolve trigger; group skills step per-victim
> in $52:$71B5/$71ED. OPEN: resolver side-constraint (no side filter in
> code — $DD1B masking suspected, one probe outstanding) and the AI-side
> initial post-commit write site. Remaining S81 box: tactics $DB50-52
> plan adjusts (user behavior anchors logged in ROADMAP), MISS/dodge,
> loop-level validation of battle.py, small rule residuals (§15.9).
> **USER DECISION (end of S81): annotation now gates progress — Iron
> Rule 6 added; SESSION_PROTOCOL start-gate + wrap-up step 6 added;
> ROADMAP S82/S83 = annotation catch-up for banks $57 then $52/$53/$58,
> blocking the S81 remainder and the pacing layer until burned down.**

> Last verified: 2026-07-31 (Session 73 — **custom skill $E4 "Anchor"
> SHIPPED, USER-CONFIRMED (incl. S73b: descriptions + battle rejection)** —
> verifier PASS 5/5, clean `1ca6579…`, compiler 38/38, patched pin
> `224b1176…`, full round trip verified in PyBoy AND by the user in SameBoy.)
>
>
>
> Session 73 (2026-07-31 — **custom skill $E4 "Anchor" (user-directed):
> anchor a standard gate floor, warp to GreatTree, warp back later for 3/4
> of the caster's current MP, charged upon ARRIVAL; anchor persists through
> save (save-image bytes), single-use, forced-standard regenerated floor.
> SHIPPED, USER-CONFIRMED (v1+S73b). Final patched pin `224b1176…`
> (superseded interim: `8fa605d7…`)** (clean
> `1ca6579…` untouched). Owning docs: BATTLE_SKILL_SYSTEM §14 (the
> FIELD-cast system, RE'd this session), GATE_GENERATION (town→floor-N
> re-entry recipe), EVENT_FLAGS ($01E0-$01EF retired), known_RAM_map
> (record-layout correction +$50 curHP/+$52 maxHP/+$54 curMP/+$56 maxMP;
> menu-shell vars), KEY_LESSONS (script-arm ctr=$FFFF; menu close = shell
> state 4), PROJECT_COMPILER (template re-pin). As built: bank $07
> usability whitelist rewritten IN PLACE byte-exact (`jr z`→`ret z`
> compression buys `cp $E4/ret z`; the bank had 2 bytes slack) +
> Anchor07Post (post-entry-4 fork: $E4 → menu-shell state 4 = the full
> B-exit teardown; funded by 21 bytes of the $7F58 free run); bank $14
> entry-4 default tail → `rst $10 $7202`; bank $72 AnchorField14Tail
> (context classify: inGateworld=1 → confirm-2 / gate-like `wMapID≥$30` →
> error-4 / town+anchored → confirm-3 / town bare → error-5; arms
> medal_vault scripts via $D8D3=$71 + ctr=$FFFF; caster slot captured);
> GateAwareDispatch template gains the script-type branch (≥$6B, ≠$70
> poison guard; re-pinned); project.json: 4 scripts + 4 auto-id dialogue
> entries (density fix for the no-quest fixture); bank $73 commit-hook arm
> protocol (1=store anchor 1-BASED floor; 2=install gate/floor−2 +
> `curMP := curMP>>2` at the commit = arrival + clear anchor + arm:=3;
> 3 consumed by GateDecisionFork → force standard maze, also bypasses the
> gate-1 POC rotation on returns); wAnchorGate/Floor $D9D7-8 (persistent,
> floor 0 = no-anchor sentinel, hence 1-based storage), wAnchorArm/Caster
> $DEB2-3; Slim harness skills → $E4,$E1,$09; skill name/record/MP-0 rows.
> PyBoy-verified END-TO-END via the REAL menu (A → SKIL grid pos 2 via
> $C8DA → monster → skill → use): cast → menu full-teardown → confirm
> dialog (YES = A,up,up,A in scripted input) → WarpWing-recipe warp →
> anchor stored → town cast → confirm → arrival on the exact floor with
> MP 98→24 → anchor cleared → standard floor. Also verified: both error
> dialogs, NO paths (clean, no side effects), regressions Heal-in-field
> (HP 10→27, MP −2), WarpWing item, town NPC talk, vanilla-style gate
> entry. v1 notes for user test: battle cast of Anchor is a SILENT no-op
> (record anim9=$02); errors open a dialog after the menu closes; YES/NO
> default feel to be judged in SameBoy; save/reload persistence is
> architecture-verified (save-image bytes) but not priest-tested in the
> emulator. Anchor scripts are hosted on medal_vault (room $71) — a
> dedicated script-container room is a cleaner v2 home.)
>

> Session 70 (2026-07-25 — **E2: data-driven side quests + the emulator
> revolution. SHIPPED, user-confirmed.** Owning docs: PROJECT_COMPILER
> (§progression, §vanilla_exit_extensions, §5 re-pin 358 B),
> PYBOY_DEBUGGING (new), SIDEQUEST_MAP (as-built), CROSSBANK_ROOMS
> (unified Entry-6 resolve + walk-on y=7), MONSTER_DATA (quest EID rows),
> KEY_LESSONS ×9. Three pins this session: 6a6f4f87 (v1, wiring),
> 22d30b66 (v2, bug-fix pass), **a5a5e0d5 (v3, walk-on exits — CURRENT)**.
> Headline engine findings, all PyBoy-measured: script text is serviced
> only in dialog mode ($C915 slot $0B) → init_dialog before every
> out-of-interaction say (vanilla Healer protocol, auto-injected);
> field-mode script cadence 1/8 frames; encounter drain 100/step;
> CheckGateWorldMapType's gate-like sweep of $6B+ is load-bearing for
> movement yet caused the 385-frame exit ceremony — fixed by an in-place
> bank $0B tail rewrite (custom source → town path); Entry 9 never runs
> while standing (movement-attempt-gated) → walk-on via the data-driven
> Entry-6 y=7 skip (wCustomY7Cmp, armed by bank $60 entry 7 per scan;
> vanilla rooms byte-semantics-unchanged, regression-checked). Compiler
> hardening: emit_script rejects non-terminated scripts; write_ram2 $13 +
> init_dialog $07 opcodes (both handler-verified; $07's "1 param" table
> row is a decompiler defect). Legacy build.compat retired (narrow table =
> ERROR since the entry-path change). Known cosmetic remainder: guardian
> sprite $23 renders draconic; sprite-id catalog = future session
> (species+$10 disproven; $11 hard-crashes the renderer).**)
>
>

> Session 69 (2026-07-19 — **E3: 32 KB SRAM expansion via the RAMB PIN.
> BUILT, NOT yet user-tested.** Owning: ARCHITECTURE "SRAM banking as built
> S69". Headline: instead of disciplining every SRAM consumer, the quadrant
> convention (`RAMB := rom_bank>>5` on every rst $10 / return trampoline /
> audio-tick entry+exit) is REMOVED at its 19 ROM0 producer sites — each
> `ld [$4100],a` retargeted one operand byte to the MBC5-ignored `$6100`
> (A/flags/timing preserved for trampoline-flag observers; vanilla itself
> writes $6100 at boot = proven-inert sink). Boot's three literal `RAMB:=0`
> kept (the pin's establishment). RAMB is therefore $00 forever; every
> existing consumer (vanilla quadrant-0 save cluster, CF3 bank $73 entries,
> $50/$51 walker dereferences) hits bank 0 = exact 8 KB behavior, zero
> consumer changes. WHY the S65 sketch ("RAMB=0 inside CF3's entry points")
> was wrong: the vblank audio tick saves only the interrupted ROM bank and
> RECOMPUTES `RAMB := quadrant(popped bank)` on exit (AudioPopSetDE) —
> RAMB is not saved state; a per-entry set is clobbered by the first vblank
> (DOC_AUDIT S69, KEY_LESSONS S69 ×2). Untouched writers adjudicated: bank
> $40 di-bracketed 4×8 KB wipe ($FFA3-shadowed, exits via InitGameData →
> boot re-zeros; now genuinely useful at 32 KB); bank $20 streaming system
> ($C68A has NO initializing writer — provably 0; all exits write RAMB:=0).
> `HeaderRAMSize $0149 = $03` (32 KB; rgbfix recomputes checksums). New
> accessor: **CF3SRAMBankedCopy** (bank $73 entry 9; mailbox wSRAMXferBank/
> Src/Dst/Len $DE8B-$DE91 carved from the reserve, 76 B left) — per-byte
> di / RAMB:=n / copy / RAMB:=0 / ei; the pin invariant (RAMB==0 whenever
> IME on) holds at every interruptible point; call with IME on; one side is
> the SRAM side; SRAM stays enabled (CF3 policy); DE preserved. Banks 1-3
> arrive UNINITIALIZED — first consumer brings format/magic (E3 residual).
> Validation: byte-diff vs S65 baseline = exactly 19 operand bytes
> $41→$61 (all ROM0, offsets $1F/$35/$640/$862/$891/$8A0/$8D2/$8E1/$D5F/
> $D76/$1167/$11BA/$1575/$1625/$1632/$33F4/$345A/$34E0/$357A) + $0149 +
> header/global checksums + bank $73 (+2 entry-table shift, label-safe per
> S58 precedent, + entry 9 at $73:$4302); entry 9 byte-executed on emitted
> bytes (copies both directions, bank isolation, len-0 no-op, DE preserved,
> ZERO pin-invariant violations); clean build `1ca6579…` untouched;
> verifier PASS 5/5; compiler 25/25 re-pinned `e719d286db0ff66e80755ec3ef1203e0`
> (patched; prev `de0c5a67…` S65). ARCHITECTURE stale 40-flag claim fixed
> (pre-CF2; DOC_AUDIT S69). E3 remains [~]: (a2) new-game INIT object +
> (b2) banks-1-3 storage schema: BANK 1 NOW CLAIMED (v2 half, below).
> User smoke SAME SESSION: old-save load / gate run / warp heal /
> save+reload / breeding / farm pick+drop PASS; .sav = 32 KB confirmed.
> **S69v2 — USER-FOUND DEFECT → PERSISTENCE v3 (ROSTER SNAPSHOT), same
> session.** Report: unsaved battle deaths (and an unsaved catch) survive
> reset+reload. NOT an S69 regression — the CF3 v2 EAGER roster's reload
> consequence, confirmed from the user's uploaded .sav (party slots 1-2:
> HP $0000 + status bit 7 @ +$4A; +$50 empirically = CURRENT HP). The
> first coffin report was the same mechanism; the S69 Coliseum
> adjudication was WRONG (user: Coliseum faints auto-revive; DOC_AUDIT
> S69v2, KEY_LESSONS S69v2). FIX (owning: MONSTER_DATA "Persistence model
> (v3)"): SRAM bank 1 "R3"-magic snapshot of $A1BF-$AD9E (95×32-B chunks
> via wSnapBounce $DE92-$DEB1), committed by entry 5's DE==$B124 main-save
> detector, restored over the eager image by entry 6's tail (then bank0
> roster → WRAM $CA8D-$CC7F re-copy); magic-absent = one-time seed
> (migration). No di/ei — ISR graph audited SRAM-free + RAMB-free under
> the pin, so hooks are IME-agnostic (boot-safe). Reset-no-save now
> rewinds party+farm to last explicit save (pending-exp rewinds with the
> main image; pool stays vanilla-eager, sleep-flag-gated; unsaved trades
> rewind). New game untouched (snapshot must survive unsaved new game);
> corrupt-save wipe safe ($A002 gate); bank $40 wipe clears magic →
> reseed. Validation: 4-scenario emitted-bytes execution (commit /
> death+catch+reset rewind / migration seed / non-main no-trigger, exit
> RAMB=0 all); diff v1→v2 = bank $73 + global checksum only; verifier
> PASS 5/5; compiler 25/25 re-pinned `94731e601af28503060acf3884348015`
> (patched; prev `e719d286…` S69v1). **v2 USER-CONFIRMED same session:
> all 5 smoke tests PASS (migration heal+save; death→reset-no-save→
> rewound; catch→reset-no-save→gone; breed/deposit+save persists;
> sleep/wake + in-gate save). E3 expansion + persistence v3 are
> user-tested.** Pool write timing verified in code (S69v2): sleep/wake
> commit $B124-$BCC7 eagerly via the di accessors at action time; the
> save funnel's blocks end/start flush at $BCC7/$BCC8 — pool is
> VANILLA-eager, gated by flags in the rewinding image; all sleep reset
> edges resolve exactly as vanilla.**
>
>

> Session 68 (2026-07-19 — **E2 RE half + AUTHORING SPEC: the battle↔story
> engine decoded (byte-neutral). Owning section: SIDEQUEST_MAP "Story
> progression ENGINE + AUTHORING SPEC — DECODED S68".**
> Headline: **"win → subsequent script commands run" is an engine
> guarantee** — wGameMode $C88A (ROM0 tables $00:$030F init / $00:$050F
> tick; mode 1 = field bank $01, mode 2 = battle bank $50); battle request
> = wGameState.6 latch → bank $13 $C905 transition ($13:$73F5 = the ROM's
> only res 6) → mode 2; script VM state $D8D5-7 survives in WRAM;
> BattleExitHandler ($50:$640A) restores mode 1 + $C8EA.7 → bank $01
> ClearAnimationState SKIPS its reset → script resumes after the battle
> opcode (= the on-win rewards). LOSS ($DB55==1): $D92B=8, engine warp to
> Castle via the opcode-$0F cells, gold $CA4B-4D halved, items dropped
> unless info byte +$0B bit 2 (keep-on-defeat = TinyMedal/BeastTail/
> WarpStaff/ShinyHarp/BookMark — user FAQ list VERIFIED +BookMark), $D8D7
> cleared. **$D9EC = 18-phase battle machine** (BattlePhaseTable $50:$5F3A;
> not 15; intro 0-3 / main 4-8 / sequencer 9 on $D9ED / post $0A-$0D /
> exit $0E-$11), outcome set by bank $52 KO scans (~$76E0 loss / ~$7727
> win; XOR'd for link peer; $DB73=$FF loss freeze). **$D9F4 = nested
> battle sub-machine** (bank $50 header's "main game state" framing + the
> "$C86C = gate world" claim were WRONG — $C86C is the LINK flag, bank $03
> serial setters; state variants are LOCAL/LINK; wInGateworld=$C969).
> **Evaluation opcodes resolved**: $CA8D = party count (Well/Bazaar-Edge
> "==1" = can't-forfeit-last-monster refusal, NOT skill check); $FF92 =
> hPlayerX low (Bazaar 215/216/217 = position gate); $D8E1 = result cell
> of the 10-opcode evaluator family $23/$30/$32/$34/$38/$51(library-seen
> tiers)/$55(item count)/$56(gold÷10)/$59/$5F (census in
> BANK04_SCRIPT_ENGINE); opcode $45 = restore party from $CAB9 7-byte
> snapshot. Deliverables: bank_050 header rewrite + BattlePhaseTable/
> BattlePhase09SubTable re-sections + 18 phase labels in BOTH trees
> (sym-verified addresses; renames Jump_050_640a→BattleExitHandler,
> Jump_050_6aac→BattlePhase09_TurnSequencer); wram.asm wBattlePostFlag
> comment (0=win/1=loss/2=undecided); ARCHITECTURE mode table +
> bank/$D9F4 rows; known_RAM_map (10 rows); MONSTER_DATA fixes;
> SIDEQUEST_MAP spec + 3 corrections; DOC_AUDIT ×3; KEY_LESSONS S68;
> ROADMAP E2 → [~] (RE+spec done, schema wiring open). **Campaign
> recommendation recorded (user Q): new-world spine in custom rooms via
> generated scripts; vanilla intact as postgame; arena gating = re-authored
> Arena Lobby scr0; capacity = 32 flags → E3 or audited vanilla-flag
> reuse.** **HW-pinned same session (user SameBoy): FLEE → $DB55=2
> neutral (resolver $50:$5808 jumps phase $0A + masks exp targets
> $DD1F-22; no penalty; $DB73-armed edge → 1); CAUGHT monster → plain win
> ($52:$7729 = 0 via the phase-7 chain, backtrace-verified); $C899/$C89A
> proven the LIVE RNG pair (adjacent examines differ) → LoadBtl_5d29's
> &$1F==$1F = 1/32-per-side random battle-intro event ($DB55 doubles as
> its marker until the KO scans).** Residuals: $CAB9 snapshot writer;
> intro-event message text (3-14). Byte-neutral: clean build `1ca6579…`
> unchanged; verifier PASS 5/5.



> **Purpose.** This file is a verbatim archive of superseded PROJECT_STATE.md
> session blocks and of long narratives compressed out of ROADMAP.md. It exists
> so that consolidation never loses information — but it is **not session
> reading**. Every canonical fact in here already lives in the owning reference
> doc (BATTLE_SKILL_SYSTEM, MONSTER_DATA, GATE_GENERATION, BREEDING_SYSTEM,
> TEXT_SYSTEM, KEY_LESSONS, …); when this archive and a reference doc disagree,
> the reference doc wins. Use this file only for forensics ("when/why did X
> change") — the session index in PROJECT_STATE.md points here.
>
> **Aging rule (SESSION_PROTOCOL §3):** PROJECT_STATE.md keeps only the latest
> TWO session blocks verbose. When a new session block is written, the oldest
> retained block moves here VERBATIM (prepend to Part 1) and gets one index row
> in PROJECT_STATE. Nothing is ever summarized away — moved, not rewritten.

---

## Part 1 — Archived session blocks (verbatim, newest first)

> Session 67 (2026-07-19 — **E1: arena / gate-boss opponent-roster format
> DECODED (byte-neutral). Arena path USER-VERIFIED on HW same session.**
> Headline: there is NO arena roster table — opcode $1F `ArenaBattleSetup`
> ($04:$5D5B; between-matches clone `LoadArenaEnemyStats` bank $50) computes
> **EID = $E0 + 9*wArenaGroup + 3*wColiseumBattle + slot** → 90 consecutive
> enemy-stats rows ARE the brackets (groups 0-7 = G..S, 8 = Starry Night
> 296-304, 9 = King, overridden to $01E1-$01E3; formula rows 305-313 =
> unreachable rival-team cut data). Group source: bank $09 lobby menu
> (4*[$C8E3]+([$C8E2]&$7F); gold table $09:$5D23; availability $C0D8) or
> Arena Lobby scr6 write_ram (group 8/9 + $D999 = 1/4). $D999 = map-$5D step
> counter (0 arena / 1-3 Starry phases / 4 King). Master lobby sprites:
> `ArenaMasterSpriteTable` $04:$5E22 (30×[gfx,is_monster]; dup $50:$6778) —
> both re-sectioned from fake instructions (byte-perfect). Gate bosses:
> EVERY boss fight is the opcode $5A/$05 EID param in the boss ROOM script
> (53-site census, all script-attributed): Medal Gate has THREE variants
> (156/153/155); Durran gate = 3-fight chain (write_ram2 Servant 342 ×2 +
> op $20 → op $05 Terry 343 @ $0F:$4D46 → op $05 Durran 199 @ $0F:$4DB8;
> post-game Terry rematch $0F:$500E); Bewilder/Anger decoys (341×4/349×7);
> Digster = op $05 127; NEW: undocumented MadGopher L21 event battle
> (EID 255, Castle scr13 + Farm scr26); Tatsu EID 344 unused. **$14:$4893 is
> the fight→join RECRUITMENT redirect, NOT a boss-selection table** —
> boss_table.json semantics corrected (data unchanged; DOC_AUDIT S67).
> Coliseum (map $52): RNG level-banded parties (op $5C `ColiseumInitPrize`
> keys MAX level, bank $16 twin keys AVERAGE; bands 2×9 then 18-wide at
> 13/33/57/81/105/129/157/181; parties 2/3 staged $D9D1-6/$D9D9-DE, chained
> by $50:SetBtl_67ae; prizes $04:$6F44/$6F54, visit counter $D9CF). Mimic
> (op $36, $04:$63EF) tiered by **$CAB4 = arena progress** (Arena Lobby scr0
> writes class+1 per victory — the scr0 per-class victory cascade of rank +
> catch-up flags + world step counters is now fully tabled in SIDEQUEST_MAP).
> Op $52 = random scaled battles ($04:$6A3C). Battle-slot RAM: $DA03/05/07
> 16-bit EIDs, **$DA02 = count−1**, $DA09 mode 0/1/2/3. **HW verification
> (user, SameBoy write-watchpoints, Class D)**: $DA02=$02 written at
> $04:$5D8E with EIDs 251/252/253 (= $E0+27, exact formula), caller DE=$47AA
> (scr6); regen fired at the $50 clone; $DA09=$01 by op $20 at $04:$5E69
> from map $5D scr0 (DE=$61E4). Deliverables: `tools/dump_arena_brackets.py`
> → `extracted/arena_brackets.json` (Tier A, self-checking anchors); owning
> prose SIDEQUEST_MAP "Arena / gate-boss ROSTER format — DECODED S67" incl.
> AUTHORING SPEC for E2; annotation both trees (2 table re-sections, 3 label
> renames incl. the wrong `ArenaGenerateBattles`→`ScriptWriteRAM`, 7 opcode
> header fixes); corrections in QUEST_OPCODES / known_RAM_map / DOC_AUDIT
> (2 rows) / KEY_LESSONS (2: script words are op|$FF00; synonym-grep before
> "not documented"). Residuals banked in SIDEQUEST_MAP ($DA09 modes 0/2/3
> code-derived; intro Dracky EID 4 engine-side; match-2/3 loop not stepped).
> ROADMAP E1 ✅ — E2 unblocked. Verifier PASS 5/5; clean build `1ca6579…`
> unchanged; editor2 untouched.


> Session 66 (2026-07-18 — **A′1: mapID ≥$80 readiness audit — engine is
> ≥$80-READY as patched (byte-neutral session). CF4 v7 USER-CONFIRMED
> ("custom rooms work fine after WRAM move, no issues").**
> Census: exactly 58 (clean) / 56 (patched) `ld a, [wMapID]` sites, zero
> pointer-form/literal-$C968 refs, 21 writers (constants/copies/table reads,
> no masking). Every site instruction-verified and adjudicated; reproducible
> via new `tools/audit_mapid_range.py` (label-keyed verdicts, SELFTEST pins,
> NEEDS_REVIEW tripwire for post-S66 code) → `extracted/mapid_range_audit.json`.
> **Headline: the ROADMAP's "sign-test" fear was structurally impossible —
> the SM83 has no sign flag (`jp m` doesn't exist); every mapID compare is
> unsigned `cp`, so ≥$80 takes the identical branch proven by rooms $6B-$70.**
> The `bit 7` hits near mapID reads are all on OTHER variables (wInGateworld,
> $c8ea, skill id $db8a) or the NPC-entry TYPE byte ($8F/$90 spawn/exit
> discriminators — by-design format, not mapIDs). Real ≥$80 hazard classes:
> (a) 8-bit `add a` doubling drops the $100 carry — **RST_00 itself is
> $7F-capped this way** (`add a / add l` destroys the doubling carry before
> `adc h`; RST_20 likewise) — the only mapID-driven rst $00
> (PerRoomDispatchEntry) is clamp-protected; the four bank $0B RoomPtrTable
> walks, both bank $17 AttrPtrTable walks: diverted for ALL ≥$6B by unsigned
> `cp CUSTOM_ROOM_START` predicates upstream; (b) fixed tables:
> FloorPalettePtrTable/EncounterRateData/GateFloorDataTable/FloorDamageTable
> are gate-context (wMapID = floortype/gateID <$20 there); RoomBGMTable is
> `cp $61`-guarded + S64 resolver-first. Copies (wWarpGateId, $c8fb pair,
> hram $d5/$d6, wScriptMapType, wGateID, $c96a) traced: full-byte, consumers
> unsigned. Exit dest_map_type = full unmasked byte end-to-end.
> **Ceilings**: hard mapID $FE ($FF = exit terminator); practical $EA
> (custom-side `sub $6B` then 8-bit `add a` idiom); 75-room plan (max $B5)
> fits with 53 spare. **Feature cap**: room-default music stops at $7F
> (bank $71 `cp $80` guard + 128-entry table + music.py:176 loud validator)
> — compiler-owned extension recipe + 2 recommended exit validators
> (gate_flag=0 to custom dests; trigger_x≠$FF) recorded in CROSSBANK_ROOMS
> §"mapID ≥$80 readiness audit" (owning) and as the A′1 ROADMAP follow-up.
> **WATCH**: bank $01 default-spawn table (auto-label `NPCWalkDataTable`
> is misleading — annotated in BOTH trees, comment-only) — pre-existing
> ≥$6B overrun, benign on all proven paths (v7); $80 changes nothing.
> Verifier PASS 5/5; clean build `1ca6579…` unchanged; editor2 untouched.
>
>


> Session 64 (2026-07-18 — **Arc 3 M3b + M3c: room-default music + MIDI
> import, both USER-CONFIRMED (test ROM v6 `7cc0857faad8a950573e865e93f791eb`,
> patched).** User decisions: DQ6-town MIDI → the vanilla LIBRARY room ($12)
> to prove vanilla-room assignment; room $6B default = DWM2 BGM #07; this
> ROM is testing-only (the real romhack starts from vanilla via the editor;
> sources = inbuilt ids, DWM2 catalog, MIDI); >3ch songs drop extras for
> now; `custom_songs.json` retired.
> **M3b engine**: traced `LoadNewBGMIdIntoA` $01:$432D-$4372 (70 B, single
> caller `CheckScreenLock` ← `InitFieldState` ← `GameInit` — runs on map
> entry AND save-load, which is both why script SetBGM was transient and
> why the fix survives reload by construction). `RoomBGMTable` $01:$4373 =
> 112 B, $70 entries (mapIDs $00-$6F, $61+ padded $34) — re-sectioned from
> fake instructions to labeled `db` in BOTH trees (clean build still
> `1ca6579…`; fake labels jr_001_43bd/43dc were misassembly-internal).
> Patched tree: SAME-SIZE rewrite (−9 B funded by the vestigial `cp $09/
> ret nz/ret` tail, the redundant 2nd `ld a,[wMapID]`, and `adc h/sub l`;
> +7 B prologue `ld hl,$7102/rst $10/ld a,e/or a/ret nz`; 2 pad) — table
> address unmoved, vanilla fallback byte-equivalent. Bank $71 template:
> 3-entry table + `CustomRoomBGMResolve` (E := `CustomRoomBGMTable[wMapID]`
> or 0; gate floors return 0 — wMapID isn't room-meaningful there; the
> proven rst $10 DE-return contract). Templates re-pinned (`64cb43ee…`),
> TEMPLATE_SIZE $71 116→142 ($408E).
> **Compiler**: `custom.music` live (PROJECT_COMPILER §2.9): `libraries`
> (repo-committed catalogs) + `songs` (library refs or inline; `first_id`
> explicit/auto from $9E) + `room_defaults` (ANY mapID $00-$7F; raw value =
> inbuilt vanilla id) + `rooms[].music` sugar (conflict = error, found by
> a new test: key normalization `0x6B` vs `$6B` had let conflicts slip).
> Trio normalization at bake: missing $34/$4E/$68 slots pad silent (6 B;
> InitBGM starts 3 CONSECUTIVE ids — an unpadded 2ch song would start its
> neighbor's channel), >trio drops warn (InitBGM ext boxed). `music74`
> emitter owns generated `patches/bank_074.asm` via `song_codec.
> song_bank_asm`; existing BGM #06/#07 streams verified BYTE-IDENTICAL
> under the new ownership (fixed-record-area property); `dispatch71` emits
> the 128-entry BGM table. 25/25 tests (8 new music tests) @ re-pinned
> `7cc0857f…`; verifier PASS 5/5.
> **DWM2 catalog**: `song_codec.py extract-gbs-library` → `extracted/
> dwm2_song_library.json`: ALL 31 subsongs (19 BGM + 12 jingles, names per
> the zophar m3u set, ids via GBS song map @ $0FC0) translated +
> trace-proven, 57,383 stream B total (catalog only — the emitter bakes
> assigned songs; bank $74 streams cap 16,000 B). GBS never needs
> re-uploading (md5 recorded). New foreign cmd `$A4` (×6, BGM #19)
> instruction-verified as a 2-byte NO-OP IN BOTH ENGINES (DWM2 dispatch has
> no `cp $A4`; terminal default `inc hl/jp $358A`) — unlike $AA, not even
> an ornament is lost.
> **M3c**: `tools/midi_to_song.py` (pure-python SMF 0/1 → catalog entry):
> frame-accurate boundary rounding, monophonize (new-on truncates prev),
> lowest-mean-pitch→wave auto-map, $A7 tie-holds >255 frames, `B0 $FC`
> whole-song loop, decode round-trip checked. dq6_town1: 3ch, 1,325 B,
> 92.0 s/loop, 204 overlap cuts. **Two engine corrections en route
> (instruction-verified; owning SOUND_SYSTEM §4/§5, DOC_AUDIT S64):**
> (1) note lengths are FRAMES — $EC decrements unconditionally every frame;
> $FA/$FB only gates the groove stepper (S61 "ticks" falsified; duration
> evidence: the 0:01 jingles); (2) $A3 bit7=0 ENABLES the groove stepper
> and every groove row @ $3B83 is a live vibrato/detune shape — `$A3 $80`
> (E5 &= $0F) is the only deterministic straight form; the converter emits
> it. Also §5's "octave downshift" rephrased: P>>n RAISES pitch; note $00 =
> C2 = MIDI 36 (from `AudioLoadNoteB` + the $3A53 values).
> **v6 acceptance MET (user)**: Library plays DQ6 Town; $6B defaults to
> BGM #07 including save/reload; NPC overrides intact; vanilla rooms/gates
> unchanged.


> Session 63 (2026-07-18 — **Arc 3 M3a BUILT, NOT yet user-tested: general
> song slots. v4 test ROM `c23beed7aadee80a061c0f6c24d7c1f4` (patched).**)
> **The S62 blocker ("ROM0 has NO 17-byte free run") dissolved by auditing
> our own CLAIMS, not vanilla filler** (KEY_LESSONS S63): the twin helpers
> `MapIDClampForDispatch`/`MapIDClampForPalette` were byte-identical
> (merged — one 8-B body @ $3BC2 carrying both exported labels; all callers
> relink) and `CustomGFXMapID` was DEAD since S42 (bank $71 Entry 0 replaced
> all consumers; its header still said "used by" — DOC_AUDIT S63; deleted).
> Freed 24-B $3FE8 slot hosts **`AudioMasterTableExt`** (3 vanilla rows
> byte-identical + row `[$9E,$4001,$74]` + $FF sentinel; ONE spare future
> row); `AudioProcess`'s single `ld hl,$3466` operand repointed ($33D9,
> 2 B). Zero WRAM (user constraint), zero boot changes, zero net ROM0 bytes.
> **Bank $74 = song bank** (`patches/bank_074.asm` ← `song_codec.py
> emit-song-bank` ← `extracted/custom_songs.json`): vanilla-bank convention,
> FIXED 95-slot record area $4001-$417C (ids $9E-$FC; adding songs never
> moves old streams), streams from $4180. BGM #06 migrated via new
> `import-port` (byte-identical to the S62 trace-proven blobs incl. the
> translator's unreachable trailing $FF; static re-trace = S62's exact
> 1858/1566/2287 event counts); **bank $1E back to 100% vanilla** (patch
> deleted; orphan-slot route retired). Static proof: all vanilla ids
> $00-$9D resolve identically through the new table. Capacity ~31 3-ch
> songs; 10,965 stream B free. patches/game.asm includes bank_074 (the
> blank-stub include was the one build gotcha); verify_integrity
> PATCH_FILES/PATCH_NEW_FILES updated.
> **Pre-existing defect found+fixed: S62 broke compat==hand byte-identity
> silently** — hand edits to compiler-owned bank_060.asm (BGM NPC record,
> `SetBGM $9E`, "DWM2 music!") never folded into the example project; pin
> left at S60's; CI runs only verify_integrity so nothing failed. S63
> ported all three into project.json → compat build == hand tree again
> (both `c23beed7…`), `REFERENCE_MD5` re-pinned, 18/18 `--rom` tests green.
> PROJECT_COMPILER's quick-start md5 had ALSO been stale (S57 value while
> the pin was S60's) — fixed. **CI follow-up boxed in ROADMAP** (add
> `test_compiler.py --rom`). Doc fixes: SOUND_SYSTEM §1 engine addresses
> were transcription slips (`AudioProcess` = **$33D2**, updates
> $33CF/$33CC/$33C9 — not $3477/$3474/$3471/$346E; sym-verified);
> "$3BC1" comments were off by one (code @ $3BC2). SESSION_HISTORY: S60
> block refiled from file tail into Part 1 order (S61 misfiling).
> **v4 USER-CONFIRMED same session** ("music plays as before via NPC, no
> issues"); user-observed save/reload music transience = vanilla SetBGM
> behavior, expected non-issue for M3b room-defaults (SOUND_SYSTEM §8;
> room→BGM derivation to be traced at M3b wiring). **v5 BUILT + USER-CONFIRMED same session** ("Sounds great";
> GBS re-uploaded): DWM2 BGM #07 (GBS index 6 →
> internal id $19 via song map @ GBS $0FC0) → DWM1 ids $A1-$A3, 2,471 B
> in bank $74 (`add-gbs-song`: extract+translate+prove+slot-map); room $6C
> screen 0 NPC (5,6) `SetBGM $A1` wired through project.json + `--apply`
> (bank_060/bank_071/bank_017-regions/wram-region now compiler-generated —
> the sanctioned route S62 skipped); pin re-pinned `3009b75e…` (v5 compat
> == hand tree by construction). End-to-end proof: ROM-resident $A1-$A3
> under DWM1 semantics == original GBS bytes under DWM2 semantics
> (954/645/840 ev). Foreign `$AA`×20 verified NON-FLOW at instruction
> level (DWM2 handler @ GBS $37AE: one param, HRAM $F2/$F3/$ED only) —
> a DWM2 ornament dropped as no-op in DWM1; ear test judges. v4→v5 ROM
> diff: banks $60/$74 + header checksum only.
> **v5 acceptance MET (user)**: both NPC songs confirmed in-game; the
> $AA-ornament drop passed the ear test unremarked.


> Session 62 (2026-07-17 — **Arc 3 M2 COMPLETE: song round-trip codec.
> M3 POC: DWM2 BGM #06 audible in custom well room — USER-CONFIRMED by ear
> ("sounds great"). patched test ROM v3 `5683146a…`.**)
> **M2 (`tools/song_codec.py` + `extracted/songs_spec.json`):** decode /
> selftest / extract-gbs / build-port / patch-bank1e. Selftest decodes ALL
> audio in banks $1C/$1D/$1E (157 streams: 153 referenced + 4 orphan) and
> re-emits full 16KB banks **byte-identical**. **Grammar corrected vs S61
> (owning: SOUND_SYSTEM §5):** there is NO standalone 3-byte $FC jump — the
> real form is a `Bn` pair with param $FC + a (lo,hi) TARGET PAIR (4 B);
> engine reads the Bn's own param at AudioCheckFC; counter elapse skips the
> target pair. Bn prm=$00 = $EE counter + mark-return (no skip). B0 =
> unconditional. Counted loops play n+1 passes. $F0-$FB/$FE = 2-byte no-ops.
> Mark = state+$14/+$1A (CONFIRMED at instruction level). Bank $1E orphans:
> 4 records @ $419D (ids $9E-$A1 via the open-ended master-table row — ZERO
> ROM0 changes needed for the port) + 4 orphan streams; $00 filler $6B7D+.
> **M3 POC (patches/bank_01e.asm regenerated by patch-bank1e; bank_060.asm
> NPC):** BGM NPC placed room $6B screen 0 metatile (5,6) (v2 fix: the
> script existed but NO NPC was wired — SOUND_SYSTEM's claim falsified,
> DOC_AUDIT S62); SetBGM $9E; reverts on room exit (vanilla).
> **v1/v2 played but SKIPPED + distorted → root cause via targeted DWM2 GBS
> driver RE (sanctioned by M3's "fix $AC + header diffs"; owning: SOUND_SYSTEM
> §7):** DWM2 driver has (1) **$AC n = counted CALL** — the pair after it is
> a 16-bit LE byte-offset target; phrases live PAST the $FF terminator;
> **$AD = return** (single slot, no nesting); v1/v2 truncated at $FF, losing
> the phrases, and DWM1 executed target pairs as bogus commands. (2) **4 mark
> slots per channel with private counters** (`FD slot`/`Bn slot`, resolver
> $DCC0+ch*12+slot*3); under DWM1 these collapse to the single mark and the
> prm∉{00,FC} elapse path EATS the following pair. Headers: all 4 fields
> parse identically (GBS $3503) — no translation.
> **Fix: translate_dwm2_stream()** — true-grammar walk → IR with labels →
> nested counted loops UNROLLED (only pulse1 nested, 2 sites, depth 2) →
> DWM1-native emit (AC phrases inlined, slot loops → Bn/$FC jump form; both
> engines play n+1 passes, exact match). **prove_translation(): static
> event-trace equivalence (DWM2 semantics on original bytes vs DWM1 semantics
> on translated bytes, 2 outer wraps) — PASS 1858/1566/2287 events**; ROM-
> resident streams byte-equal the proved translation. 5,035 stream B @ $6B80;
> diff envelope bank $1E $419D-$7F2A + header checksums + bank $60 NPC.
> **Limits/next (ROADMAP M3):** orphan-slot route caps at ONE custom song
> (4 record slots); general authoring needs master-table relocation but ROM0
> has NO 17-byte free run — open problem. **USER REQUIREMENTS logged: song
> LIBRARY in the editor, assignment to rooms/gates, MIDI import.** Residual:
> $Cn/$A5/$A8 audible semantics unverified (same family; ear test clean).
>


> Session 61 (2026-07-17 — **Arc 3 M1 COMPLETE: sound engine + song data fully
> mapped. Byte-neutral: tool + docs + comments only; ROM MD5 unchanged.**)
> **Engine (owning doc SOUND_SYSTEM.md — new, user-approved):** entirely ROM0
> $3331–$3AB2 region, VBlank-driven; the ROADMAP claim of song banks
> `$61 $62 $63 $65 $66 $68 $78 $7b $7d` is FALSIFIED (DOC_AUDIT S61) — ALL
> audio data is in banks **$1C/$1D/$1E**. Master table @ ROM0 **$3466**
> (`[base_id, ptr, bank]` rows; $00-$20→$1C, $21-$36→$1D, $37-$9D→$1E; the
> `ld hl,$3466` operand in `AudioProcess` is the M3 extension hook). Per-id
> record `[state_slot, hw_ch, seq_ptr]`; a sound = CONSECUTIVE ids, one per
> channel ($DE24 increments per AudioProcess call; Update1x/2x/3x = 2/3/4 ch).
> 6× 26-B channel state @ $DD80 ↔ HRAM $FFE4-$FFFD per tick. **Streams =
> 2-byte (cmd,param) pairs, position = PAIR INDEX (addr = base + pos*2) → all
> jumps stream-relative → streams relocatable.** Notes <$A0 (semitone|octave,
> len); $Ax ctl (unknown $Ax = 2-byte no-op); $Bn loops; $FC jump; $FD mark;
> $FF end. Pitch table $3A53 (12+12 words), noise $37C5, wave instruments
> $316E (16 B each). `tools/enumerate_songs.py` + `extracted/songs.json`:
> **86 sounds / 158 streams, all terminate, zero overruns**; track $06
> decoded note-by-note (acceptance).
> **DWM2 (user-supplied GBS `DMG-BQLJ-JPN.gbs`): same engine family** — pitch
> table + all 16 wave instruments byte-identical; same master-table algorithm
> (@ GBS $3DC2, DWM2 banks $40-$43), same stream format; driver evolved
> (state 26→32 B, new cmd $AC = benign no-op to DWM1). **User's target DWM2
> BGM #06 = internal id $16, 3 ch, 1,762 B relocatable — direct port judged
> feasible** (SOUND_SYSTEM.md §7); replaces MP3 transcription.
> **User requirement logged: M3 must accept BOTH DWM2 tracks AND MIDI** —
> M2's decoded-song spec is the common intermediate (ROADMAP M3;
> SOUND_SYSTEM §8). DWM2 stays extraction-only.
> Byte-neutral session — no test ROM. Verifier PASS 5/5; clean build
> byte-perfect `1ca6579…` (bank_000 audio comments only). NEXT: M2 round-trip
> keystone (nails the §4/§5 *(unverified)* rows), then M3.

> Session 60 (2026-07-16/17 — **CF3 COMPLETE: farm slots 3-19 moved to SRAM.
> USER-CONFIRMED 2026-07-17 (sleep/unsleep, breeding + reload, gate saves,
> "all tests normal") — hand-off accepted.**)
> **The move (v2 architecture):** farm slot s (3-19) lives permanently at its
> save-image address $A1FB+s*$95 (window $A3BA-$AD9E); party 0-2 + staging
> stay WRAM; WRAM $CC80-$D664 FREED (custom-room buffers at $D379-$D477 now
> legal in place — S55 hazard + ≤14 rule RETIRED). Rebase WRAM<->SRAM =
> -/+$28C6. GMDP forks per-slot (fast path <3, slow path via bank $73 entry 3);
> 48 walker advance sites across 10 banks patched with the byte-neutral
> `ld hl,$730x / rst $10` dance (BC/HL preserved via push/pop — **rst $10
> CLOBBERS BC**, caught by interpreter validation pre-ship). Bank $73 entries
> 2-8: AdvanceDE / RebaseDE / Checksum / CopyTo / CopyFrom / NewGameClear /
> TradeRecv. bank $59 NOT patched (party-only by S58 sort invariant — bank
> 100% full anyway).
> **Persistence model (v2, the field-bug fix):** the entire roster image
> $A1C7-$AD9E (list + library bits + monster vars + party records + farm) is
> EAGER — checksum v2 excludes it ($A002 x $1C5 + $AD9F x $1261, seed $4638);
> the canonicalizer tail mirrors WRAM $CA8D-$CC7F -> $A1C7-$A3B9 after every
> canonicalize. World state stays lazy. Reload restores the last canonical
> roster; roster changes are never half-committed/duplicated/lost (the v1
> field bug: cross-space sort swaps committed SRAM eagerly, WRAM lazily).
> Migration self-heal accepts vanilla-full AND S60v1 stored checksums,
> rewrites v2 in place at boot verify.
> **The "third field bug" was NOT a bug:** save analysis (checksum-format
> fingerprinting) proved the user was on the recalled v1 ROM, AND loading an
> S52-era emulator save state under S60 splices two timelines (state WRAM has
> the S52-layout roster; S60 reads slots >=3 from the state's OLD SRAM).
> **Save states across the storage migration are architecturally invalid**;
> same-build states are safe (both tiers snapshot atomically). Machinery
> vindicated by 145/145 battery + 5 differential simulations of real ROM
> bytes vs the vanilla oracle (bank-aware SM83 interpreter) + a clean replay
> of the user's real .sav under v2.
> Patched-build/compiler pin `168c5f1b5b4b3b2568a6d6e2f3f1ab45` (18/18);
> verifier PASS 5/5 (PATCH_FILES + bank_00a/bank_015/bank_051). Clean build
> untouched `1ca6579…`. Owning docs: MONSTER_DATA "CF3 as built (S60)",
> ARCHITECTURE SRAM layout, known_RAM_map, KEY_LESSONS (5 new), ROADMAP CF3
> [x].

> Session 59 (2026-07-16 — **Phase 0 close-out: the last two Phase 0 boxes.
> Byte-neutral: tools + docs + comments only; ROM MD5 unchanged.**)
> [S61 archival note: the following six lines are the tail of S59's original
> header sentence, orphaned in PROJECT_STATE when S60's 'Last verified' line
> replaced its head; rejoined here verbatim.]
> (tool selftests) + `extracted/skills.json` retired. Byte-neutral session —
> no test ROM. Verifier PASS 5/5** — clean build byte-perfect `1ca6579…`
> (unchanged; the only `disassembly/` edits were comments). Patched-build /
> compiler-regression reference `d31c9300e13b98f516c6bee8b446069d`
> (**patched**) is UNTOUCHED — this session emitted zero ROM bytes; v1
> `79dd32c5…` (patched) and S57 `6c41f0d8…` (patched) remain historical.)
> **NOTE — the ROM was not attached to the kickoff.** It did not need to be:
> the clean build reproduces `1ca6579…` from source, so `data/DWM-original.gbc`
> was reconstructed from `disassembly/game.gbc` and MD5-verified canonical.
> Worth remembering — a missing ROM is not a blocker.
> **(1) `verify_integrity.py` check 5 = tool selftests** (owning doc
> TOOLS_AND_DATA "Guardrail"): `check_tool_selftests()` + `SELFTEST_TOOLS`
> runs `--selftest` on `build_breeding.py` / `build_library_table.py` /
> `build_skill_tables.py`; labels renumbered `/4`→`/5`. **The load-bearing
> design decision is ROM-tolerance:** the ROM is gitignored/user-provided and
> `.github/workflows/verify.yml` runs WITHOUT it ("MD5 compare needs only the
> expected hash"), so an absent ROM **SKIPs** check 5 — failing there would
> break every CI push. A present-but-non-canonical ROM still FAILs. All four
> branches proven: PASS 5/5 clean; FAIL on a mutated `skill_records.json`
> `mp_cost` (pinpointed `SkillMPCostTable` offset 0, restored → PASS); SKIP
> with no ROM; FAIL on a 1-byte-corrupted ROM.
> **(2) `extracted/skills.json` RETIRED (deleted).** The box's scope was
> INVERTED (DOC_AUDIT S59): "only `gen_name_tables_db.py` reads it" — that
> tool declared `SKILLS_PATH` and never opened it (dead constant, removed,
> output byte-identical); the three real readers (`gen_skill_table_db.py`,
> `gen_enemy_stats_db.py`, `gen_monster_db.py`) were named in no doc. All
> ported to `skill_records.json`; they use only `id`→`name`, so each port is
> one line. `gen_enemy_stats_db` + `gen_monster_db` outputs byte-identical;
> `gen_skill_table_db` comments-only. `dump_skills.py` → inert tombstone
> (exits non-zero; the `dump_monsters.py` "legacy dumper resurrects a deleted
> file" hazard).
> **ROOT CAUSE (the session's real find; owning section BATTLE_SKILL_SYSTEM
> "Extent"):** the 34 junk records (ids 222–255 — the docs said 33) came from
> reading the **222**-entry skill function table as **256**. The table is
> `$52:$4011..$41CC` (222 × 2 = 444 B) and is **UNTERMINATED** — its bound is
> simply where the next thing starts: `SkillBlaze` @ `$52:$41CD`
> (`CD FF 5B` = `call $5BFF`). The phantoms were that handler's CODE decoded
> as pointers (`$CD` = `call` opcode ⇒ the bogus `$FFCD`/`$CD5B`/`$E7CD`).
> Corroborated three ways: `$4011 + 222*2 == $41CD == SkillBlaze`;
> `build_skill_tables.py --selftest` re-emits `SkillFunctionTable` at **444
> bytes byte-identical**; ported `gen_skill_table_db` now emits **zero `?`
> fallbacks**, proving `skill_records.json` covers the id space exactly.
> **Doc errors fixed in place (DOC_AUDIT S59):** `bank_052.asm` header
> `$4011..$41BC` → `$41CC` (`$4011+$1BC = $41CD`; the count 222 was right, only
> the end address was wrong — a correct-looking header with one bad number),
> in BOTH `disassembly/` and `patches/`, comment-only, build re-verified
> byte-perfect; same headers' `; Sources: … skills.json` → `skill_records.json`;
> `gen_skill_table_db.py`'s `256 entries`/`512 bytes` → 222/444 and its bogus
> `$4211` xref → `$6CC7` (the only `21 11 40` in bank $52 is `$6CD5`, inside
> `jr_052_6cc7`). The disassembly had been correct at 222 since S45 — the
> TOOLS had rotted past their own source.
> **NEXT:** Phase 0 is now clear, so feature work is unblocked: CF3 (a2)
> (pre-sort save migration) + the two redirected walker helpers (b), or A′1
> (mapID ≥$80 audit). S58's residual test item stands: battle JOIN was never
> explicitly exercised.

> Session 58 (2026-07-13 — **CF3 step 1: party-first sort. The invariant
> "party at slots 0-2 in list order, farm contiguous after" now holds after
> every canonicalize** — the CF1-flagged precondition for farm→SRAM.
> Owning section: MONSTER_DATA "CF3 step 1 as built".)
> **User decisions settled at session start (recorded in ROADMAP CF3):**
> (1) party-first SORT over index remapping; (2) freed-range save semantics
> = **EXPLOIT** (keep the vanilla block copy — the range persists across
> save/load; layout rule: transient scratch stays $DE74, relocated buffers
> take a corner, the bulk is the editor's persistent-state pool, usable
> only AFTER the walker redirects land).
> **Implementation (1 operand edit + 1 new bank entry):** canonicalizer
> tail `ld hl,$0106 / rst $10` at $01:$4808 retargeted **$0106→$7301**
> (2 operand bytes $4809-$480A; pattern `79 EA 8D CA 21 06 01 D7 C9` unique
> in ROM). Bank $73 entry 1 `CF3PartyFirstSort` (patches/bank_073.asm):
> selection sort over ≤3 party-list positions (entry state per vanilla:
> occupied contiguous, list compacted/unique ⇒ t=list[i]>i), 149-B record
> swap i↔t + fixups of every WRAM cell holding raw slot indices across a
> canonicalize — later party-list entries (==i→t), battle-position cache
> $DA15-$DA17 (exchange i↔t; vanilla compaction is provably no-op at the
> mid-battle join canonicalize, the sort is not), $CA40 breeding-offspring
> persist (exchange; vanilla compaction happens to preserve it, the sort
> would not). Deliberately NOT remapped: $CAC0 (vanilla "indices unstable
> across canonicalize" contract; positional uses exist), $DA14 (consumed
> pre-canonicalize, verified). $C0D8 map: no caller consumes it after
> return (20-line scan below all 22 sites). Then nest-calls the displaced
> $0106 (rst $10 stack-nests; depth 3).
> **Validation:** emitted bytes decoded (sm83dis) + byte-executed in a mini
> SM83 interp: identity, scattered party [4,0,2], displaced-member fixup
> [1,0], post-breeding $CA40 tracking, empty party, mid-battle-join shape
> (pre-join cache untouched) — 21/21. Patched-build byte-diff vs S57
> reference: header checksum + 2 operand bytes + bank $73 only. Compiler
> regression re-pinned `79dd32c5…` (patched), 18/18 `--rom` green.
> **Two doc errors fixed in place (DOC_AUDIT S58):** the canonicalizer tail
> $0106 is `ScanPartySlotTable` (+$29/+$31 sanitizer), NOT "follower art"
> (MONSTER_DATA CF1 + bank_001 comment block, both corrected, byte-perfect);
> canonicalizer call-site count re-verified with generator: 22 sites /
> **7** banks ($04 $0A $12 $15 $18 $50 $51), S56's "8 banks" off by one.
> **Semantic delta (user to veto in test):** farm-menu display order can
> change when the party changes (sort displaces farm records that sat
> below a party member) — cosmetic, order-only.
> **NEW OPEN (ROADMAP CF3 (a2)):** pre-sort saves load a vanilla-layout
> roster; the invariant only appears at the first canonicalize after load —
> force a canonicalize/sort on the load path BEFORE any walker redirect
> assumes slots 3-19 == farm. Harmless in the sort-only build.
> **v2 (2026-07-14) — phantom-monster incident + $CA40 fixup removal:**
> user's first v1 session showed phantom farm monsters (garbage species,
> 0 HP/MP, PAIRED junk names "0012/0095", levels 1→cap) — ONLY in the S57
> in-gate save; unreproducible from any clean save on S57 OR S58 builds
> (user ran full gate loops both ways). SHELVED with hypothesis (recorded as
> hypothesis, KEY_LESSONS S58): fossils of the pre-S55 slot-14/16 collision
> bug class in that save's lineage, surfaced by CF2's drain leveling any
> flag-$01 garbage into visibility (level spread = garbage exp; 0 HP =
> level-ups don't heal). User advised to archive the .sav as evidence, then
> release the phantoms in-game. The investigation DID surface a real v1
> defect: the sort's $CA40 exchange-fixup rewrites the farm drop/pick flow's
> live candidate register ($CA40 is dual-role — S56's "breeding persist" was
> one flow's view; farm UI writes it per selection at $0A:~$5CC4 and feeds
> it to unguarded flag-marking paths). REMOVED in v2; $DA15-17 fixup kept
> (verified battle-only, 2 refs). Drain's nested calls exonerated by
> reading: $13 entry 2 + $51:$5B31 are context-free record math off [$CAC0].
> Interp re-run vs v2 bytes 21/21; compiler re-pinned `d31c9300…` (patched)
> 18/18; PASS 4/4. Breeding window + stale-$C0D8 state-machine reads are
> WATCH ITEMS in the as-built section.
> **v2 RESOLUTION (2026-07-14):** phantom mystery SOLVED — user found the
> repro (enter/exit well custom room = +2 Drakslimes "0095", level 0, all
> zeros) and the byte trace confirmed the S55 accepted hazard's undocumented
> facet: room $6B S1 NPC table byte 3 ($03, the spawn Y) is copied to
> wCustomNPCBuffer+3 = $D37C = SLOT 15's IN-USE FLAG (slot 16's = $D411 =
> exit buffer byte 24); the next canonicalize normalizes the spray into a
> real farm record. The <=14 rule protects real monsters, NOT empty 15/16.
> The S57 gate save's 4 fossils = two rooms' visits + CF2 drain leveling.
> SORT EXONERATED (predicted to repro on S57). USER RULING: hazard
> re-accepted, no interim patch, CF3 relocation retires it (ROADMAP CF3 (d);
> hazard note sharpened in patches/wram.asm). v2 then USER-CONFIRMED: farm
> multi pick/drop, breeding (the $CA40 watch item passes), full gate run +
> boss, party shuffles, save/reset. Battle JOIN not explicitly exercised —
> carry as a residual test item.
> **NEXT:** user test of the S58 **v2** ROM (party swaps at the farm —
> multiple picks/drops in one visit, battle join, breeding, save/load,
> farm-menu order sanity) → then CF3 (a2) + the two redirected walker
> helpers (b), or A′1.
>
> (S57 + earlier blocks moved verbatim to SESSION_HISTORY.md Part 1 — see Session Index.)

---


> Session 57 (2026-07-13 — **CF2: per-battle exp re-bound to party; farm exp
> banked into a persistent accumulator, paid at the map-change commit.**)
> **Implementation (3 patch sites + 1 new bank; MONSTER_DATA "CF2 as built"
> is the owning section):** (1) `wPendingFarmExp` **$D9C8-$D9CA** (24-bit LE,
> clamp $98967F) — carved from the S8-verified clean event-flag block, INSIDE
> the save image ON PURPOSE: in-gate save rooms exist (FAQ), so pending must
> survive save+reload; boot-cleared, new-game-zeroed, pre-CF2 saves load as 0.
> Flag indices **$0168-$017F retired** from the allocator pool in exchange.
> (2) Bank $50 same-size 14-B window at the exp walker head ($61FA):
> `CF2FarmShareDivert` (67 B, tail nops) still runs the vanilla Div24x8To16
> but banks total/16 into pending and ZEROES the per-monster farm share HRAM
> $DB-$DD — the walker's farm branch and the post-battle all-20 level scan
> become farm-inert with zero loop edits. (3) Bank $0B same-size 6-B window at
> RoomEntry0's map-change commit ($4020): `ld hl,$7300 / rst $10` + 2 nop →
> NEW **bank $73** entry 0 `CF2WarpCommitDrain` does the displaced
> wWarpFlag→wInGateworld store, then, when the DESTINATION is non-gate
> (wWarpFlag=0) and pending≠0, pays each eligible farm monster (flag $01, not
> egg +$63, level≠99, level<cap) the full pending and levels it with the
> IDENTICAL silent vanilla pair the post-battle farm scan uses
> ($1300 threshold / $1302 gains / $510d apply — all context-free, only
> [$CAC0]; nested rst $10 = vanilla precedent, bank $50 does it). [$CAC0]
> saved/restored. **Semantic deltas (user to veto in test):** farm
> exp/levels land at the first non-gate transition, not per battle (invisible
> — farm UI is town-only, and vanilla farm level-ups are SILENT: the
> party-list pass gets the display state, the all-20 scan is the $1302+$510d
> pair with no message — code-verified); mid-run storage recruits get the
> FULL run's pending (slightly generous); drain also fires entering in-gate
> special rooms (wWarpFlag=0) — an early payout, semantically safe (vanilla
> paid farm mid-gate every battle).
> **Validation:** emitted bytes decoded at all 3 sites (sm83dis);
> divert+drain byte-executed in a mini SM83 interp (accumulate ×2, clamp at
> 9,999,999, multi-level drain, egg/99/cap/party/empty skips, gate-dest
> passthrough, zero-pending early-out — all pass). Compiler regression
> re-pinned: compat build == the S57 hand-staged patched build md5-equal
> (`6c41f0d8…`, **patched**), 18/18 `--rom` tests green; old reference
> `026970d3…` (patched) historical.
> **⚠ FLAG-POOL DEFECT found + fixed in passing:** EVENT_FLAGS' "broader safe
> ranges" (and `editor2/core/project.py FLAG_SAFE_RANGES`) were script-only
> analysis — per-byte audit vs engine literals + all_scripts.json shows
> $D9CC, $D9D9-$D9E2, $D9E4-$D9E5, $D9E7-$D9E8 are LIVE (engine named vars
> and/or script-referenced). Truly clean persistent flag bytes: **$D9C6-$D9C7
> + $D9D7-$D9D8** (32 flags after the CF2 retirement, not "~200").
> EVENT_FLAGS rewritten in place; FLAG_SAFE_RANGES now
> [(0x0158,0x0167),(0x01E0,0x01EF)]; DOC_AUDIT addendum + KEY_LESSONS S57.
> **USER-CONFIRMED 2026-07-13 (`DWM-S57-CF2-TEST.gbc`):** farm exp up at the
> farm UI after a multi-battle gate run; save in an in-gate save room →
> reload → exit gives the FULL run's exp (persistence proven); party
> level-ups/display unchanged; town walk clean. Semantic deltas above stand
> un-vetoed.
> **NEXT:** CF3 (order: party-first sort first; the open user decisions in
> ROADMAP CF3 must be settled before it starts) or A′1 (mapID ≥$80 audit).

> Session 56 (2026-07-11 — **CF1: the monster-array access map. Byte-neutral;
> deliverables = docs + tool + JSON + source comments only.**)
> **Membership model (the CF1 headline):** party is NOT positional — dual
> representation: per-record in-use flag +$00 (**$00 empty / $01 farm /
> $02 party**, tri-state, what battle trusts) + party order list **$CA8D**
> (count) / **$CA8E-$CA90** (slot indices, $FF empty; battle position cache
> $DA15-$DA17). Synced by the CANONICALIZER `ReadPartySlotInfo` ($01:$46F6,
> entry 5, **22 call sites / 8 banks** — every roster mutation's epilogue):
> flags normalized $01, listed slots re-marked $02, array COMPACTED
> (149-B record swaps toward slot 0; old→new map at $C0D8), list remapped,
> $CA8D recounted. Records MOVE between slots on every canonicalize.
> **Exp (walker $50:$61E2, ONE walk over all 20):** party member =
> total/eligible-count (KO +$4A bit7 excluded; ±1 rounding quirk), farm =
> **total/16 each**; skips eggs (+$63 flag), level 99, level≥cap; total in
> $DD23-25 (RAM-map row solved). Level-ups: party list first, then all-20
> scan `jr_050_6318`. **The party/farm forks are single-site** — CF2 is a
> retarget, not new plumbing.
> **New structures:** EGG flag = record +$63 (set by egg-receive
> $12:jr_012_6c0a + builder sub-cmd $5E); KO bit +$4A.7 (bulk-cleared by
> $01 entry 9); nickname = +$0C ×9 (old "+$14 name" row was its last byte);
> two $FF-terminated ID lists +$29 ×8 / +$31 ×25 (semantics unverified);
> **staging pseudo-slots $14/$15 @ $D665/$D6FA** (GetMonsterDataPtr masks
> $7F): breeding parents (copied+deleted pre-bank-$16; fields read at
> +$0BA4/+$0BA4+$95), link-trade transit (send $15:jr_015_5aa5; receive
> $18:~$4C50 with forced SRAM saves = anti-clone), bank $15 menu scratch.
> $CA40 = offspring first-empty slot persist; $CA42 ×9 = name text scratch.
> Roster mutation paths enumerated (gives $28/$29, egg, battle join
> $51:SetBtlS_63e8, breeding ×2 variants, release $12, trade ×2, sleep $12
> init + $07 scans, compaction) — table in MONSTER_DATA.
> **Deliverables:** MONSTER_DATA "Party/farm boundary semantics + monster-
> array access map" (owning section); `tools/map_monster_walkers.py` +
> `extracted/monster_walkers.json` (**all 44 $CAC0 writers** — the S55
> count's origin: 44 = the `ld [$cac0],a` sites — **+ 60 register/stride
> walkers classified**; self-checking: drift in writer set or labels
> aborts); known_RAM_map rows ($CA40/$CA41/$CA42/$CA8D/$CA8E/$CA91/$CAC0
> tri-state/staging/$DA14/$DA15/$DD23 + record fields); audit_wram curated
> staging entry (gaps 34→31, selftest re-pinned incl. $D78E extent);
> bank_054 header corrected (claimed "EXP distribution entries 0-6" — they
> are the skill-record accessors — and "$CA94 party/storage count" — it is
> the seen-bits array; DOC_AUDIT row added); discovery comments at 17 sites
> across 10 banks (build byte-perfect after).
> **⚠ CF3 design input:** arc premise "party stays hot in slots 0-2" is
> false in vanilla — CF3 needs a party-first sort in the canonicalizer or
> index remapping (user decision pending). The S55 "$15-special release"
> was actually trade/breeding staging.
> **NEXT:** CF2 (exp accumulator + chokepoint drain — fork sites now known)
> or A′1 (mapID ≥$80 audit). T2 / S2f / blink remain parked; `--apply`
> decision from S53 still open. **OPEN USER DECISIONS for CF3** (details
> ROADMAP CF3 S56 amendments): save-persistence semantics of the freed
> range $CBEB-$D664 (it is inside the save image + SavePartyToSRAM copy);
> party-first sort vs index remapping.


> Session 55 (2026-07-10 — WRAM relocation, reduced form; block below moved
> verbatim from PROJECT_STATE by S57 per the aging rule; it was retained
> there without its own header, appended to the S56-era notes):
> **MID-SESSION CRASH POST-MORTEM (user test of the first S55 ROM): hard
> crash on room entry + on scroll after loading an in-room save.** Root
> cause: the old block was initialized by ADDRESS ACCIDENT (inside both the
> boot clear — ClearAllWRAM stops at $DDFF — and the SRAM save image); $DE74
> is inside neither → power-on garbage counters (the S53 crash mechanism,
> resurrected) + wCustomRoomFlag no longer restored on load. Fixes (v2):
> ClearAllWRAM `$1E00`→`$1EE0` (boot zeroes $C000-$DEDF; same-size operand
> edit, single early-boot call site) and flag DERIVED := (wMapID ≥ $6B) every
> movement frame at CopyCustomRoomRecord head (bank $71 template re-pinned
> per §5; TEMPLATE_SIZE 0x71: 103→116). Load-in-room now shows step-0 content
> — expected under transient semantics, not a bug. Full lesson: KEY_LESSONS
> S55 ("vetted-unclaimed is NOT initialized" + "one variable per test ROM" —
> the first S55 ROM wrongly stacked the never-user-tested S53 master-table
> fix under the relocation; v2 delivers COMPAT first).
> **What moved (patches/wram.asm; all refs were label-based → zero patch-bank
> edits; template sha256 pins UNCHANGED):** step counters $D478→**$DE74**
> (compiler region, STEP_COUNTER_BASE + example-project reserved hole
> →0xDE78), wRoomRecScratch→**$DE7B**, wRoomEncFlag $DE83, wTameDelay $DE84,
> wTameBGSave $DE85, wCustomRoomFlag→**$DE88**; $DE89-$DEDD reserved (85 B).
> Regression md5 re-pinned (v2): S55v2 reference patched build
> **`026970d361f6afe03f28e29fa6e631f6`** (compat) / fixed master-table build
> **`fb6a96abd2b045c68234d74fcfcc76b5`** — historical, superseded: S53 pair
> `3a5a514c…`/`f81d4ad8…`; mid-S55 pair `cc62b5…`/`8878ef…` (crashed, no
> init/flag fixes). Test ROMs delivered: **`DWM-S55v2-compat-TEST-FIRST.gbc`**
> (S53-user-tested table config + relocation/fixes — the isolating build)
> and `DWM-S55v2-fixed-master-table.gbc` (adds the S53 table fix) — **both
> user-confirmed working, 2026-07-10**.
> **USER-CONFIRMED 2026-07-10** ("everything now works without issues", both
> S55v2 deliverables): well entry, egg-give exit + scroll-up, save-in-room →
> reload → scroll all work. This ALSO clears the S53 master-table fix's
> test debt (first user run of the fixed-table config). Standing expected
> behaviors: load-in-room shows step-0 content (transient counters); stored
> monsters #15-16 still corrupt on custom-room transitions (≤14 rule). **NPC/exit buffers stayed at $D379-$D477** (inside monster slots
> 14-15): ACCEPTED legacy hazard of the exploration overlay (user decision —
> saves there are disposable); **≤14-occupied rule stands** for custom rooms
> on the hand overlay.
> **Why reduced (S55 vetting — full detail KEY_LESSONS S55 + wram_usage.json
> regen, 51→34 gaps):** the S54 candidates were FALSE gaps — $C200-$C2FF =
> attr decompression staging (every stream declares declen 256), $C300-$C4FF
> = 512-B screen staging unit (bank $06 bulk copy $C500→$C300 ×$0200; both
> blocks SRAM-save-copied — ARCHITECTURE's save table was right, the S54 read
> of it was partial); $DD80-$DE2B = **AUDIO engine** (6 chan × 26 B +
> scalars; known_RAM_map's "INFERRED battle structs" corrected); stack tops
> $DFFF. $DE74-$DEDD was the only vetted block. **Retired alternative:** cap
> monster slots 20→18 (reclaim $D53B-$D664 298 B; $00 in-use pads defuse all
> 44 read-walkers; give scanner `label4_5c14` + full-check `label4_5f67`
> located) — viable but retired as throwaway-path surgery; do NOT re-derive.
> **New canonical discoveries:** farm SLEEP pool = second 20×$95 monster
> array, SRAM-only at $B124-$BCC7 ($CA41 bit7; bank $07 scans it in place —
> vanilla's own cold-storage precedent); SVBK census: five writes total in
> the ROM → **WRAM banks 3-7 = 16 KB virgin** (docs: known_RAM_map); debug
> mode (banks $55/$56/$59) owns ~10 exclusive WRAM bytes (exclusivity scan).
> **Architecture decisions (user, S55):** vanilla rooms KEPT as postgame →
> mapID ≥$80 audit in scope (custom room #22+), vanilla counter pool not
> harvestable; parallel architecture (overlay = exploration, structural fixes
> = compiler pipeline only); **Cold Farm arc** = editor-era WRAM strategy
> (farm→SRAM, party-only exp + accumulator drained at the castle gate-exit
> chokepoint — user-confirmed: all gate exits funnel there, Arena awards no
> exp; ~2.5 KB freed; exp level-scan loop found at bank $50 `jr_050_6318`).
> Full specs: ROADMAP Arc COLD FARM / Arc LAYER A′; EDITOR_DESIGN §1 S55
> amendments.
> (S55 NEXT superseded by S56 — see above.)


> Session 54 (2026-07-08 — **egg-give root cause: custom WRAM sits inside the
> monster array; audit_wram.py ships. Byte-neutral session** — no ROM delta,
> verifier PASS 4/4, clean build byte-perfect `1ca6579…`).
> S53 anomaly (a) CLOSED (user misread the gate; Pillar B works; the "hub exit
> data" suspect statically refuted — room $24 exits step-invariant). S53
> anomaly (b) **ROOT CAUSE (static, runtime probe pending)**: the party/storage
> monster array (party+farm+eggs, ONE 20-slot limit, user-confirmed) spans
> **$CAC1-$D664** via `GetMonsterDataPtr` indexed access — zero literal refs,
> so the Phase-0 grep audit falsely called $D378-$D477 "unclaimed", and ALL 14
> custom WRAM labels ($D378-$D48B: room flag, NPC/exit buffers, 7 step
> counters, wRoomRecScratch, wRoomEncFlag, Tame vars) sit inside monster slots
> 14-16 (third instance of this bug class after $D95E and $D9A0-2).
> Forward corruption (the user's crash): `$FF29` writes a 149-B record into the
> first empty slot; slot 16 lands the 27 resistance bytes on $D479-$D493 =
> bottom-screen step counter (garbage step-entry ptr → dead exit) +
> wRoomRecScratch (garbage tileset/collision record → scroll-up crash).
> Reverse corruption (silent, worse): `CopyCustomRoomRecord` rewrites scratch
> on EVERY room transition since S42; buffer copies spray slots 14-16 →
> stored monsters #15-17 corrupted by normal play, persisted by saving.
> **Interim play rule: keep the array ≤14 occupied around custom rooms; user
> should inspect stored monsters #15-17 for damaged stats/resistances.**
> Confirmation probe: **RUN AND CONFIRMED by user same session.** Recorded
> values for the fix session — before: $D478-$D47E = 00×7, scratch
> `0d 28 a0 00 00 01 30 00`, encFlag 01, $D488+ = 00. After the give:
> $da14=$10 (slot 16); $D478-$D47E = `c8 22 fa 8b c8 22 fa`;
> $D488-$D497 = `ea 8a c8 af ea 8b c8 21 8e c8 34 fa 42 c8 cb 5f`;
> scratch bytes unchanged (per-frame self-heal, see above). Slot 16 = first
> empty ⇒ the user's save has slots 0-15 OCCUPIED ⇒ **monsters #15-#16
> (slots 14-15) are being actively corrupted by every custom-room visit** —
> slot 15's in-use flag ($D37C) is NPC-buffer byte 3; user advised to inspect
> both. The given egg (slot 16) will itself be corrupted by future room
> transitions (scratch/Tame writes land at its +$6E..+$7A). Deliverables: `tools/audit_wram.py` (4 evidence sources;
> gaps reported UNVETTED, never "free"; `--selftest` pins this detection) +
> `extracted/wram_usage.json` (TOOLS_AND_DATA rows added). Relocation
> candidates from the gap list: $C20D-$C2C2 (182 B), $C42B-$C4C3 (153 B),
> $DE74-$DEDD (106 B) — each needs vetting (pointer-walk loops; SVBK bank-2
> windows exist in bank_051/052, so banked WRAM is NOT assumed free). Docs
> corrected in place: ROADMAP facts row (refuted claim + new Phase 0 item),
> known_RAM_map (array end $D664, not $D6B0; seen-bits $CA94-$CAB1 documented;
> collision warning), DOC_AUDIT addendum, KEY_LESSONS S54. Class-C finding:
> new species 224's library bit at $CAB0 is inside the vanilla-scanned extent
> (benign; counts toward the 100-monster library rewards).

---


> Last verified: 2026-07-07 (Session 53 — **Editor headless backend ships:
> `project.json` schema + `tools/build_project.py`; regression machine-verified
> byte-identical.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`.)
> **The compiler (`editor2/` package + `tools/build_project.py`) compiles a semantic
> `project.json` into the proven patch overlay.** It owns `bank_060.asm` +
> `bank_071.asm` whole-file (verbatim, sha256-pinned engine template heads +
> generated data) and three byte-neutral `@BUILD_PROJECT` regions
> (`bank_017.asm` ×2: `room_palettes_a`/`room_render_tables`; `wram.asm` ×1:
> `wram_step_counters` — markers added S53, neutrality proven by integrity PASS).
> Pipeline: content-validate → emit ×2 (determinism enforced) → bank-accounting
> BEFORE rgbasm (pinned template sizes: `$60`=283 B @`$411B`, `$71`=103 B
> @`$4067`, from the reference `game.sym`) → splice regions → stage/`make`/
> restore (PATCH_FILES lists parsed from verify_integrity.py — one source of
> truth) → `build/manifest.json` (+`game.sym`) mapping every text/script/
> step-counter/flag to `bank:addr` for the SameBoy debug loop. KEY_LESSONS
> rules are compiler VALIDATIONS (spawn script 0; screen_byte required, never
> guessed; text terminators + bare-`$EE`; 8×4 palettes + forced-idx1/idx3
> warnings; dense mapID/text tables; flag safe-pool allocator; wram region cap
> keeping `wRoomRecScratch`@`$D47F`). 18/18 tests
> (`editor2/tests/test_compiler.py --rom`).
> **Proof 1 — regression:** `editor2/example-project/project.json` re-expresses
> ALL user-confirmed content (6 rooms `$6B–$70`, 21 texts, 10 scripts, 4
> palettes, records/enc rows, 7 step counters — auto-allocation reproduces the
> hand addresses incl. the `$D47C` legacy hole via a `reserved` entry); the
> generated patched ROM md5 **`3a5a514c65b330e2788170c5d409b960`** equals the
> S53 reference patched build — byte-identical.
> **Proof 2 + defect fixed by construction (built S53, NOT yet user-tested):**
> the hand `CustomScriptMasterTable` had 3 entries but rooms reach index 5; on
> the SCROLL path a room past the table overshoots into following data —
> benign today ONLY because `$70` is single-screen (cannot scroll). Compiler
> default emits the full-width master table + shared `CustomScriptNoop`
> (+10 B); `build.compat.master_table_rooms` reproduces the legacy bytes
> (compile-time warning). Fixed patched ROM `f81d4ad84ee52f4c3342cc1f7e261e58`;
> measured delta vs reference = bank `$60` `$4010–$45B8` (+ the 2 header
> checksum bytes) ONLY; `$60` usage 1455→1465 B. Test ROM delivered
> (`DWM-S53-compiler-fixed-master-table.gbc`).
> **Script routing documented (resolves S11 "room-entry script unreliable at
> initial entry"; engine UNMODIFIED, grep-verified):** scroll/post-battle path
> (bank `$06` `$66e3`, patches/bank_006.asm ~4931) sets `wScriptMapType` = raw
> `wMapID` → `MapTypeDispatch` ≥`$40` → `DispatchBank0F_Ext` →
> `GateAwareDispatch` → `CustomScriptRead` — the path that reaches bank-`$60`
> scripts. Initial-entry path (bank `$01` `$4C3E`, ~line 2478) clamps via
> `MapIDClampForPalette` → post-S42 `$00` for ALL custom rooms → CASTLE scr0
> runs at initial entry (benign: flag/var-guarded; the "`$16` for custom
> rooms" comment at that site is stale). Full write-up: PROJECT_COMPILER.md §7.
> **Tool defect logged, NOT fixed:** `tools/compile_script.py` declares
> `set_bgm` (`$41`) = 2 params; the handler `$04:$669D` consumes ONE (the
> user-confirmed hand script uses one). Fix later together with
> decompile_script.py's independent PARAM_COUNTS + round-trip re-test
> (PROJECT_COMPILER.md §8).
> New reference doc (user-sanctioned, like GATE_GENERATION precedent):
> **PROJECT_COMPILER.md** — schema, pipeline, regions, template pinning,
> insertion recipes for future skills/music emitters, S53 findings.
> **User test result (S53, same day):** demo loop CONFIRMED on the fixed ROM —
> $6B render/NPCs/jerky, scroll, encounters, $6C dusk + teleports + step demo,
> $70 ember + encounters, save. TWO anomalies, BOTH classified NOT-S53 by
> byte evidence (identical in reference + fixed builds):
> (a) **Gate of Villager shows 4 vanilla floors** (Pillar B $6D absent) —
> bank_016 unchanged since the S41 commit; fork machine code verified byte-equal
> in BOTH built ROMs at $16:$5BA9→$7CB9. Fresh-entry contract is
> `wGateID := wMapID` (pedestal pseudo-id) at `$16:$5B67` when wInGateworld
> bit7 clear. **CLOSED S54 — user misread which gate; Pillar B $6D + descent
> music + Dran boss all work as designed.** The recorded suspect
> ("story-step-dependent hub exit data") was ALSO statically refuted in S54:
> room $24's four step variants carry byte-identical exits (pedestal (2,2) →
> dest 1 / gate_flag 1 in every step; steps only toggle the sprite-77 pedestal
> objects). Do not chase it again.
> (b) **SkyDragon-egg give ($6B bottom screen) then scroll up → crash** —
> unknown vintage per user. Not plausibly S53 (the fix's measured delta doesn't
> touch the path). **A/B CONFIRMED (user, S53): reproduces on the reference
> build too → PRE-EXISTING, not S53.** **ROOT CAUSE FOUND S54 (static; runtime
> probe pending)** — see the S54 block below: the custom WRAM block sits inside
> the party/storage monster array; the give's 149-byte record lands on the live
> room state. The earlier follower-loader suspect list is dead (the egg goes to
> storage, party untouched; family byte written correctly from the bank-$03
> info loader). **RUNTIME-CONFIRMED (user probe, same session): `$da14=$10` —
> the give picked slot 16 exactly as predicted; step counters clobbered
> ($D478=$c8 → scroll-up crash via garbage screen-0 step-entry ptr;
> $D479=$22 → dead bottom exit; $D488-$D497 garbage) while wRoomRecScratch
> read back UNCHANGED — it self-heals (the ROM0 collision-threshold reader
> re-populates it via bank $71 entry 0 per movement/frame), so the crash
> vector is the counters, not the scratch. Fix NOT built yet — next session.**
> Demo rooms are THROWAWAY per user (real romhack starts from a fresh
> project.json); both anomalies matter as MECHANISMS ($29 give, Pillar B),
> not as content.
> **NEXT (updated S54):** the WRAM relocation (ROADMAP Phase 0, full spec
> there) is now the gating item before ANY new custom state or bigger romhack
> content — it touches the compiler-owned wram region + pinned scratch, so it
> is its own session with the PROJECT_COMPILER §5 re-pin cascade. After that:
> `--apply` decision (compiler sign-off GIVEN S53), then Phase 2 follow-ons
> (Encounters #2, Layer A extraction, dialogue DTE, set_flag-by-name) — or
> resume S2f / T2 / the blink.
>

> Last verified: 2026-07-06 (Session 52 — **Tame Stage 2 ships: 3-tier skill-evolve chain,
> natural-learn fork, real MP costs.** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`. **Tame $E1 / TameMore $E2 / TameMost $E3** are a working upgrade chain,
> level-up learn + upgrade-replace **user-confirmed in SameBoy** (v34: "levelled up
> perfectly, message correct"). New systems (all label-based, byte-neutral splices):
> (1) **learn-chain fork** — the natural-learn scanner (bank `$06` entry 5 `$4f9a`,
> caller `$51` level-up) loops ids `0..$D9`; `LearnLoopFork` (3-byte splice at `$5088`)
> continues the SAME loop over `CustomLearnReqTable` (`$E1..$E3`, vanilla 18-byte format,
> prereq chain = vanilla EVOLVE/replace path) in the `$7F1E` free run — `Jump_006_7f7f`
> and `db $06 @ $7FFF` offsets preserved. (2) **MP fork** — ALL THREE `$570C` readers
> (display `$56E8` / afford / deduct) route through `MPPtrFromId` → `CustomMPCostTable`
> (0/0/0/10/30/50 for `$DE..$E3`); record `+4` mirrors match. Custom ids no longer read
> garbage MP. (3) **announce fork** — the vanilla announce table's tail physically
> overlaps CODE at `$58:$58E8` (byte for id `$E2` IS an opcode), so `AnnounceIdxFork`
> (9-byte window at `jr_058_57e6`) reads `CustomAnnounceTable` for ids ≥`$E2`;
> `DataBtlFX_7959` offset preserved. (4) **crank reverted** — `SkillTame` meter add is
> now `TameMeterTable` dw 10/100/400 (= FeedMeat/PorkChop/Sirloin meat record powers,
> NOT "$000A = Beef Jerky" as previously documented — BeefJerky is +30; DOC_AUDIT S52).
> The "$0640 mirrors in bank_052" claim was FALSE — those are the vanilla meter CAP
> (present in the clean tree); the only crank was one line in bank_072. (5) **upgrade
> message page-split** — `MiscTextPtrTable[3]` repointed to `MiscText_03_Paged`
> ("[Mon]'s [Old]" / page / "becomes"+NL+"[New]!"), fixing the orphaned "!" (vanilla
> defect for 8+-char names). Built S52, NOT yet user-confirmed. (6) MP charging
> (10/30/50) + tier meter values: built S52, NOT yet user-tested. Harness wild-Slime
> (bank `$14`) KEPT per user (revert at editor time); natural-to-Slime slot DE-SCOPED
> by user (editor lays real data; the fork makes any species slot work). (7) **Enemy
> hit-blink mechanism SOLVED via HW captures but implementation DEFERRED** (user:
> "bank it"): the battle enemy is **BG-drawn** (NOT OBJ — §11.7's old OAM premise was
> wrong; three prior fix attempts targeted layers the enemy doesn't use). The blink =
> tilemap toggle, bank `$5f` entry 5, `$da83` phase → `$da84` sub-dispatch `$4b99`
> (blank `$4ba5` / enemy `$4bcb`, sources via `$50f4`+`$50ff`/`$5109`, VRAM-safe copy
> `$4e1f`, divider `$da34`, done-flag `$da82`). Full map: BATTLE_SKILL_SYSTEM §11.7.
> An interim whole-screen BGP flash was built, user-rejected (that's the PLAYER-hit
> visual), REVERTED — the S50 no-op OBP flicker was removed with it (hook is now
> sound-only during the delay; `wTameBGSave` reserved, unused).
> **NEXT:** S2f (field-cast skill) or more §13.4 skills, or the blink implementation
> (mechanism fully mapped — drive `$5f` entry 5's blink phase from `TameGateHook`
> via `$da82/$da83/$da84/$da34` state injection), or T2 text roll-out.
>


### Session 51 (archived from PROJECT_STATE by S53, verbatim)

> Last verified: 2026-07-02 (Session 51 — **Repo/doc consolidation audit + skill-table
> rename.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Doc-layer session:
> no functional ROM change.)
> **S51 — the status layer is restructured for context cost; contradictions fixed.**
> (1) **PROJECT_STATE compressed** (~1,071 → ~330 lines): session blocks S11–S48 moved
> verbatim to the new cold archive `SESSION_HISTORY.md`; a one-line Session Index (below)
> replaces them; resolved doc-defects moved there too. Aging rule added to
> SESSION_PROTOCOL §3 (keep latest 2 blocks; move the oldest on each new session).
> (2) **ROADMAP compressed** (~1,176 → ~490 lines): every [x] item reduced to
> evidence + owning-doc pointer; cut narratives preserved verbatim in SESSION_HISTORY
> Part 3. New boxes added: **Tame Stage 2 / skill evolve** (⚠️ the S50 TEST CRANK
> `$0640` is LIVE in `patches/bank_072.asm`+`bank_052.asm` — one Tame cast maxes the
> [S52 correction: FALSE re bank_052 — its two `$0640`s are the VANILLA meter cap,
> present in the clean tree; the only crank was one line in bank_072. Crank reverted S52.]
> meat meter; revert to `$000A` is part of that box), G3 schema fold (was prose-only),
> MP/learn-table `dw`/`db` re-section, §13.4 skill follow-ups, skills.json retirement,
> TOOLS_AND_DATA upkeep. (3) **Contradictions fixed in place:** empty-bank counts
> unified (canonical Bank Allocation table below); script-count bases reconciled
> (518 = bank $0C–$0F label census; 732 = (map_type, script) entries in
> all_scripts.json — map types share banks); ROADMAP flag counts updated to the
> branch-following numbers (328/298); SESSION_PROTOCOL stale `documentation/reference/`
> path fixed (layout stays FLAT — the old "target structure" is dropped, user decision);
> DATA_STRUCTURES related-docs table fixed (FIRST_5MIN_TRACE → ROUTING appendix;
> known_ROM_map.md removed); BREEDING_SYSTEM "NOT yet built" header fixed (B1–B7 built);
> TOOLS_AND_DATA refreshed (103 tools / 56 JSONs; ~13 tools + ~10 JSONs added to the
> manifest; header counts fixed); README patched-build cleanup line fixed (8 new-bank
> files, not just bank_060). (4) **Rename executed (was deferred S44):**
> `TilesetLookupTable` → **`SkillMPCostTable`** and `LoadFld_56e8` → **`GetSkillMPCost`**
> in `disassembly/bank_007.asm` + `patches/bank_007.asm` (labels/comments only; clean
> build byte-perfect; role confirmed live by S48's 3-reader map + S49 MagicBurn MP path).
> (5) **Same session, user-approved follow-on:** housekeeping deletions EXECUTED —
> actually deleted: `__pycache__/`, 8× `.DS_Store`, `breeding_extra_recipes.json`
> (all tracked at HEAD → git-recoverable; the recipes file was a B3 capacity TEST
> fixture, facts archived in SESSION_HISTORY). THREE queue rows were stale:
> `monsters.json`, `event_flags.json`, `edits.json` were already absent
> (untracked at HEAD — never in a fresh clone). `--emit-relocation` marked
> legacy/absence-tolerant. (6) **Both skill tables
> RE-SECTIONED to real data** in BOTH trees via the new
> `tools/resection_skill_tables.py` (probe-build method): `SkillMPCostTable` →
> 222×`dw` with per-skill name/MP comments; `SkillLearnReqTable` → 222×18B `db`
> with decoded stat/prereq comments; 4,293 fake-instruction lines → 676 real ones;
> two fake-decode artifact labels kept at exact offsets (`DispMapS_566b`,
> `label6_6034` — referenced from not-yet-re-sectioned bank-$06 regions). Clean
> build byte-perfect; verifier PASS 4/4. (7) Phase-D STALE BOXES verified + ticked:
> banks $03/$14/$16 were already labeled `db`. Toolchain incident, honestly
> recorded: S51 **violated the pre-existing four-doc "never `make clean`" rule**
> (README ×2, PROJECT_STATE Iron Rule 3, SESSION_PROTOCOL, KEY_LESSONS — the
> SECOND recorded violation; the KEY_LESSONS canonical entry now logs both) and
> initially misreported the rule as nonexistent until the user pushed back —
> grep the docs before making claims about the docs. Sibling hazard also hit:
> **broad `git checkout -- disassembly/`** reverts uncommitted label work.
> STRUCTURALLY FIXED: Makefile `clean` no longer
> deletes gfx, the `%.2bpp: %.png` trap rules are removed (17/18 committed .2bpp
> are NOT PNG-regenerable — measured), `disassembly/gfx/README.md` added.
> (8) `--check` caught a tool defect (the SkillLearnReqTable label line was
> emitted missing — a silent str.replace no-op in the tool build); label inserted
> in both trees + the `ld hl, $50e0` loader relabeled to `ld hl,
> SkillLearnReqTable` (byte-identical), tool fixed with an assert.
> **NEXT:** Tame Stage 2 (crank revert + 3 tiers + natural-to-Slime) as its own session,
> or S2f (field-cast skill), or T2 text roll-out. Housekeeping deletions (`__pycache__/`,
> 8× `.DS_Store`, Tier-L JSONs, `breeding_extra_recipes.json`) queued pending user OK.

---

### Session 50 (archived from PROJECT_STATE by S52, verbatim)

> Last verified: 2026-06-30 (Session 50 — **S2e: custom skill #2 (Tame) ships; the
> custom-message + presentation-timing infra generalizes.** Integrity PASS 4/4, clean build
> byte-perfect `1ca6579…`. **Tame (`$E1`)** — recruit (meat-meter) + anti-abuse damage
> (ATK/4), single-target — is user-confirmed in SameBoy: announce "used Tame!", heart
> animation, damage sound + "takes X damage" text correctly SEQUENCED after the heart, damage,
> and recruitment all correct. New infra this session: (1) **custom-message render fork** —
> `$FD` is now a general escape resolving a per-skill pool string by `[$db8a]-$DE`
> (`LoadB4c_Fork`), so bespoke text no longer needs a scarce free id (MagicBurn migrated onto
> it); (2) **presentation timing** — the effect state machine's per-id animation-wait gate
> (`$53:$5b07`) + a fixed frame delay (`wTameDelay`) sequences a note-then-hit skill, and the
> damage sound is moved off the note onto the text. Full RE: `BATTLE_SKILL_SYSTEM.md` §13.5 +
> §11.7; TEXT_SYSTEM.md (fork); KEY_LESSONS.md (Session 50). KNOWN DEFECT (deferred, minor
> cosmetic): the per-enemy-sprite blink is unsolved (not `wBGPalette`/whole-screen, not
> OBP-only — an OAM visibility toggle not yet found; §11.7). Meter is TEST-cranked (`$0640`);
> revert to `$000A` for Stage 2.
>
> [S49 context] Session 49 — **S2d: custom skill #1 ships end-to-end.**
> Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. **MagicBurn (`$E0`)** is a
> non-aliased custom skill, user-confirmed working in SameBoy: own record (½ current MP →
> all foes) + result text + **announcement** + **animation** + **hit-flash** + **cast
> sound**, all via clean dynamic indirection, zero per-aspect hacks. New this session:
> (1) **announce** — `AnnounceTemplateTable` (`$58:$5806`, lookup `$58` e6 `$57C5`, render
> `$50:$5A42`; `$FF`=silent) re-disassembled to a clean `db` table in patches with `$E0`'s
> slot filled; (2) **custom message pool** — the 256-id battle-message table is FULL (one
> free slot `$FD`), so bespoke text lives at `$4c:$7326` (`CustomMsg_E0_MagicBurn`, `$FD`
> repointed); (3) **presentation proxy** — `GetPresentId` in `$5f` free space (identity for
> stock ids, per-skill PROXY for custom ids via `CustomProxyTable`) forked into the 12 `$5f`
> reads of `$db8a` (byte-neutral); renderers `$5c/$5d/$5e` read the id zero times, so a custom
> skill borrows a real skill's whole anim script → no hang, flash + SFX restored (MagicBurn
> proxies Infernos `$09`). Full RE + per-skill recipe: **`BATTLE_SKILL_SYSTEM.md` §13**;
> TEXT_SYSTEM.md (pool); KEY_LESSONS.md (3 lessons). The standalone presentation-groundwork
> doc was folded into §13 and deleted.
> **NEXT:** Tame Stage 2 — revert meter crank `$0640`→`$000A`; 3 upgrade tiers (learn-chain
> fork, bank $06); make Tame natural to Slime (a `$03:$4461` slot). Then S2f (field-cast skill,
> e.g. teleport) / more custom skills via the §13.4 recipe. Optional polish: the per-enemy
> blink (§11.7).


> Prior (Session 48 — **S2d FOUNDATION: skill-id bucketing audit.**
> Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral (disassembly
> comments + tooling; no byte change, no ROM/patch). Built the missing prerequisite for
> the "proper" S2d that S45 deliberately skipped: a complete map of where the battle
> engine buckets the working skill id (`$db8a`, **254 reads / 9 banks**, 148 in enemy AI
> `$57`). **Result — the surface reduces to a small, verified fork set:** 204 reads are
> equality checks (max `$C5`, so a custom id `≥ $DE` matches none = auto-safe), the 15
> range gates are windowed ladders that fall through to defaults, and the exhaustive `$57`
> AI pass (all 148) finds **zero** sites mishandling a custom id (its high-id sub-dispatch
> is guarded by `cp $d9; ret nc`). **Keystone:** magnitude/targeting/MP-in-record/status/
> ai_weight all come from INDEXING the record table `$54:$4013` by the id (3 indexer sites
> `$5251/$5276/$529E`), which overshoots at `≥ $DE`; one record fork fixes all of them and
> the enemy AI (shared reader). HW-confirmed (SameBoy): `$52:$66D9` writes `$db4c=$db8a`
> (Scorching `$5E`); the `$54:$535F` divert is a MINOR path (didn't fire for Scorch/Zap/
> IceStorm); menu Flee ≠ skill `$DB`. **Keystone fork PROVEN byte-neutrally implementable:**
> the 3 sites are identical 5-byte windows (`21 13 40 09 09`), no interior jump-ins, bank
> `$54` has ~10550 free in-bank bytes; an RGBDS-assembled `call Fork`+nop+nop trampoline
> executes vanilla-identical for normal ids and indexes a high table for custom ids. Other
> forks: MP (3 readers `$07:$56E8/$5A98/$5B4E`, mirror `record+4`), sound (`$55:$4067`,
> `$FF`=silence), name (repoint), anim (none for a no-visual skill — `$58dd[$DE]=$0d`).
> Full RE: **`BATTLE_SKILL_SYSTEM.md` §12**; tool `tools/map_skill_id_buckets.py` →
> `extracted/skill_id_bucket_map.json` (self-checking).
> **NEXT:** S2d implementation — fork the 3 record sites + in-bank high tables, MP, sound,
> name; prove a non-aliased ally heal (own record/handler/name). Shovel-ready per §12.6.
>
> Prior (Session 47 — **S2c: effect-script format / animation
> dispatch RE.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral
> (discovery + tooling; no `disassembly/` or ROM change). Resolves the S46 OPEN item.
> **Finding (corrects the prior model):** bank `$4c` is **not** a novel effect-bytecode
> interpreter — it is the shared **text/message VM**. The `$dd70/71` "script pointer"
> is a **packed pair of 8-bit message ids**: low = the "effect happens" message
> (damage/status/heal), high = the "effect fails" message (miss/resist). The battle
> effect player (`bank_053 jr_053_5a6f`, a frame-stepped state machine) hands a small
> mode (0/1) + the chosen id byte to bank `$4c` e0 (`LoadB4c_42d1`), which runs
> `CallTextEngine`/`SaveBankAndSwitch` to resolve the string via the **mode-0 two-level
> table at `$4c:$4019`** (`subtable=[$4c:$4009+mode*2]`, `string=[subtable+id*2]`).
> Effect "scripts" are standard `$F0`-terminated text-VM strings (DTE + control codes;
> `$F9 <slot>` = insert name/number). The on-screen **visual** is a SEPARATE system keyed
> by **skill id**: bank `$5f` e6 (`$52F0`) → per-skill anim-index (`$5f:$58dd/$59c3/$5aa9`)
> → routine table `$5f:$58bd`; **sound** = bank `$55` e1 → SFX table `$55:$4070`. So
> Blaze/Firebal/IceBolt share selector `$b882` yet differ visually. **Accept met +
> validated:** Blaze decoded to bytes — hit `$4c:529f` "{mon}{name} takes {num} damage pts!",
> miss `$4c:5871` "Has no effect on {name}!"; and `--validate` cross-checks decoded messages
> against the categorized FAQ (`extracted/skill_faq.json`, user-provided) — **67/67**
> statically-resolved skills match, 0 contradictions (≈81 real skills incl. the `$b682`
> physical-attack default). **S2c-anim — RENDERER REVERSED + EMULATOR-VERIFIED (2026-06-28):**
> the `$dd68` consumer is a **metasprite/OAM engine** (same 4-byte `dy,dx,tile,attr` $80-term
> format as the follower system). Full chain SameBoy-verified: skill id → `$5f:$52F0` →
> side-select `$5f:$58dd/$59c3/$5aa9` → routine dispatch `$5f:$5441` → table `$5f:$58bd`
> (index `$0d`=`ret`=NO VISUAL) → `$dd68` → builders `$5c:$40fc`/`$5d:$4122`/`$5e:$413a`
> (de=`$4071`, `[$c7]`anim/`[$c8]`frame). **3 presentation layers:** sprite-anim,
> sound+flash (`$56ed/$57d5`→`$da81`), vertical screen-shake (`$5f:$4c0c`, SCY via
> `$da84`/`$bb`). Corrects two prior mislabels (`$c8a8`=input-lock not shake; `$c8b1`
> dormant). *Reusing* an animation on a new id = table edit; *authoring a novel* one = add
> metasprite frames + a `$4071`-table entry (now fully specified). See **§11**. Tool:
> `decode_battle_animations.py` → `extracted/battle_animations.json` (45 anims/~600 frames).
> **Tool:** `tools/decode_effect_messages.py` (`--selftest`, `--validate`) →
> `extracted/effect_messages.json` (222 skills → selector → hit/miss messages, full 203-id
> mode-0 corpus, Blaze byte dump; honest classification of `a:a` flag-params, RAM-ptr loads,
> and dynamic builders as non-static). Full RE: **`BATTLE_SKILL_SYSTEM.md` §9 + §11**.
> S47's "NEXT" was S2d's foundation, which S48 (above) then built.)
>
> Last verified: 2026-06-28 (Session 46 — **Phase F / S2-arc: skill PRESENTATION
> foundation decoded + record-table round-trip keystone + re-section.** Integrity
> PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral (discovery +
> annotation + tooling); no functional ROM. NOT yet user-tested — handoff for a
> fresh instance to continue.)
> **S46 — S2 was NOT done; it is an ARC.** S45 shipped a single-caster,
> Blaze-shaped alias POC (correct but narrow). Audited S45 byte-for-byte: built
> correctly, no false claims; the error was marking S2 "done". This session
> decoded the skill **presentation** layer that the alias hack worked around.
> **Core architecture proven:** handler (`$52:$4011`) = effect TYPE (shared:
> Blaze/Blazemore/Blazemost → one handler `$41CD`); the per-skill **record**
> (`$54`) = parameters. **(a) Record table fully decoded + round-tripped:**
> `$54:$4013` pointer entries (dispatch entries 9–230) = `$41CF + id*19`, 222 × 19B
> data at `$41CF`. `build_skill_tables.py` now re-emits the pointer table + data
> **byte-identical** (`--selftest` 5/5 PASS); the 4218-byte block is **re-sectioned
> to clean `db` records** in `bank_054.asm` (editable in source). Field map (FAQ-
> validated PROVEN: +0 effect_class, +1 effect_category, +2 target_mode, +3
> **ai_weight** (per-skill AI score summed by enemy AI `$57`), +4 mp_cost, +5
> status_id, +6 damage_class, +11/+13/+15/+17 power min/range party/enemy — 31/32
> FAQ damage-heal ranges exact). **(b) Item-effect/meat system (#3):** the 37
> item_effect skills (ids 176–212) are the in-battle items; shared handler
> `$52:$4625` (record-driven); meat items (194–198) special-case via `$52:$4014`
> → recruitment handler `$58:$591E`. **(c) Animation dispatch (#2):** handler picks
> a descriptor-setter (`$52:$5460–$54f8`) → `$dd6f` (bit7=has-effect) + `$dd70`
> script pointer (Blaze=`$b882`) → bank `$4c` effect engine + `$55` sprite anim;
> pointer space `$b6xx–$bcxx` (`$b682` default). **OPEN:** effect-script bytecode
> FORMAT + `$b000` backing not reversed = the animation-authoring sub-item.
> **Tools:** `gen_skill_records.py` (+battle_record 7th source), `build_skill_tables.py`
> (+record round-trip, `--emit record/recordptr`). Annotation comment/label-only in
> `bank_052/053/054/058.asm` (clean build stays `1ca6579…`). Full RE + field tables
> + confidence: **`BATTLE_SKILL_SYSTEM.md` §7–§10.** **NEXT for the new instance:**
> either (1) reverse the effect-script bytecode (animation authoring, bank `$4c`),
> or (2) the real authoring step — proper per-id custom-skill records (own record +
> handler + name) that REPLACE the S45 alias hack, enabling heal/Tame/Anchor shapes.
>
 Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`. Functional change (rename) **user-confirmed in SameBoy: skill 215
> displays "BugCut".**)
> **S44 — the skill subsystem is now data-complete for an editor.** Audited the
> reshaped S1 and found it was already partly done (bank `$52` `SkillFunctionTable`
> was re-sectioned with named handlers); the real work was the *data* tables.
> **Two undocumented tables fully decoded and FAQ-validated:**
> **(a) `SkillMPCostTable` `$07:$570C`** — 222 × u16 LE = MP cost to cast (`999`=ALL,
> ids 50/102). The disassembly **mislabels this region `TilesetLookupTable`**; the
> indexing fn `$56E8` is effectively `GetSkillMPCost` (its id-`$70`/Ahhh special case,
> gated on `[$cacc]&1`, picks Ahhh's male/female MP 1/2). Renamed **only in comments**
> pending SameBoy confirmation of the fn's callers. **(b) `SkillLearnReqTable`
> `$06:$50E0`** — 222 × 18B: `+0` level u8; `+1` hp `+3` mp `+5` atk `+7` def `+9` agl
> `+11` int (u16 LE); `+13..17` up to 5 prereq skill ids (`$FF`=none). Validated vs the
> FAQ incl. MegaMagic's 5 prereqs. **BugCut finding:** id 215 (ROM name "Sheldodge", a
> placeholder) is the **Bug-family cut** — proven 3 ways: family sub `$6349` tests family
> code `$05`=Bug; StubBird's enemy list uses 215; its learn reqs match the FAQ's "BugBlow"
> row exactly. Renamed to **"BugCut"** in `patches/bank_041.asm` (10-byte slot preserved;
> **user-confirmed in SameBoy**). **Real skill count is 222 (`$00–$DD`), not 256:** the
> 222 entries classify as **155 skill / 37 item_effect (`$B0–$D4`) / 30 internal**, by
> cross-referencing monster natural sets + enemy lists. Corrected the bank `$52` header
> (`$4211`→`$6CC7` dispatch, `256`→`222`, `140`→`115` handlers). **Tools (NEW):**
> `gen_skill_records.py` → `extracted/skill_records.json` (222 records: name, kind, mp,
> handler+shared group, learn block, prereqs, family code, monster/enemy usage; `_generator`
> key, all 6 source addrs); `build_skill_tables.py --selftest` proves the JSON re-emits the
> function/MP/learn tables **byte-identical** (444+444+3996 B, PASS). Annotation is
> comment-only in `disassembly/bank_006/007/052.asm` (clean build stays `1ca6579…`).
> Test ROMs: `DWM-BugCut-test.gbc` (full stack + rename), `DWM-BugCut-vanillaVillager.gbc`
> (villager fork reverted so wild Picky is catchable — throwaway; project keeps the gate mod).
> **Follow-ups:** confirm the `TilesetLookupTable`/`$56E8` role in SameBoy, then rename +
> re-section both tables to real `dw`/`db` blocks; retire the old 256-entry `skills.json`
> (still read by `gen_name_tables_db.py`). Next item: **authoring NEW skills** (data side is
> ready; novel effects need a new handler in a free bank = the ASM frontier).
>
> Last verified: 2026-06-26 (Session 43 — **disassembly gap audit + Arc-1/T1 text
> re-section keystone (bank `$47`).** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`; T1 is byte-neutral so there is no test ROM — acceptance is the MD5.)
> **S43 — two things.** (1) **Disassembly audit** (user-requested): characterized what is
> entirely un-understood or misassembled. Three gaps were *understated* in docs and are now
> first-class: **(a) audio** — engine partly in bank `$08` (`LoadAudP`, the SGB path; switches
> to `$78`) + scattered `Aud_`/`SoundEffect` routines, barely annotated; song/SFX **data**
> in banks `$61 $62 $63 $65 $66 $68 $78 $7b $7d` (~9 banks/144 KB) misassembled as
> instructions, reached only as DATA (nothing executes them) — format unreversed; **(b) battle
> engine** — bank `$52` holds the labeled `SkillFunctionTable`/dispatch but the 140 skill-effect
> handlers + `Battle*` funcs (banks `$52-$5f`) are auto-labeled only; the **damage formula, turn
> order, and enemy AI selection** are untraced (the `ai_weights` are extracted as DATA but the
> consuming algorithm is unlocated); **(c) vanilla text `$42-$4B,$4E`** — fully tool-extractable
> but **misassembled as fake instructions in source** (~12k bogus lines/bank), so vanilla text
> isn't editable in place. (Phase E's E1/E2 confirmed as genuine, already-flagged gaps.) The full
> attack plan is mapped in **ROADMAP Phase F** (Arc 1 text, Arc 2 skills+AI, Arc 3 music) —
> session-sized items, keystone-first methodology, with S3/M1 flagged as real RE.
> (2) **Arc-1/T1 DONE (byte-perfect):** new `tools/resection_text_bank.py` converts a corpus
> bank's contiguous DTE string run into `TextStr_<bank>_<addr>:` + `db` blocks (one label per
> text id, decoded text in a comment), labels/comments only. Region is data-driven (first string
> addr from `text_id_map.json`; end = bank trailing-fill scan) and snapped to real line
> boundaries via a probe-build line→address map (same machinery as `resection_library_tables.py`)
> so no fake instruction is split; exact ROM bytes are emitted as `db`, so a wrong split fails
> the build instantly. **Bank `$47`: 69 strings, run `$4174-$5b74`, 5607 fake lines replaced;
> clean build stays `1ca6579…`, integrity PASS 4/4.** Idempotent, re-runnable from clean tree.
> Docs updated in place: TEXT_SYSTEM.md "Source re-section" (method + per-bank bounds table),
> ROADMAP Phase F (Arc plan, T1 ticked), TOOLS_AND_DATA (tool). Files: `disassembly/bank_047.asm`
> (re-sectioned — clean tree, zero byte impact), `tools/resection_text_bank.py` (NEW).
> `APPLY_THESE_CHANGES.md` regenerated.
>
> Last verified: 2026-06-26 (Session 42 — **Phase 2 keystone: table-driven custom-room
> dispatch COMPLETE & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`;
> test ROM `DWM-S42-custom-room-keystone-v3.gbc`, **user-confirmed: 3-room walk loop with
> visible staircase exits, amber `$70` renders past the old ceiling with working encounters +
> exit, green `$6D` gate rotation → boss still works.**)
> **S42 — the editor-backend keystone (EDITOR_DESIGN §2) is built.** All remaining hardcoded
> per-room intercepts are now table-driven, and the old `$6B-$6F` room ceiling is lifted to
> editor scale. **Architecture:** dispatch *logic + data* live in the previously-empty bank
> **`$71`** (reached via `rst $10`), so every in-bank edit is a **byte-neutral** stub — no
> scarce/fragmented ROM0 or bank-`$0B` free space consumed, and no risk to dense code/audio
> banks. (1) **Encounters #1 folded in:** `RoomEncTable` (bank `$71`, 3 B/room
> `[enabled,gate,floor]`, indexed `mapID−$6B`) via `CustomEncResolve` (bank `$71` e1) replaces
> the hardcoded `cp $6B` whitelist in `$0B`; `$6B` keeps gate-0/floor-1 exactly. (2) **`$26DD`
> ceiling lifted:** `Custom26DDTable` (bank `$71`, 8 B/room, indexed `mapID−$70`) via
> `CopyCustomRoomRecord` (bank `$71` e0) far-copies the tileset/dims/threshold record into
> `wRoomRecScratch` ($D47F). All three consumers (both `$0B` GFX loaders + the ROM0 collision
> threshold reader) read scratch; for `mapID<$70` the routine replicates the original
> `$26DD/$2A5D` index byte-for-byte (vanilla + `$6B-$6F` unchanged). Threshold site preserves
> `C` with `push bc`/`pop bc` around `rst $10`. This sidesteps the in-ROM0 `$70`↔`$2A5D`
> gate-table collision. (3) **Render tables** (`CustomRoomPalPtr`/`CustomRoomAttr`, `$17`)
> relocated to the bank tail + widened to 6 entries (`$6B-$70`; `$6E/$6F` vanilla-fallback).
> (4) **`MapIDClampForPalette`** (ROM0) made **uniform** (`$00` for all custom rooms) — already
> O(1); removed the dead `$6B→$16` special case. (5) **Room data** (`CustomSourceMapTable`/
> `CustomRoomPtrTable`, `$60`) widened to 6. **Proof:** room **`$70`** (amber) added *past* the
> ceiling by table rows alone; walkable loop `$6B→$6C→$70→$6B` with **staircase** exit markers
> (`$3C-$3F` placed on the exit metatiles via `tools/build_gate_room.py`); `$6D` (green) left
> as the gate-rotation-only proof. `$6B/$6C/$6D` behavior preserved. Files: `patches/bank_071`
> (NEW), `bank_000` (clamp + threshold site), `bank_00b` (2 GFX sites + encounter hook),
> `bank_017` (render tables relocated/widened + `$6D`/`$70` palettes), `bank_060` (tables + `$70`
> room + chained exits), `bank_064` (regenerated: exit staircases), `wram`
> (`wCustomStep_Room70_S0 $D47E`, `wRoomRecScratch $D47F`, `wRoomEncFlag $D487`), `game.asm`
> (`bank_071` include), `tools/build_gate_room.py`, `tools/verify_integrity.py`
> (`PATCH_NEW_FILES += bank_071`). Docs updated in place: EDITOR_DESIGN §2 (as-built),
> ROADMAP (Phase 2 keystone + Encounters #1 ticked, Pillar A ceiling-lift note), KEY_LESSONS
> (S42). `APPLY_THESE_CHANGES.md` regenerated for git.
>
> Last verified: 2026-06-26 (Session 41 — **Phase 2C: custom gate room INSERTION half ("Pillar B")
> complete & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`; test ROM
> `DWM-gate-rotation-v3.gbc`, **user-confirmed: room appears every gate-1 floor, descends to boss,
> with whoosh + continuous BGM.**)
> **S41 — custom room `$6D` inserted into the Gate of Villager (gate 1) rotation, descending
> floor-to-floor.** This is the *insertion* half that Pillar A (S40, table-driven render) set up.
> (1) **Insertion via a byte-neutral fork**, NOT the planned `rst $00` slot: the 6-byte gate-0
> exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf` — reads **`wGateID $C935`**,
> correcting an earlier `wCurrentFloor` cite) is replaced in place by `call GateDecisionFork`+3 nop.
> The fork (`$16:$7CB9`, end-of-bank padding) routes by `wGateID`: gate 0 → vanilla maze, gate 1 →
> `CustomGate1Setup` (`wMapID=$6D`, mirror of `$50` handler `$5D0D`), gates 2–31 → untouched RNG
> gating. A `pop hl` discards the call's return addr so gate 0/1 unwind to entry-5's caller (not back
> into the RNG path). (2) **Descent** via a `gate_flag=$80` exit on the room's PIT tile (mirror of
> special rooms `$50/$51`) → re-enters entry-5 floor setup, increments `wCurrentFloor`, re-runs the
> fork → `$6D` again until the boss floor. (3) **Descent-transition feel fixed.** Both the slow
> dissolve and the per-descent BGM restart trace to **one cause**: the custom room runs with
> `wInGateworld=0`, so the engine treats each descent as a *fresh hub→gate entry*. Making it a real
> in-gate floor (`wInGateworld=$01` during display) **freezes the game** — that flag gates every
> gate/maze branch and the un-intercepted ones read absent maze state. Fix is **transient**: set
> `wInGateworld=$01` **only during the transition window** (`CustomDescentInGate` @ `$0B`
> `jr_00b_466b`/`$45F9`, byte-neutral; resets to 0 before redraw via the fork) → whoosh + BGM
> continuous, render/descent unchanged. Dedicated room `$6D` keeps the `$6B`/`$6C` demos intact.
> Files: `patches/bank_016` (fork + setup), `bank_000` (`$26DD[$6D]` 1-screen gate record),
> `bank_017` (`CustomRoomPalPtr/Attr[2]` borrow `$6B`), `wram` (`wCustomStep_Room6D_S0 $D47D`),
> `bank_060` (`$6D` room data + descent exit), `bank_00b` (`CustomDescentInGate`). Docs updated in
> place: GATE_GENERATION §7.5 (+§6 `rst $00` table corrected: idx0=`$5C42`, idx2=`$5CCB`), ROADMAP
> (Phase 2C both halves ticked), KEY_LESSONS (S41: pop/jp fork control-flow; `wInGateworld=0` ⇒
> fresh-gate-entry transition; transient-flag-during-transition technique). `APPLY_THESE_CHANGES.md`
> regenerated for git.
>
> Last verified: 2026-06-25 (Session 39 — **Phase 2C: custom gate room (rendering half) +
> room-palette derivation fully solved & tooled.** Integrity PASS 4/4, clean build `1ca6579…`;
> gate-room test ROM `DWM-gate-room-v5.gbc` MD5 `2a008235…`, **user-confirmed in SameBoy**.)
> **S39 — two landed pieces.** (1) **Custom Room `$6B` now wears the Gate-of-Beginning maze
> tileset** (gfx-ID `$280D` = bank `$28` step `$0D`, floortype `$D`): a sandy island with an
> ocean-wall border (incl. top), 2×2 **tree** (`$34-$37`/pal3) and **dune** (`$38-$3B`/pal0)
> metatiles, and pit holes — all real gate tiles with the real gate floor palette (`$17:$629D`).
> Authored in new `tools/build_gate_room.py` → `patches/bank_064.asm`; gfx-ID/threshold in
> `bank_000.asm`; `CustomPaletteColors_6B` (slots 0–3 ONLY — widening clobbers system slots →
> monster-colour corruption) in `bank_017.asm`. Palette assigned **per position** (trees need
> pal3 yet share the `$30` collision-threshold side with ocean/floor). This is the *rendering*
> half of "custom room into the gate rotation"; the `rst $00` *insertion* half is still open.
> (2) **Room-palette derivation from ROM** (`tools/derive_room_palette.py`): a room's real BG
> colours are only indices 0 and 2 of slots 0–3 (from `$17:$476F`[mapID] normal / `$17:$51F5`
> [floortype] gate, scanning past empty screens); the engine **forces idx1=`$6bff`, idx3=`$0000`**
> in every BG palette; slots 4–7 are a shared system set; object palettes are one global block at
> `$17:$5615`. Validated **30/30** SameBoy dumps + the gate floor; refuses cleanly when a room has
> no resolvable pointer. Docs updated in place: GATE_GENERATION §7.1–7.3 + palette tables,
> TOOLS_AND_DATA (both tools), ROADMAP (Phase 2C rendering half ticked), KEY_LESSONS (S39: forced
> colours / screen-scan / decimal-label / metatile-palette lessons).
>
> Last verified: 2026-06-25 (Session 38 — **Phase D new-species data-table SEAMS annotated +
> Phase N lineage parent-name "?????" FIXED.** Integrity PASS 4/4, clean build `1ca6579…`;
> lineage test ROM `DWM-lineage-fix-v1.gbc` MD5 `2a09d94f…`, **user-confirmed in SameBoy**.)
> **S38 — two pieces, both landed.** (1) **Data-table fork SEAMS** now self-documenting at their
> clean anchors (labels/comments only, build byte-perfect; the S33 pass did the DISPLAY seams, this
> finishes the data-table set): `bank_003 label443f`/`SaveMon_4446` (single info indexer; id≥224 →
> bank `$6A` fork; also reached as `$03` entry 1 by breeding's `$0301` parent-family load),
> `bank_014 LoadEnemyStats` (16-bit EID → NO fork) + new label `EnemyStatsTrailingFree` @ `$7EAD`
> (append region; EIDs 487–517 are unusable CODE, first grid-aligned slot is EID 518 `$7EB3`),
> `bank_001 EncounterPool_000` (empty slot = in-place insertion point, Iron-Rule-2 safe),
> `bank_016 label16_485c` (entry-1 recipe lookup overshoots 222-entry `FamilyRecipeTable` →
> `FamilyRecipeResolve` display fork) + the `$0301` parent→family seam (new species resolves a real
> family as a breeding parent via the forked info loader). (2) **Lineage parent-name fix (N5 sub-item
> closed):** the library/encyclopedia lineage line-1 showed "?????    ?????" for Gorbunok. Verified the
> path from clean source (entry 2 `call SetB4d_43b9` → `HighDetailTextFork` → `HighModeTable4D` for
> id≥224), then wired `HighModeTable4D` mode-0 → new `HighMode0Ptrs` → `GorbunokRecipeLine`
> (`patches/bank_04d.asm`). Also **corrected a latent format bug** in the S32-staged string: real recipe
> lines use TWO 9-char fields (e.g. slot 200 "Servant  GreatDrak"), so rebuilt as `"Snaily   BattleRex"`
> (names sym-verified vs `MonsterNamePtrTable $41:$4339`). id≥224-gated → ids 0–223 byte-identical.
> Built-ROM check: `[mode0base+224*2] → GorbunokRecipeLine` → "Snaily   BattleRex". Docs updated in
> place: ROADMAP (Phase D seams ticked, N5 lineage sub-item done), MONSTER_DATA (overshoot registry
> lineage row → DONE, data-table seam annotations recorded).
>
> Last verified: 2026-06-24 (Session 36 — **Starter + force-join verification (audit of legacy
> editor knowledge).** Integrity PASS 4/4, clean build `1ca6579…`.)
> **S36 — starter mechanism PROVEN end-to-end and editor claim confirmed.** Starter = enemy-stats
> **EID 1** (`$14:$4C36`); granted by Castle intro `add_monster enemy=$0001` at `$0C:$42D6`, gated by
> flag `$0002` (fires once at new game), built via `LoadEnemyStats(EID 1)` → `label14_40b4`. Confirmed
> in-game (EID 1 → SkyDragon Lv25 swap). Stats transfer as base then take an 80–100% creation roll
> (`SaveEnem_4821`). Annotated the previously-raw-`db` grant block in `bank_00c.asm`
> (`Bank0C_ScriptAddr_4270:`, labels/comments only, byte-perfect). **Force-join hack verified** (hooks
> `$54:$55D5` NOP + `$54:$5604`→`$7FC8` resolver + `$7FE0` table all correct; logic sound) but **NOT
> ported** — brittle on `wGateID` (`$C935`) overload (arena/bank_055 zeroes it; gate-entry/bank_016 sets
> it to `wMapID`, not the editor's 0–31 ordering), table range, and tier-7 lacking a `join_eid` redirect.
> Crossbank left untouched per directive. Docs updated: MONSTER_DATA.md (Starter Monster, stat creation
> roll, force-join verification), EVENT_FLAGS.md (flag `$0002`).
> Last verified: 2026-06-24 (Session 35 — **Milestone G2: new-species BATTLE sprite + battle
> palette baked into `patches/`; user-confirmed OK.** Integrity PASS 4/4, clean build `1ca6579…`,
> patched build verified.)
> **S35 — battle-art half is now permanent too.** id 224 (blue-dragon proof art) now shows its real
> custom sprite IN BATTLE (royal-blue body / white belly / black outline), matching the G1 follower.
> What landed in `patches/`: the dragon battle pose packed as a **2nd overflow entry** in `bank_07e.asm`
> (`Battle_sp224` @ gid **`$7E01`**; the follower stays `$7E00`, byte-identical — the pointer table just
> grew to 2 entries); `bank_000.asm` repoints `MonsterBattleGfxTable[224]` at `$00:$2d5f` `$320f`→`$7e01`
> — a **same-size 2-byte edit, NO fork**, because the species-indexed battle gfx table `$2b9f` has a real
> (padding) slot for id 224 (contrast the follower tables, which overshoot and needed id-indexed forks);
> `bank_017.asm` forks the battle-palette reader `label17_41d0` byte-neutral (`call HighBattlePal` + 5 `nop`)
> to a resolver in the bank `$17` filler tail (`$6cea`) — id≥224 → custom palette `67 4d ff 6b ff 7f 00 00`,
> else vanilla `$62fd+species*8` (its slot `$69fd` overshoots into `PaletteColorData`). Tool
> `tools/bake_follower_overflow.py` extended with `--battle-art/--battle-spec` (emits both streams, prints
> the battle gfx-ID + palette); new spec `examples/follower_swap/gorbunok_battle.json`. No verify_integrity
> PATCH-list change (`bank_000/017` already in PATCH_FILES, `bank_07e` in PATCH_NEW_FILES). See
> KEY_LESSONS + MONSTER_DATA "NEW species battle sprite".
> **S34 — follower-art fork is now permanent + editor-shaped.** id 224 (blue-dragon proof art)
> walks the overworld / shows in menu+library with real custom art, built from the canonical
> `make` path. What landed in `patches/`: new overflow bank `bank_07e.asm` (blue-dragon 256B
> layout-0 payload, gid `$7E00`); all **8 follower-art gfx-ID copies** forked to a per-bank
> **id-indexed `NewFollowerGfxTableNN`** (`dw $7E00` at slot 0; resolver computes
> `table + (species-224)*2`, so adding species 225 = append a `dw` + rebuild — content-sized,
> grows on rebuild); `bank_011.asm` writes the layout level-1 slot `$413f = dw $4184` and forks
> the attr read (`HramUnk11_406e` → `NewAttrHandler @ $11:$792d`, id-indexed `NewFollowerAttrTable`);
> overworld clamp narrowed `cp $e0`→`cp $e1` so 224 passes (225–255 still clamp). New patch files:
> `bank_011/059/07e.asm`; new tool `tools/bake_follower_overflow.py` (emits the art bank).
> **Two orientation bugs found + fixed PROPERLY (root cause, not band-aid), both the same lesson —
> sanitise the base attr surgically:** (1) art is stored **un-flipped** (the `--flip-y` band-aid was
> removed from both tools); (2) the clean-attr mask is **`$B8` not `$98`** — `$98` also cleared the
> engine's bit5 X-flip, breaking the LEFT facing. See KEY_LESSONS + MONSTER_DATA. **G2 (battle sprite +
> battle palette for id 224) is now DONE (S35, above).** NOT yet done (next): `new_species.json` schema
> fold (G3).**

> **S33 — name/text/lineage/follower display fork seams now self-documenting at the clean anchors.**
> 11 files touched (`bank_000/001/006/007/009/00b/012/016/018/041/059`), comments+labels only.
> Covered: bank `$41` `$4007` mode→table config list, the corrective `FamilyCodePtrTable` block
> (it's the SPECIES-indexed 2-letter default-nick table, mode 7 — NOT a family table; label kept
> for ref-stability, flagged legacy), `Func_Bank41_GetText/GetPutText`; ROM0 `SaveBankAndSwitch
> $092F`/`TextHandler_0940 $0940` two-level `[mode][id]` lookup + per-mode-count overshoot hazard +
> `LoadModeBaseRedirect $00F0` fork cross-ref; bank `$12` lineage chain (`LoadItem_6456`→`$4d` entry
> 2 modes 0/1, `LoadItem_65a8`→recipe `$1601`→parent icons, `CmpItem_65cb`→`ItemSlotPtrTable`); the
> **8 follower gfx-ID copies** one-line-commented at their add-base sites (`$01/$06/$07/$09/$0b/$12/
> $18/$59`, all operands sym-confirmed to the tool's bases); + one optional cross-ref at bank `$16`
> `$0301` parent-family load. **Two corrections baked into source + MONSTER_DATA:** ItemNamePtrTable
> is **mode 8** of the `$4007` list (NOT mode 11 = `$49CD` MiscTextPtrTable); `$4739` overshoots at
> **id≥215** (fork covers **id≥224**; 215–223 phantom). Decisions (per user): keep the label + strong
> corrective comment (no rename), bank `$16` breeding-determination internals deferred to a
> breeding-mechanics pass. Docs updated in place: ROADMAP (Phase-D seam box → partial, display seams
> done, data-table seams `bank_003/014/001-encounter` + breeding internals still pending),
> MONSTER_DATA (overshoot registry + 8-copy add-base table + the two corrections). Changed source
> files are clean-disassembly only; no patches/tools/extracted touched.
>
> Last verified: 2026-06-22 (Session 30 — **Phase N audit + two reproducibility defects
> fixed; user-playtested OK**. Gorbunok (id 224) caught in Gate of Beginning, lists under
> Slime family, visualizable in library; custom rooms + encounters still good. Integrity
> PASS 4/4, clean build `1ca6579…`, test ROM `DWM-newspecies-repro-v1.gbc` MD5 `c17c2840…`.)
> **S30 — Phase N keystone verified; library + encounter made TOOL-OWNED (reproducible).**
> Forensic re-audit of the "add new monsters part 2" commits: clean disassembly net-zero
> change (the d84a43f/c4af28b comment add+remove cancel; nothing lost), N2 info-fork +
> N3 enemy-stats verified byte-correct (info table pinned at `$4461`, ids 0–220 byte-
> identical bar the 2 B6 reassigns; EID 518 @ `$14:$7EB3`). Two latent defects found and
> fixed, both "patch works but not reproducible from its tool": **(1)** the library Gorbunok
> entry + the unseen-marker move `$E0`→`$FE` (needed because `$E0` is now a real species)
> were hand-edited — `build_library_table.py` now reads `new_species.json` and owns all
> three marker sites (`ld [hl],$fe` + 2× `cp $fe`), count-validated, `--selftest` still
> proves vanilla parity. **(2)** the wild-encounter insertion (pool 0 slot 3 = EID 518) was
> hand-edited — `build_new_species.py` now emits it as a same-size in-place `EncounterPoolData`
> edit (validates the target slot was empty in vanilla first; Iron-Rule-2 safe). NOTE: an
> earlier audit claim that the encounter was "not applied" was MY error (searched the pool
> for species id `$E0` instead of EID `518`); the encounter was correct, only un-reproducible.
> Docs updated in place: BREEDING_SYSTEM (walker marker `$FE`), MONSTER_DATA (overshoot
> registry: encounters are a pool edit not a fork, follower 3/8 partial, library tool-owned),
> ROADMAP (N2/N3 ticked, N4/N5 partial, + a Phase-D follow-up to annotate the fork seams in
> clean disassembly). Changed files: `tools/build_library_table.py`, `tools/build_new_species.py`,
> `patches/bank_012.asm`, `patches/bank_001.asm`, `extracted/library_grouping.json` (+ docs).
>
> Last verified: 2026-06-22 (Session 29 — **encyclopedia DETAIL page FREEZE fixed**;
> Gorbunok (id 224) detail now opens clean, integrity PASS 4/4, ROM
> `DWM-Gorbunok-stage1ac-v16.gbc` MD5 `4d3d0d59…`. User-playtested: no freeze, no
> glitches; entry mirrors Dracky.)
> **S29 — detail-page freeze root-caused and fixed; recipe overshoot fixed.**
> Root cause: monster detail text uses a **mode×species double indirection** in
> `SaveBankAndSwitch` (`$00:$092F`) — source = `[ [$4007 + mode*2] + id*2 ]`. The
> line-2 **description** table (`$4D:$420B`) is only **215 entries** and ends at
> routine code, so id 224 read `[$43CB]=$0609` (ROM0 code) and the text VM rendered
> code as glyphs forever → `WaitScreenUpdateDone` spin. Fixed by a byte-neutral fork
> of `SetB4d_43b9` → `HighDetailTextFork` (custom mode-table; id≥224 line-2 →
> `$60BC`, Dracky's description as placeholder). Separately, the breeding-recipe
> lookup `label16_485c` indexed the **222-entry** `FamilyRecipeTable` unchecked
> (id 224 → bogus parents); forked via `FamilyRecipeResolve` → `$FF,$FF` (no recipe,
> correct for wild-only). New patch file `patches/bank_04d.asm` (registered in
> `PATCH_FILES`). The "material icon"/"stale Healer info" were render-abort artifacts
> and cleared with the freeze. New docs: `TEXT_SYSTEM.md`,
> `MONSTER_DATA.md` (Species ID geography) (species-indexed-table overshoot checklist); mechanism in
> `TEXT_SYSTEM.md`; recipe/new-breeding path in `BREEDING_SYSTEM.md`; lessons in
> `KEY_LESSONS.md`. **Deferred:** custom Gorbunok sprite/art and a custom (non-Dracky)
> description string. Vanilla 0–220 byte-identical; clean build still `1ca6579`.
>
> Last verified: 2026-06-21 (Session 28 — Phase N kickoff: add-NEW-species scoping/RE.
> No bytes changed, vanilla ROM untouched, integrity PASS 4/4. Pure RE + data tool —
> nothing to playtest yet; N2 is the first ROM.)
> **S28 — "add new monsters on top of the 221" scoped + slot map delivered.**
> User goal: brand-new species (not reskins). Species id is a single byte → hard 256
> ceiling; ids 215–219 are special (215 `TERRY?` one-off enemy; 216–219 Tatsu/Diago/
> Samsi/Bazoo = summon-skill byproducts, user-confirmed), 220–223 empty/phantom, so the
> **first free id is 224 (`$E0`), budget 32 (224–255)**. Architecture chosen: **high-table
> + single forked loader, vanilla 0–220 byte-identical** — each per-species table has ONE
> arithmetic indexer to fork (`if id < 224 → vanilla, else → free-bank high-table`).
> Verified single indexers: monster info `$03:SaveMon_4446` (×43; all 16 consumers read
> the `$DA33` copy), enemy stats `$14:LoadEnemyStats` (×25, **16-bit EID** → no 256 wall on
> the battle side). The ceiling is NOT one clean gate: ~40 `cp $dd`/`cp $de` hits are
> false positives (interrupt boilerplate + misassembled data); only 4 real top-range
> special-case gates (`$5f/$57/$58/$52`) need the N6 "treats ≥224 as normal" check.
> Deliverable: `tools/map_species_slots.py` + `extracted/species_slot_map.json` (256-slot
> map, self-aborts on drift). Plan: ROADMAP "Phase N" (N1 done; N2 info-table fork is the
> keystone next session); mechanics: MONSTER_DATA "Species ID geography".
>
> Last verified: 2026-06-21 (Session 27 — Phase D re-section: bank `$12` library/family
> data **COMPLETE**. Labels-only, byte-perfect — clean build still `1ca6579…`, integrity
> PASS 4/4. No behavioral change, nothing to playtest.)
> **S27 — bank `$12` window-layout run finished (whole bank now editor-addressable).**
> Extended `tools/resection_library_tables.py` to convert the **two remaining contiguous gaps**
> in the menu window-draw layout run: `$724e..$759a` (10 layouts) and `$75c0..$7b42` (13 layouts).
> Combined with S26, the entire contiguous run **`$710c..$7b9b` = 29 layouts** now reads as named
> `db`/`dw` (`LibWinLayout_<addr>`), all 13 remaining `ld de,$imm` reference sites labelized (44
> total across S26+S27). The 380-B `$79c6` full-screen library view (an 18×20 layout using a
> *different* window-border tileset, `$01 $02..$03`/`$04`/`$05`) is converted — its mgbdis fake `jr`
> labels (`$7a05`…`$7aca`) and their `jr` sources were all inside the data range and vanished
> together (no dangling refs). The 21 `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/
> `$6101`) correctly LEFT raw. New data deliverable `extracted/library_layouts.json` (29 layouts
> decoded to rows; `--dump-json`). Tool is now per-table idempotent and re-runnable from the clean
> tree (verified: clean-tree run reproduces byte-perfect build + identical 29-label set). Format +
> per-layout table: DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)"; ROADMAP Phase D
> bank-`$12` item ticked complete. This closes the bank-`$12` re-section; the remaining Phase D work
> is the stale-box verify-ticks (`$03`/`$14`/`$16`) and editor-driven banks (`$01`/`$50`/`$51`).
> Also recorded (Session 27) a **"new campaign" gap analysis** — the campaign-scale subsystems
> beyond editor v1 (arena/gate-boss roster format, story-progression authoring + bank-`$50`,
> new-game init/save headroom, gate-network, intro/ending, text capacity) — in ROADMAP "Phase E",
> with the two story/arena keystones detailed in SIDEQUEST_MAP "Gaps for authoring a NEW campaign".
> The keystone RE gap is **E1 (arena/gate-boss roster format)** — the natural next Phase-D/E session.
>

> Last verified: 2026-06-21 (Session 26 — Phase D re-section: bank `$12` library/family
> data tables converted to labeled `db`/`dw`. Labels-only, byte-perfect — clean build still
> `1ca6579…`, integrity PASS 4/4. No behavioral change, nothing to playtest.)
> **S26 — bank `$12` library/family data tables re-sectioned (editor-addressable).**
> `tools/resection_library_tables.py` converts the misassembled library-menu data tables in
> `bank_012.asm` to named `db`/`dw` (labels/comments only, zero byte impact): `LibraryFamilyTabBounds`
> (`$6294`, 11 B family id-range bounds — the S18 case, "THE ONLY id-range family assumption in the
> ROM"), `LibTabColPos_564a`/`_5a8e` (tab-column cursor positions, `$ffff`-terminated, read by
> `FuncItem_43e2`), and `LibWinLayout_710c`/`_71aa`/`_71f4`/`_759a`/`_7b42`/`_7b6c` (menu window-draw
> layout streams: dest-position word + tile bytes, `$d8`=newline, `$d9`=terminator, via
> `ReadPtrFromDE` + draw loop `$40c3`). 31 raw-pointer reference sites labelized. `$5605` correctly
> LEFT — it's a far-call descriptor (`ld hl,$5605; rst $10` → bank `$56` entry `$05`), NOT `$12` data;
> the `$79c6` region conservatively skipped (mgbdis put `jr` labels in it; it is reached via `ld de`
> so likely a convertible layout — flagged for the bank-`$12` follow-up). The tool maps source
> line→address via a zero-byte probe-build read from the linker `.sym` (avoids the S22 opcode-size-
> summing trap) and is re-runnable from the clean tree. Format + addresses: DATA_STRUCTURES
> "Library / family-tab menu data (bank `$12`)"; remaining bank-`$12` tables + skip-list folded into
> ROADMAP Phase D "Re-section misassembled data tables". Supports the B8/B9 library/family work
> (the 11th-family tab + bounds are now named/editable rather than re-derived from raw bytes).
>
> Last verified: 2026-06-21 (Session 25 — GFX-4 DONE: monster→follower-layout auto-map +
> custom-art import + full multi-context consistency. Healer→Dragon clone and Dracky→custom
> blue-dragon both user-confirmed "everything is correct" in SameBoy, consistent across overworld
> + menu + library.)
> **GFX-4 DONE — monster → follower-layout map, custom-art import, all-context consistency.**
> (1) The level-1 layout dispatch tables are LOCATED at FIXED addresses **`$10:$407f` (species
> 0–127) / `$11:$407f` (species 128+)**, 128 `dw` each, indexed by species directly (`$ffc7 =
> species+$10`, routed `$10–$8F`→bank `$10`, `≥$90`→bank `$11` via bank-`$04` entry 2). A per-species
> **attr/palette table at `$10:$417f` (128 entries) / `$11:$412d` (87 entries)** (ORed into `$ffca`, low 3 bits = OBJ palette). **Two
> pre-GFX-4 doc errors corrected:** `[$caca]` is the SPECIES (party struct +$09), NOT a "sprite-class"
> byte; and bank `$05` is the ObjTest viewer path, NOT the follower path (S24 anchored to `$05`
> addresses — harmless because dedup ignored bank, but wrong). Both Healer (sp9, sharing) and DarkDrium
> (sp214, non-sharing) reproduced byte-for-byte through `$10`/`$11`. (2) `tools/extract_monster_follower_layouts.py`
> + `extracted/monster_follower_layouts.json` (every species → layout id + addresses + sharing); it
> REGENERATES & REPLACES `follower_layouts.json` with the COMPLETE **155 layouts** (old 118 dropped
> the 3-entry small/blob layouts the brute-force scan rejected). `--selftest` PASS (215/215
> collectible map; anchors verified). (3) **The follower-art gfx-ID table has EIGHT copies**
> (`$01 $06 $07 $09 $0b $12`-library `$18`-menu `$59`); a consistent swap must repoint all 8 (layout
> `$407f` + attr `$10:$417f`/`$11:$412d` are single/shared). GFX-3 repointed only `$01` → that's why swapped monsters
> kept old art in menus. (4) `tools/build_follower_reassign.py` — reassignment primitive: clone
> layout+art+attr from a same-bank monster, OR import custom 16-tile art (placed cross-bank via the
> GFX-2/3 overflow allocator, all-8-copies repointed) + set layout (default layout 0 `$10:$4e33`) +
> OBJ palette. Layout 0 packing: tiles 0–3=DOWN-a, 4–7=SIDE-a, 8–11=SIDE-b, 12–15=UP-a (down_B/up_B
> auto-mirror; LEFT = right X-flip). Clean build still `1ca6579…`; integrity PASS 4/4. Reassignments
> are reproducible EXAMPLES, not baked into the canonical ROM. **Reassignment is a level-1 repoint,
> NOT a `[$caca]`/species edit** (supersedes the GFX-3 plan's "same-size `[$caca]` edit"). Method:
> KEY_LESSONS "Session 25"; mechanics: MONSTER_DATA "Monster → layout dispatch".
>
> Last verified: 2026-06-21 (Session 24 — GFX-3 DONE: walking/follower sprite swap +
> follower metasprite engine fully reverse-engineered + 118-layout library extracted.
> Blue dragon → DarkDrium follower user-confirmed "absolutely perfect" all 4 directions.)
> **GFX-3 DONE — follower (walking-sprite) swap, end to end.**
> (1) `ScreenTransDataTable` @ `$01:$49DF` re-sectioned from mgbdis fake-instructions to a
> labeled `dw` block (`tools/resection_follower_gfx_table.py`; 231 entries indexed
> `species+$10`, + `FollowerFamilyGfxTable` 10 families @ `$4BAD`; build still `1ca6579…`,
> zero external refs into range). `build_sprite_swap.py --kind follower --payload F.bin`
> repoints the dw entry and DMAs a self-contained 16-tile (256 B) literal-encoded stream.
> (2) **Follower render = metasprite engine** — `SaveScr_40cd` @ `$04:$40cd` (GBC variant of
> ROM0 `$0d91`). A two-level pointer table (sprite-type `$ffc7` → frame/direction `$ffc8`)
> selects a metasprite list: 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated.
> Final OAM tile = `tile_offset + [$ffc9]` (follower tile base `$20`/`$30`/`$40` per party
> slot 0/1/2); final OAM attr = `[$ffca] XOR attr` (X-flip = bit5 `$20`). `$ffc7 = [$ca91]`
> (= `GetActiveMonsterStatus` return: `$01` if bit7 of `[$cb0b]`, else `[$caca]+$10`).
> (3) **OBJ transparency rule (critical):** colour index 0 is HARDWARE-transparent for OBJ
> sprites (the battle path used a BG backdrop = index 1 — opposite). Follower empty/background
> pixels MUST map to idx0. 8 global OBJ palettes (4×RGB555) at `$17:$5615`.
> (4) **Per-monster layouts — there is NO single universal arrangement.** The tile→direction
> mapping is one of **118 distinct layouts** (`tools/extract_follower_layouts.py` →
> `extracted/follower_layouts.json`). **76 are non-sharing** (disjoint down/up/side tile sets
> → ANY distinct art renders perfectly; cover 202 sprite types) and **42 are sharing**
> (up/side reuse tiles — fine for radially-symmetric blobs, breaks directional art; 58 types).
> This resolved the multi-attempt mystery: a symmetric blob masks layout errors (the clam
> "worked" by luck); a directional dragon exposes them. Healer = a sharing layout, DarkDrium =
> a non-sharing one (both measured, both matched the extracted data exactly).
> (5) Tooling: interactive `tools/follower_frame_picker.html` (drag 6 boxes over a sprite
> sheet, live per-direction engine-accurate preview, export coords/payload). **Numbered-tile
> calibration method** (each VRAM tile renders its own hex index 0–F + a flip-foot →
> read the layout directly off-screen, no decoding) — `--palette` override forces black digit
> / red foot for legibility against terrain.
> USER-CONFIRMED in SameBoy: blue dragon (DWM2 art) → DarkDrium follower, all 4 directions
> correct, by matching the art to DarkDrium's non-sharing layout.
> **FOLLOW-UP — GFX-4 flagged (ROADMAP):** monster→layout auto-map. The type→layout level-1
> dispatch tables (banks `$05`/`$10`/`$11`, routed by `$ffc7` magnitude: `<$10` bank `$04`,
> `$10–$8F` bank `$10`, `≥$90` bank `$11`) and the per-monster sprite-class byte (`[$caca]`)
> are not yet located/extracted; the full engine structure IS known, so it's a clean pickup.
>
> Last verified: 2026-06-20 (Session 23 — GFX-2 DONE: cross-bank sprite backbone +
> monster battle palette SOLVED + recolour; clam→Dracky purple + full integration
> user-confirmed in SameBoy.)
> **GFX-2 DONE — cross-bank sprite swap backbone + monster palette recolour.**
> (1) `dwm/sprite_bank.py` — cross-bank OVERFLOW allocator: places encoded streams in
> the reserved sprite banks (`$7E–$7F`, then `$7C/$7A/$79`; EDITOR_DESIGN §8) with a
> `$4001` pointer table, and `tools/build_sprite_swap.py` (rewritten) repoints the
> species→gfx-ID entry — works for ANY of 221 monsters regardless of which bank their
> art lives in (resolver reads `$<bank>:$4001+index*2`, NO bank gating; verified). This
> is the bulk-DWM2-import enabler (the old tool was battle-only, bank `$36` only,
> ~40/221). `--relocate` = lossless cross-bank copy (proof: Slime relocated renders
> identically, user-confirmed). (2) **Monster battle palette SOLVED** (was the GFX-2
> "semi-speculative" gap): the enemy renders as BG tiles on **BG palette slot 4**; the
> per-species colours live in **`MonsterBattlePalettes` @ `$17:$62FD`** (mgbdis-misnamed
> `RoomAttrDataBlocks`), 8 B/species `[c0, c1=$6bff backdrop, c2, c3=$0000 black]`,
> loaded by bank `$17` **entry 6** (`$1706`: `$c81e`=species×8+base, `$c81f`=slot).
> Found via SameBoy BG-slot-4 dump (Dracky `007b 6bff 2a97 0000`) + ROM grep; annotated
> in `bank_017.asm` (label `MonsterBattlePalettes` + loader doc, byte-perfect). Recolour
> = same-size 8-byte edit of one species' entry (Iron-Rule-2 safe; per-species, no
> bleed) via `build_sprite_swap.py --palette`. (3) Data: `tools/extract_monster_palettes.py`
> + `extracted/monster_palettes.json` (all 221); `extracted/monster_sprites.json`
> REGENERATED (all 221 — the shipped copy was a 3-monster subset, a data defect now
> fixed). USER-CONFIRMED in SameBoy: DWM2 clam→Dracky battle + correct purple palette;
> and a full integration ROM (clam + Dracky→Spirit family + custom room with random
> encounters + breeding/library all coexisting, no glitches). The swap touches only
> bank `$7e` (art) + 2 B in `$00` (repoint) + 1 entry in `$17` (palette) — orthogonal to
> breeding/library/custom-rooms/Spirit-family. Integrity PASS 4/4. NEXT: GFX-3 (follower
> /walking swap) — rides this backbone via `$01:$49DF` (needs re-section first) + its own
> palette table + the family-shared `$4bad` block. Method: KEY_LESSONS "Session 23";
> mechanics: MONSTER_DATA "Monster battle palette system".
>
> Last verified: 2026-06-20 (Session 22 — GFX-1: graphics system annotated +
> sprite codec/extraction/swap tooling; Dracky→Anteater swap user-confirmed in
> SameBoy as a mostly-red Anteater, i.e. correct shape in Dracky's palette.)
> **GFX-1 DONE — editor graphics asset layer + correct disassembly.** Three
> foundations landed: (1) the battle gfx-ID table `$00:$2B9F` was misassembled
> (fake instructions, 23 hallucinated labels cross-referenced from other banks);
> re-sectioned into a real labeled block `MonsterBattleGfxTable` via
> `tools/resection_battle_gfx_table.py` — anchored between real symbol-map label
> boundaries, exact ROM bytes emitted, all 23 cross-refs preserved, build still
> `1ca6579…`. (2) `dwm/sprite_codec.py` — the SINGLE LZ codec for tiles+sprites
> (decode byte-exact = game + existing tile decompressor; encode valid/compact;
> tile↔image); `decode(encode(x))==x` verified on all 442 monster streams.
> Deliberately NOT byte-identical re-encode of vanilla (no editor value). (3)
> `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` — all 221
> monsters' battle+follower sprites → manifest (count-parameterised, no 221 wall).
> `tools/build_sprite_swap.py` generalised to species-agnostic (PNG/payload/probe →
> encode → place → repoint); builds valid ROM. INTEGRITY PASS. KNOWN: all 221
> battle streams use shared-VRAM-pool back-refs → new art must encode self-contained
> (`--literal`) or reconstruct pool; swap tool's free-space placement currently
> knows bank `$36` only (cross-bank allocator = editor-backend follow-up). PALETTE
> LEAD for GFX-2 (user VRAM data): battle uses ONE shared OBJ palette slot (4); the
> per-species COLOURS are loaded into it at battle-init via `FuncFld_6942`/
> `SetGBCPalette` (bank `$07`, note `ld h,$04`). So recolour = edit the per-species
> colour table, NOT a slot assignment. Full mechanics in MONSTER_DATA.md "Monster
> sprite graphics system"; lesson in KEY_LESSONS "Session 22". Next: GFX-2 (palette
> recolour) or GFX-3 (follower swap, rides the codec).
>
> Last verified: 2026-06-19 (Session 21 — Monster battle-sprite swap POC:
> Dracky sp.78 → DWM2 "clam", proven rendering in SameBoy; in Dracky's native
> palette pending recolour.)
> **Monster sprite graphics system reverse-engineered + swap proven.** Every
> graphic = gfx-ID `(bank<<8)|index` → resolver `DecompressTileLayout` `$00:$1627`
> → per-bank pointer table `$<bank>:$4001+index*2` → LZ stream (3-byte header,
> back-refs into a SHARED VRAM tile pool). Battle path VERIFIED: `SetFld_466d`
> (bank `$07`) → table `$00:$2B9F`[species*2] → VRAM `$8B00`; Dracky = gfx-ID
> `$3627` (bank `$36`, 36 tiles). Swap method: self-contained literal stream (no
> runmark byte) repointed in bank `$36` free space — `tools/build_sprite_swap.py`,
> `patches/bank_036.asm`. Build stays `1ca6579…`; INTEGRITY PASS. Full mechanics
> in MONSTER_DATA.md "Monster sprite graphics system"; next jobs queued as ROADMAP
> **GFX-1** (annotate tile system), **GFX-2** (palette + recolour, semi-speculative),
> **GFX-3** (follower swap). Palette is a separate subsystem (bank `$17`, not yet pinned).
>
> Last verified: 2026-06-19 (Spirit B9 — family-10 VRAM corruption FIXED + icon
> finalized; user-confirmed in SameBoy. Built ON TOP of the gate-entry-freeze fix.)
> **B9 — 11th family "Spirit": VRAM corruption FIXED; icon shipped.** Catching a
> family-10 (Spirit) monster (Dracky sp.78 / DarkDrium sp.214) → party → map corrupted
> ALL of VRAM. Root cause: `bank_01:$49C0` indexes a **10-entry family-indexed GFX
> pointer table at `01:$4BAD`**; family=10 reads OOB → garbage source + garbage copy
> length → runaway copy over all VRAM (SameBoy watchpoint: BC=$2196 runaway, source
> $55fc, into $9864). Fix: 8-byte `ClampFamIdx::` in ROM0 end-of-bank padding (replaced
> 8 `rst $38` filler at $3BCB: `call ReadActiveMonsterByte / cp $0a / ret c / dec a /
> ret`, family≥10→9); `patches/bank_001.asm` routes ONLY the `$4BAD` lookup ($49C0)
> through it as a same-size `call` (Iron-Rule-2 OK, zero shift). The nearby `$499D`
> lookup is SPECIES-indexed into the 215-entry follower table `$49DF` (NOT family) —
> clamping it broke all follower sprites, so it is left alone. **Icon:** the Spirit
> whip (user-selected "option 5") ships on font byte **$19 (`$4F:$41A0`)**, overwriting
> the vanilla ??? glyph (??? + Spirit share it) — NOT the S20-planned free slot $1A
> (`$41B0`), which the menu blanks at runtime (not fill-immune). `extracted/family_icons.json`
> + `tools/build_family_icon.py --selftest` reconciled to the $19 art (icon rederivable
> from tracked data, no PNG). This whole feature sits ON TOP of the committed gate-entry-
> freeze fix: `ClampFamIdx` and `CustomGFXMapID` coexist in ROM0. Clean build still
> `1ca6579…`; integrity PASS. User-confirmed: no corruption, correct followers, library
> grouping good, family attribution correct. Method: KEY_LESSONS "Spirit B9 Lessons".
> **Doc correction:** any S20 text below stating the Spirit icon is on $1A is superseded
> by the $19 placement recorded here.
>

> Last verified: 2026-06-18 (Session 20: family-icon trace (B8/B9 "name" path) +
> Spirit icon insert. NOTE: the S20 "$1A slot / pending sign-off" claims below are
> SUPERSEDED by the 2026-06-19 block above — Spirit icon ships on $19, B9 confirmed.)
> **B8/B9 family-icon path TRACED + Spirit icon half-built (S20).** The long-blocked
> "family-NAME render path" is solved: the family identity is an **ICON font tile**,
> not a string. 10 icons live at `$4F:$4110-$41A0`, addressed by **text bytes
> `$10-$19`** via `ComputeTileDataAddr` (`$00`: `addr = $4010 + byte*16`); the
> monster-detail screen prints `<$F0><icon $1x>"family"` (bank `$4D`) and the
> library tab strip blits the same tiles. `FamilyTextPtrTable` (`$04:$60F4`) is
> confirmed a red herring (per-family monster **dialogue**, opcode `$2D`). User
> confirmed the medium ("symbols, not text") and the icon order (by visual, glyph
> order `$10-$19`: slime, dragon, paw, feather, tree, insect, hammer/axe, black face,
> red face, "?"). The free slot for an 11th icon is **byte `$1A` → `$4F:$41B0`**
> (blank filler; charmap "20-23 are blank"). **Spirit icon inserted** as a same-size
> 16-byte 2bpp tile there (`patches/bank_04f.asm`, user "Fire Whip Spirit" art, zero
> shift; bank `$4F` otherwise byte-identical to vanilla). Tool
> `tools/build_family_icon.py` + data `extracted/family_icons.json` (Variant A = head
> on palette index 0 → yellow head if the menu palette allows; Variant B = head on
> index 2 fallback; `--selftest` proves the JSON grid == the patch bytes). Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `bank_04f.asm` family-icon block
> + free-slot map. Verifier PASS 4/4 (`bank_04f.asm` added to the patch set). Test ROM
> `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN (rest of B9):** the "yellow
> head" is a SameBoy palette question (menu BG pal via `LoadGBCPalettes`→`rst $10`
> `$17:$03`); wiring Spirit as family 11 (the `$4D` detail line, tab-strip 11th cell
> `LoadItem_4241` `b=5,c=10`, the `$FA` family-code wildcard, `NUM_FAMILIES`→11,
> reshuffle) is not done. The icon isn't referenced by any family yet → view via
> SameBoy VRAM viewer until wired. Method: KEY_LESSONS "Session 20 — Family icons";
> reference: BREEDING_SYSTEM "Family icons (B8/B9)".
>

> **B7 — production library grouping (SameBoy-confirmed).** The S18 dynamic-library
> POC (runtime per-species far-load scan, ~221 loads/tab → lag + scratch RAM) is
> REPLACED by a build-time precomputed **family→members** table. `tools/build_library_table.py`
> emits the table into bank `$12` trailing free space (`$7B9B+`) and rewrites
> `SetItem_6242` zero-shift (`jp LibScanByFamily`; 82-byte body → `jp`+79 `nop`); the
> walker reads the table directly — **zero far-loads, zero scratch RAM**, and restores
> the vanilla blank-slot-for-undiscovered semantics the POC had dropped (`$E0` unseen /
> id seen; `$C8E9`=member count, `$C8E8`=seen count). Format: pointer table + length-
> prefixed member lists (additive for an 11th family). Family assignment sourced from
> the vanilla family byte (`$03:$4461+$00`, raw 0..9) + `breeding_family_reassign.json`
> (the SAME spec `bank_003`/B6 consumes — library and family bytes stay in lock-step).
> Build-time self-checks: `--selftest` proves no-reassign grouping == vanilla bounds
> table exactly (ids 0..214 → parity); each family ≤ buffer cap (32); ids ≤ 255;
> free-space fit. **COLLECTIBLE vs SPECIAL clarified (user, do not re-derive from
> "looks empty"):** ids 0..214 are collectible (library-listed); ids 215..220 are REAL
> but non-collectible combat-only entities — 215 `TERRY?` (Durran story enemy), 216–219
> the four summon-skill tiers (Tatsu/Diago/Samsi/Bazoo), 220 reserved/blank — enumerated
> and PROTECTED (excluded, never a reassignment target). **Extension-aware (no hardcoded
> 221):** species id is 1 byte → 256 ceiling; `COLLECTIBLE_MAX`(→255) and `NUM_FAMILIES`
> (→11, B9) are the only knobs. **User decision (S19): Spirit will be ADDED as an 11th
> family (B9), then families reshuffled** — not a 10-family rename. Data deliverable
> `extracted/library_grouping.json`. Test ROM `065943f6…`; canonical clean build still
> `1ca6579…`. Method: KEY_LESSONS "Session 19 — Breeding B7".
>
> Last verified: 2026-06-18 (Session 18: breeding B6 — family reassignment +
> dynamic-library proof-of-concept, user-confirmed in SameBoy.)
> **B6 — family reassignment (SameBoy-confirmed) + dynamic-library POC.** Monsters
> can be moved between ANY families (incl. in/out of ??? / Boss=9) via same-size
> family-byte edits at `$03:$4461+$00`. `tools/build_family_reassign.py` (spec
> `extracted/breeding_family_reassign.json`, `from` validated == vanilla) emits
> `patches/bank_003.asm` (exact-line db edits, zero shift). **Reader gate CLEARED:**
> family-byte readers outside breeding are display/struct-copy only (banks
> `$01/$04/$07/$09/$14`); none gate scout/recruit/AI/resistance on family==9 —
> eligibility is the enemy-stats joinability byte (`$14 +$3`) + boss table
> (`$14:$4897`). **Three family representations** (BREEDING_SYSTEM "B6"): breeding =
> live byte; status/menus = struct `+$0A` stamped at creation (snapshot — correct
> for a fresh hack); library = id-range via `SetItem_6242`/`$12:$6294` (the ONLY
> id-range family assumption in the ROM). **Dynamic library = PROOF OF CONCEPT**
> (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
> redirected (zero-shift) to a family-byte scan in bank `$12` free space; 8
> reassigned monsters group correctly in SameBoy. POC only — lags ~221 far-loads/
> render (bearable), no RAM claim beyond one scratch byte. **Production plan (B7):
> editor emits a precomputed family→members table at build time; do NOT optimize the
> runtime POC.** Rename (B8) + 11th family (B9) split out in ROADMAP. Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `SetItem_6242`, the family-byte
> reader trace at bank `$03 label443f`. Patched test ROMs only; canonical clean build
> still `1ca6579…`. Method: KEY_LESSONS "Session 18 — Breeding B6".
>
> Last verified: 2026-06-18 (Session 17: breeding B5 — full special-table
> authoring DONE, user-confirmed in SameBoy.)
> **B5 — full special-table authoring (SameBoy-confirmed).** `build_breeding.py
> --emit-special` now OWNS the whole SPECIAL recipe table as authored data and emits
> it to bank `$69`. The base is the 825 vanilla entries decoded from the **ROM**;
> `extracted/breeding_special.json` supplies in-place `overrides` (edit any base
> entry — addressed by `{"index":N}` or by `{"match":{p1,p2}}` = first base entry that
> fires for that cross; absent fields inherit the base) and `appends` (new entries
> past 824, the B3 mechanism). A **whole-table first-match-wins shadow validator**
> replaces B3's append-only check: build-failing ERRORS on a shadowed append or a
> shadowed override; WARNINGS on an edit newly preceding a later different-result
> entry and on an override that changes a result species **other entries still
> produce** (so "edit a cross" ≠ "remove a monster"). **Single source of truth:**
> bank `$16`'s special table stays byte-identical to the ROM forever (already
> runtime-dead via the B2 `rst $10` redirect), so nothing in the shift-sensitive bank
> moves and there is one authored source + one emit target. Self-checks: emitted ==
> authored bytes + `$FF`; every non-overridden base entry == vanilla; each override
> present at its index; capacity ≤ 1650. User-confirmed in SameBoy: MadCat×BattleRex →
> DracoLord (in-place edit of entry 187, was Yeti; DracoLord id 200 used explicitly —
> two species share the name), Darkdrium×BattleRex → Armorpion (unshadowed append),
> Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides at dead
> entries 693/803). Patched ROM `c95f62ce…`; canonical clean build still `1ca6579…`.
> **B5 supersedes the B3 `--emit-relocation` + `breeding_extra_recipes.json` path** as
> the canonical bank `$69` emitter (the old index-825 DracoLord append is replaced by
> the cleaner entry-187 edit; DracoLord still reachable, no capability lost). Method +
> rules: KEY_LESSONS "Session 17 — Breeding B5" and BREEDING_SYSTEM "Planned". The
> actual recipe REWRITE (Spirit-as-breedable, new results) is authored by hand in the
> editor UI later — B5 is the machinery, not the content.
>
> **B4 — family-defaults rewrite (SameBoy-confirmed).** The FAMILY recipe table
> (`$16:$4974`, positional: offspring species == slot index) can now be authored
> in place via `tools/build_breeding.py --emit-family`, sourced from
> `extracted/breeding_family_defaults.json` (a `result→{p1,p2}` override list). The
> tool starts from the vanilla family decode, applies only the overrides, validates
> positional 1:1 (one cross per result species) + 444-byte zero-shift + shadow classes
> (special-table family-code shadow and duplicate family matchers), and rewrites only
> the `FamilyRecipeTable` db block in `patches/bank_016.asm`. Authored proof set is a
> zero-collateral permutation of the three Dragon-mate matchers plus one NEW recipe at a
> previously-empty separator slot: Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj,
> Beast×Dragon→Wyvern, Dragon×Dragon→GreatDrak (slot 37). Whole-ROM impact: **5 bytes**
> in bank `$16` + header/global checksum (focused diff vs the B3 ROM; B3 baseline rebuilt
> as the recorded `f1cd94b1…`). User-confirmed in SameBoy: FunkyBird×BattleRex→DrakSlime,
> Snaily×BattleRex→Almiraj, Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; canonical
> clean build still `1ca6579…`). Beast×Dragon→Wyvern is in the table but correctly
> shadowed for MadCat by SPECIAL entry 187 (MadCat×BattleRex→Yeti) — special > family
> precedence, not a bug. Untouched cross BattleRex×Healer→DragonKid (vanilla family slot
> 20) unchanged. Confirmed mechanics (grepped, do not re-trust): family scan does
> exact-species-immediate / family-code-last-wins with a two-pass (parent2 specific, then
> as family); `$FA` "AnyFamily" wildcard is scanner-supported but used ZERO times in vanilla
> data. Method + rules: KEY_LESSONS "Session 16 — Breeding B4" and BREEDING_SYSTEM "Planned".
>
> **B3 — special-recipe capacity extension (SameBoy-confirmed).** The relocated
> bank `$69` special table (B2) now grows past the 825 vanilla entries: its
> scanner walks to the `$FF` terminator with no hardcoded count, so
> `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json`
> after the 825 base entries and re-terminates. Capacity ceiling `SPECIAL_CAPACITY_MAX
> = 1650` (2× vanilla); bank `$69` (16 KB) fits it with headroom. Proof recipe at
> index 825: **BattleRex(Pedigree) × MadCat(Mate) → DracoLord** — chosen because
> it is UNSHADOWED by all 825 base entries (the forward order MadCat×BattleRex is
> the vanilla → Yeti recipe at index 187, so it would win first); user-confirmed
> DracoLord in SameBoy (patched ROM `f1cd94b1…`; canonical clean build still
> `1ca6579…`). Tool self-checks: base 825 == patched bank_016 table, S12 recipe
> intact, appended bytes placed + `$FF`-terminated, and an emit-time SHADOW CHECK
> that FAILS the build on a dead (already-matched) appended recipe. Focused diff:
> 4 bank-`$69` bytes + header checksum, nothing else. Method + rule: KEY_LESSONS
> "Session 15 — Breeding B3" and BREEDING_SYSTEM "Planned: Overhaul & Extension".
> Forward plan signposted there + ROADMAP Phase 2B (B4/B5/B6) after a ??? mechanic
> audit (see below).
>
> Session 14: bank $0B repointing — breeding-cutscene glitch FIXED.
> **Bank $0B dynamic-repointing completed.** The breeding-cutscene parent-sprite
> glitch (wrong monster, correct palette) and a parallel gate-table glitch were
> caused by three un-labelized raw pointer refs into bank $0B's shift region
> (`$4974` sprite table; `$42c8`/`$4308` gate table with raw `dw` entries). Labelized
> in the disassembly first (clean build still `1ca6579…`), then ported to
> `patches/bank_00b.asm` — where the sprite ref was additionally found **mislabeled**
> to `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`), and
> repointed. User-confirmed in SameBoy: breeding cutscene clean; custom rooms
> `$6B`/`$6C` + custom→custom transitions working (patched ROM `b43a04fe…`; canonical
> clean build still `1ca6579…`). No trampolines — pure dynamic repointing. Custom
> banks are 100% label-based (repointable by construction). Remaining hardcoded
> repointing refs: `$08:$7751`, `$32:$5A5F` (latent — banks not patched). Method
> + rule: KEY_LESSONS "Session 14 — Bank $0B repointing" and SESSION_PROTOCOL §4.
>
> Session 13: breeding B1 + B2 DONE.
> **B2 — special-table relocation harness (SameBoy-confirmed).** The special
> scan moved from bank $16 to free bank `$69`, called via `rst $10`
> (`ld hl,$6900`); the 30-byte scan at $16:$46F2–$470F replaced in-place with
> `ld hl,$6900`+`rst $10`+26-byte NOP pad (zero shift), falling into the
> unchanged plus-clamp at $4710. `patches/bank_069.asm` (faithful scanner port
> + special table) is generated by `build_breeding.py --emit-relocation`,
> sourcing the table from the **patched** `bank_016.asm` so existing custom
> recipes survive. Verifier PASS 4/4; full-ROM diff: bank $16 changed only in
> the 30-byte window. User-confirmed: Anteater×BattleRex→GoldSlime both orders,
> vanilla crosses unchanged, saving OK (patched ROM 868f9276…, patched-build
> artifact only — canonical clean build is still 1ca6579…). Open follow-up:
> breeding-cutscene parent sprites glitch — NOT from B2 (graphics path; B2 only
> writes result RAM), suspected pre-existing earlier-patch regression; logged in
> ROADMAP with a bisect plan. **RESOLVED in Session 14** — see top entry (it was an
> incomplete bank $0B labelization, not a breeding-path regression).
> **B1 — breeding round-trip encoder (keystone).** `tools/build_breeding.py --selftest` decodes BOTH vanilla tables
> and re-emits them byte-identical to the ROM (special $4B30 4126 B incl $FF;
> family $4974 444 B incl $0000); db-text emission re-parses to the same bytes;
> disassembly db == ROM (--check-disasm). Decode independently reconciles with
> hand-authored breeding_complete.json (825/825 special, 197/197 family slots, 0
> diffs). Data deliverable extracted/breeding_tables.json (Tier A, _generator).
> Pure tooling — no ROM change; clean build still 1ca6579…; verifier PASS 4/4.
> Unblocks B2-B6. NOTE: B1 is a tool+data keystone, not a content patch — nothing
> to playtest; acceptance is fully machine-checkable.
> Prior — Session 12: custom breeding PROVEN — special-recipe
> override Anteater × BattleRex → GoldSlime via same-size, in-place edit of two
> provably-dead table entries; confirmed in-game in SameBoy. Tool
> `patch_breeding_recipe.py` + `patches/bank_016.asm` (bank $16 added to the
> verifier patch set). Romhack-scale breeding overhaul + extension specced
> (BREEDING_SYSTEM "Planned: Overhaul & Extension" + ROADMAP Phase 2B): defaults
> rewritten in place, special table relocated to free bank $69 via rst $10 and
> extended to 1×–2× (~1650). Family table is positional (result = slot index) —
> documented. The keystone round-trip encoder B1 is now built (above).
> Prior — Session 11: random encounters PROVEN in a custom
> non-gate room (Strategy A) — whitelist mapID in $0B:Jump_00b_4674 + pin
> wGateID/wCurrentFloor in ASM + arm wEncounterCounter from the room-entry
> script. Pool fully controllable via gate/floor; win+flee return clean.)

---

## Part 2 — Resolved documentation defects (moved from PROJECT_STATE, 2026-07-02)

All items below are RESOLVED; kept verbatim for forensics. Open defects live in
PROJECT_STATE.md "Open defects".

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
- ~~Room $6C step counter addresses $D9A0-$D9A2 collided with event flags~~
  → **Fixed.** $D9A0 = byte 5 of wEventFlags (boss defeat flags $0028-
  $002F: DracoLord, Zoma, Baramos, Pizzaro, Esterk, etc.), $D9A1 = byte 6
  (story flags $0030-$0037 with up to 62 uses each), $D9A2 = byte 7
  (MedalMan, Castle flags $0038-$003F). Writing step counter values there
  would clobber critical game state. Never triggered in practice because
  CustomPtrChase ignored step counters. Fixed by moving all custom step
  counters to $D478-$D47B (verified-unused WRAM gap). Room $6B's $D95E
  (shared with MedalMan original) also moved to $D478.
- ~~Room $6B NPCs blocked exit to Room $6C~~ → **Fixed (v25).** Egg giver
  at (3,3) and BGM changer at (1,4) removed; a prior session had moved
  them into positions that blocked the walkable path to the (3,1) exit
  without updating docs. Item giver at (2,2) retained.
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
- ~~KEY_LESSONS claimed ROM palette pointers had "bit 15 set" as encoding
  marker~~ → **Corrected (Session 9).** Zero step-0 palette pointers have
  bit 15 set (verified all 107 entries). The actual issue: ROM palette bytes
  at `pal_ptr` are in an engine-internal format for ALL rooms, not just some.
  The game engine always transforms them at runtime. Editor tileset PNGs now
  use `room_palettes.json` (runtime-dumped data) via `regenerate_tileset_pngs.py`.

---

## Part 3 — Archived ROADMAP detail (verbatim narratives from completed items)

Cut from ROADMAP.md on 2026-07-02 (S51 consolidation). Each completed item now
carries a short evidence+pointer stub in ROADMAP; the full original narrative
is preserved here, grouped by item.

### Archived PROJECT_STATE dashboard rows (verbatim, replaced by compressed rows 2026-07-02)

| Add NEW monster species (ids 224–255) | 🟡 working POC (S30): id 224 Gorbunok playable | ROADMAP "Phase N"; mechanics MONSTER_DATA "Species ID geography". N1 scope ✅, N2 info-fork ✅ (`build_new_species.py`→`bank_06a`, `SaveMon_4446` zero-shift, vanilla 0–220 byte-identical), N3 enemy-stats ✅ (16-bit EID → no fork, EID 518 @ `$14:$7EB3`) + wild encounter ✅ (pool 0 slot 3, same-size `EncounterPoolData` edit in `bank_001`), name ✅ ("Gorbunok"), library ✅ (`build_library_table.py --new-species`, unseen-marker `$E0`→`$FE`). All tool-owned/reproducible. **S32 (user-tested):** N5 breeding DONE — Snaily×BattleRex→Gorbunok (special append, `build_breeding.py` admits new-species results), parent-path free via Slime family, recipe icons via `FamilyRecipeResolve`. Hatch crash (bank `$0b` follower overshoot, pinned in SameBoy) fixed (`FollowerArtResolve0b`). Default-nickname+narration "SkyBell" overshoot fixed → "Gorb" first-4 via `LoadModeBaseRedirect` ($00F0 ROM0 padding) → new-species short-name at `$41:$7FF9`. N4 follower ART integrated via `build_new_species_follower.py` (real W.png art, gid `$7e00`, all 8 contexts) — **baked into `patches/` (G1, S34).** **S35 (user-confirmed):** G2 battle sprite DONE — `MonsterBattleGfxTable[224]` `$320f`→`$7e01` (same-size repoint, real slot, no fork), dragon battle pose = 2nd overflow entry `$7e01`, palette reader `label17_41d0` forked to `HighBattlePal` (custom blue palette). **S38 (user-confirmed):** lineage parent-name DONE — line-1 mode-0 wired (`HighModeTable4D`→`HighMode0Ptrs`→`GorbunokRecipeLine` "Snaily   BattleRex", `patches/bank_04d.asm`), so the library/encyclopedia lineage no longer shows "?????". **Open:** `new_species.json` schema fold (G3) — now the only remaining new-species item. |
| Custom rooms (mapID ≥ $6B), multi-screen, exits | ✅ working | patches/bank_060.asm + intercepts. Multi-screen scrolling proven (v28): vertical 2-screen Room $6B (screens 0+4). Room dimensions in $26DD bytes 2-5 control walkable area. **S39: Room $6B can render the gate maze tileset** (gfx-ID `$280D`) with the gate floor palette — sandy island, tree/dune/pit metatiles; `tools/build_gate_room.py` → `bank_064.asm`. (GATE_GENERATION.md §7.2–7.3.) **S40 (Pillar A, user-confirmed in-game): custom-room RENDER is now fully table-driven by `mapID-$6B`** — no hardcoded `cp $6B` render intercepts remain. Two bank-`$17` tables (`CustomRoomPalPtr` = `dw` per room, `CustomRoomAttr` = `db bank,base_entry` per room) drive palette + attr; `CustomGFXMapID` widened `cp $6C`→`cp $70` so each of `$6B-$6F` indexes its **own** `$26DD` tileset/threshold record. Proven by a **second custom room `$6C`**: same gate-island layout/tileset/attr as `$6B`, distinct **moonlit-night palette**, entirely from the tables, zero new render code. System scales to ~140 rooms (`$6B-$FF` minus reserved; `$70+` needs a `$26DD` intercept — Pillar B follow-up). See GATE_GENERATION.md §7.4 + KEY_LESSONS S40. |

| Custom breeding recipes (special table) | ✅ working (same-size edit + capacity extension) | v31/S12: special-recipe override (Anteater×BattleRex→GoldSlime) via two provably-dead entries; in-game confirmed. Tool `patch_breeding_recipe.py`, `patches/bank_016.asm`. Family table is positional (result=slot index). **S13: round-trip encoder B1 built** (`tools/build_breeding.py`, `extracted/breeding_tables.json`) — both vanilla tables decode/re-emit byte-identical. **S13: B2 relocation** (special scan → free bank `$69` via `rst $10`). **S15: B3 capacity 1×–2×** — `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json` past index 824 (cap 1650); BattleRex×MadCat→DracoLord confirmed in-game. **S16: B4 family-defaults rewrite** — `build_breeding.py --emit-family` authors the positional family table in place from `extracted/breeding_family_defaults.json`; Bird/Slime/Beast×Dragon + new Dragon×Dragon→GreatDrak confirmed in-game (5 bytes, zero-collateral). **S17: B5 full special-table authoring** — `build_breeding.py --emit-special` owns the WHOLE special table as authored data (825 ROM base + in-place `overrides` by index/parents + `appends`) from `extracted/breeding_special.json`, with a whole-table first-match-wins shadow validator; bank `$16` stays vanilla (single source = JSON → bank `$69`). Confirmed in-game: MadCat×BattleRex→DracoLord (entry-187 in-place edit), Darkdrium×BattleRex→Armorpion (append), S12 GoldSlime preserved. Supersedes the B3 `--emit-relocation` path. **S18: B6 family reassignment** — `build_family_reassign.py` moves monsters between ANY families (incl. ???/Boss=9) via same-size family-byte edits (`patches/bank_003.asm`); reader gate cleared (display/copy only, eligibility is joinability+boss table, not family). **S18: dynamic-library POC** — `build_dynamic_library.py` redirects `SetItem_6242` ($12) to a family-byte scan so the library groups by reassigned family (`patches/bank_012.asm`); user-confirmed, POC only (lags). **S19: B7 production library grouping (DONE, replaces the POC)** — `build_library_table.py` emits a build-time precomputed family→members table into bank `$12` free space + a zero-shift `SetItem_6242` walker; **zero far-loads, zero scratch RAM**, vanilla blank-slot semantics restored; generic-N (`NUM_FAMILIES`) + 256-id-ceiling extension-aware; special entries 215–220 protected; `extracted/library_grouping.json` data deliverable; user-confirmed in SameBoy (zero lag). Production library now done; 11th family (B9) data side unblocked. Rename (B8) folded into B9 per user decision. |

| Custom battle skill EFFECTS (net-new ids) | 🟢 Skill #1 LIVE end-to-end (S49, user-confirmed in SameBoy); system generalizes next (S2e) | **S2 is an ARC, not done.** (1) **Alias framework (S45, POC):** net-new ids ($DE Scorch, $DF Smite) on starter EID 1, templatized to Blaze at the action-queue commit; real id stashed in `$db86`; custom effect via `FarSkillFork` (bank `$72`) → `CustomSkillTable52` (`$52:$7FED`); names via `SkillNamePtrTable`. Single-caster, Blaze-shaped only. (2) **Presentation foundation (S46):** the skill RECORD table (`$54:$4013`→`$41CF`, 222×19B) decoded + round-tripped byte-identical + re-sectioned to `db`; field map FAQ-validated (power/targeting/MP/status/ai_weight); item-effect+meat system (`$52:$4625`, meat→`$58:$591E`); animation dispatch (descriptor-setters `$52:$5460–$54f8` → `$dd6f`/`$dd70` → bank `$4c`/`$55`). Handler=effect TYPE (shared), record=per-skill params. **Full RE + field tables + confidence + known limitations: `BATTLE_SKILL_SYSTEM.md` (read §⚠️ + §7–§11 before extending).** (3) **Animation renderer (S2c-anim, 2026-06-28, emulator-verified):** the 3 presentation layers (sprite-anim metasprite engine, sound+flash, vertical shake) fully mapped — see §11. (4) **De-aliasing FOUNDATION (S48, byte-neutral):** complete skill-id bucketing map (`$db8a`, 254 reads/9 banks) → the surface reduces to a verified fork set; **keystone = the record-table indexer `$54:$4013` (3 sites `$5251/$5276/$529E`), forking it fixes magnitude/targeting/MP/status/ai_weight + the enemy AI**; HW-confirmed via `$52:$66D9`; the `$535F` divert is a minor path; keystone fork PROVEN byte-neutrally implementable (5-byte `call Fork` trampoline, in-bank tables). Tool `tools/map_skill_id_buckets.py` → `extracted/skill_id_bucket_map.json`; full RE **§12**. (5) **Skill #1 SHIPPED (S2d, S49):** MagicBurn (`$E0`) non-aliased & complete — record+handler+name+announce+animation+flash+SFX, all via clean indirection (announce table `$58:$5806`; custom message pool `$4c:$7326`; `GetPresentId` presentation proxy in `$5f`). The `$5f`-cleanup anim blocker is **resolved**. Full system + how-to-add-a-skill recipe: **`BATTLE_SKILL_SYSTEM.md` §13**. **OPEN:** S2e custom skill #2 (prove a non-damage/heal shape generalizes); minor follow-ups in §13.4 (custom-id skill-name insert; 2nd bespoke-message render path). |


| System | Blocker |
|--------|---------|
| Random encounters in custom rooms | ✅ PROVEN (Strategy A, Session 11). Mechanism: encounters are gated per-step by a mapID whitelist in `$0B:Jump_00b_4674` (NOT by `wInGateworld`); whitelisting a custom mapID enables them. The battle pool is `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a non-gate room must pin `wGateID`/`wCurrentFloor` (done in ASM every step) and arm `wEncounterCounter` (room-entry script, since vanilla skips seeding when `wInGateworld=0`). Win+flee return clean; saving still works (no gate mode). **Remaining (editor):** #1 per-room on/off + gate/floor table, #2 custom pools — both specced in CROSSBANK_ROOMS.md, not yet generalized. |
| Custom tile GRAPHICS | Palette attributes fixed (v28). Multi-tileset mashup pipeline working end-to-end (Session 7): editor exports JSON → `build_combined_tileset.py` → ROM patches → playable room with tiles from 4 source tilesets (80 tiles). K-means palette grouping replaced with exact-color matching (10 groups for NORDEN). Game engine forces BG palette color index 1 to shared value ($6BFF) at runtime — build tool swaps EXT palette indices 0↔1 to work around this. Castle VRAM animation at tile indices 77-78 avoided by inserting blanks. Editor has live palette slot counter (X/8) with export validation. **Session 9**: editor tileset PNGs regenerated with runtime-correct palettes via `regenerate_tileset_pngs.py` (all 86 tilesets, using `room_palettes.json`). Force-preview toggle shows colour index 1 marker tint. `--build` flag validated end-to-end (editor export → patched ROM → clean restore). **Session 10**: multi-screen ROM patches working — per-screen layout+attr in bank $64, screen-aware CustomAttrCheck in bank $17, room height in $26DD table. **Remaining**: editor multi-screen UI (screen selector, per-screen canvas, exit/NPC placement); `build_combined_tileset.py` multi-screen export. |
| Custom music | Sound engine unexplored |
| Save-data audit | ✅ Completed Session 8. SRAM save layout fully traced and documented in ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 are in save range. Flag byte collisions mapped. Flag $0158 tested in SameBoy: set via NPC script, persisted through save+reload. |



### Archived ROADMAP narratives — Phases 1 / 2B / 2C (cut 2026-07-02)

### Phase1: NPC show/hide

- [x] **NPC show/hide by flag** — mechanism IS the step system
      (ROOM_DATA_FORMAT.md "Room State System"): multiple step entries
      per screen with different NPC lists, step counter set by opcode
      $12 (WriteRAM $D9xx). **Implemented and confirmed in-game (v25)**:
      CustomPtrChase now reads RAM step counter and indexes by ×6
      (was always returning step 0). Room $6C screen 0 has 2 step
      entries — Gatekeeper NPC at step 0 (advances counter via opcode
      $12) replaced by Guard NPC at step 1. Verified: NPC changes on
      re-entry after WriteRAM sets counter. Step counter addresses
      moved from event-flag collision zone ($D9A0-$D9A2 = flags
      $0028-$003F) to safe range $D478-$D47B. Note: $D478+ not in
      SRAM save range — step progress resets on power cycle; for
      persistence, use event flags + room-entry flag checks.
      *Accept*: NPC appears only after custom flag/step is set; verified
      after room re-entry. ✅


### Phase1: monster/egg give

- [x] **Monster/egg give** — opcode $29 (AddMonster) **confirmed working**.
      Takes 1 param (enemy_stats_id). Opcode $28 (CheckStorageFull)
      branches when all 20 slots full. Egg give proven with SkyDragon
      (EID 350, same as Farm event) — egg appears at farm, hatches
      correctly (minor cosmetic glitch on hatch). Direct monster give
      (EID 1) creates a withdrawable monster but species/stats don't
      fully initialize without `$FF04 $000F` preamble. Egg path is
      the practical choice for custom content.
      AddMonsterWrapper needed in bank $04 padding (bare `ret` →
      wrapper + `jp ScriptExecContinue`, same fix as GiveItem $2A).


### Phase1: tile layouts

- [x] **Custom tile LAYOUTS** (compressor done): place compressed layouts
      in a free bank, point step_entry byte 1 at it.
      **Done.** `tools/tile_layout_compiler.py` compiles 20×16 visible
      tile grid → 32×16 padded → LZSS compressed → ASM db statements.
      Bank $64 holds custom layout data with pointer table at $4001.
      Room $6B step entry uses `db 0,$64`. Tileset switching via
      MapIDClampForPalette in ROM0 (currently $04=Farm). User-designed
      layout confirmed in-game. Standalone HTML editor with 170 rooms
      and 85 tilesets delivered (towards_editor/). Spawn position for
      Room $6B is in Exit_GreatTree_s8 (bank_00b.asm), currently (7,6).
      *Accept*: custom room renders a layout that exists nowhere in the
      original ROM. ✅ Confirmed in-game.
      **Known issue (FIXED v28)**: palette attributes were per-position,
      causing color mismatches. Fixed by CustomAttrCheck intercept in
      bank $17 free space ($6C75): for Room $6B, bypasses vanilla attr
      lookup and decompresses custom nibble-packed attr data from bank
      $64 entry 1. Attr data generated by `tools/generate_attr_map.py`
      which builds tile→palette maps from ROM for any of the 85 tilesets.
      Collision threshold table at ROM0 $26E3 uses ×8 stride (not ×1).
      Multi-tileset HTML editor delivered (towards_editor/) with
      walkability overlay, variable-size stamps, marker management,
      tileset names, and full source-mapping export.


### Phase1: tile graphics

- [x] **Custom tile GRAPHICS**: palette attribute intercept DONE (v28).
      Single-tileset rooms fully working (tileset switch + correct palettes).
      **Multi-tileset mashup: WORKING (Session 7, refined Session 8).** Full pipeline:
      editor → JSON export → `build_combined_tileset.py` → ASM patches → ROM.
      **Session 8 critical discoveries and fixes:**
      - **4 palette groups max** (not 8). BG slots 4-7 reserved by game engine
        for monster display (4/5/6) and menu text (7). Verified: all 85 DWM1
        tilesets use max group 3. CustomPalCheck changed B=$08→$04.
      - **Gate detection in banks $06/$07**: mapID≥$50 whitelists treated custom
        rooms as gate-like (blocked saving, wrong menu state). Fixed with
        same-size `ld a,[wMapID]`→`call MapIDClampForPalette` patches.
      - **Ghost NPC**: spawn point script_id=$01 was talkable. Fixed to $00.
      - **Build automation**: `--build OUTPUT.gbc` flag added to
        `build_combined_tileset.py` (patches palette+threshold, builds ROM,
        restores tree). **Validated Session 9** — end-to-end pass with
        3-tileset test export (MedalMan+NORDEN+Farm).
      - **Editor**: PalGrp toggle shows palette group per tile (P0-P3 custom,
        S4-S9 system). Counter shows X/4. Export warns if >4.
      *Accept*: custom room shows tiles cherry-picked from 2+ source tilesets. ✅
      **Session 9 fixes:**
      - Editor tileset PNGs regenerated with runtime-correct palettes from
        `room_palettes.json` via new `regenerate_tileset_pngs.py` tool (86
        tilesets, all verified). ROM step-entry palette data is encoded (not
        raw RGB15) — was causing wrong colours for Starry Shrine and others.
      - Force-preview toggle ("Frc" button) added: swaps between runtime view
        ($6BFF at colour index 1) and marker-tint view (light cyan at index 1).
      - KEY_LESSONS corrected: "bit 15 set" palette claim was wrong — actual
        issue is that ROM palette bytes are always transformed at runtime.


### Phase1: random encounters

- [x] **Random encounters in custom rooms** — ✅ PROVEN (Strategy A,
      Session 11; runtime-verified in SameBoy). The blocker assumption was
      wrong: encounters are NOT gated by `wInGateworld`. They are gated
      per-step by a hardcoded mapID whitelist in `$0B:Jump_00b_4674`
      (`$53`,`$54-$56`,`$57-$59`,`$61-$64`); non-whitelisted normal rooms
      `ret` before the encounter step. **Recipe:** (1) add the custom mapID
      to that whitelist → enables battles; (2) the pool is
      `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a
      non-gate room must pin `wGateID`/`wCurrentFloor` (done every step in
      ASM — they're read only when a battle fires) and (3) arm
      `wEncounterCounter` from the room-entry script (vanilla skips seeding
      when `wInGateworld=0`). Trigger chain: counter underflow → `rst $10`
      bank $01 entry $0b (`EncounterMonsterSelect`) → `set 6,[wGameState]`.
      *Verified*: Room $6B, gate 0/floor 1 → pool 0 (Slime/Anteater/Dracky);
      `$C935=00 $C939=01 $CA38=00`; win+flee return intact, saving works.
      Full docs: DATA_STRUCTURES "Encounter Runtime Flow", CROSSBANK_ROOMS
      "Random Encounters in Custom Rooms", KEY_LESSONS Session 11.
      **Remaining → moved to Phase 2 (editor):** #1 per-room on/off + gate/floor
      table; #2 fully custom monster pools in a free bank. Both specced in
      CROSSBANK_ROOMS.md.


### Phase2C: gate rotation

- [x] **Custom room into the gate rotation** — TWO halves (BOTH done; Pillar A render S40, Pillar B insertion S41):
   - [x] **Rendering half (S39 + S40 generalisation).** Room `$6B` renders the
         Gate-of-Beginning maze tileset (gfx-ID `$280D`, bank `$28` step `$0D`) with
         the real gate floor palette — sandy island with ocean-wall border, 2×2
         tree/dune/pit metatiles, per-position attr palette. Authored in
         `tools/build_gate_room.py` → `patches/bank_064.asm` (+ `bank_000.asm`
         gfx-ID/threshold, `bank_017.asm` `CustomPaletteColors_6B`, slots 0–3 only).
         **S40 (Pillar A, user-confirmed):** render is now fully **table-driven by
         `mapID-$6B`** — `CustomRoomPalPtr`/`CustomRoomAttr` tables (bank `$17`) +
         per-room `$26DD` records via `CustomGFXMapID` widened to `cp $70`; no
         hardcoded `cp $6B` render code remains. Proven by a 2nd room `$6C` (same
         island, distinct moonlit palette, zero new code). `$6B` byte-identical
         regression verified; verifier PASS. (GATE_GENERATION.md §7.1–7.4.)
         **S42 generalisation:** the old `$6B-$6F` `$26DD`-record ceiling is lifted —
         `$70+` rooms read their record from `Custom26DDTable` (bank `$71`, far-copied
         to `wRoomRecScratch`). See EDITOR_DESIGN.md §2 (keystone, as-built) + Phase 2.
   - [x] **Insertion half (= "Pillar B", S41, user-confirmed in SameBoy).** Custom room
         `$6D` inserted into **gate 1 (Gate of Villager)**, descending floor-to-floor with the
         correct in-gate transition feel. Mechanism chosen was **not** the `rst $00` slot below
         but a cleaner **byte-neutral fork at the gate-branch decision**: the 6-byte gate-0
         exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf` — it reads
         **`wGateID $C935`**, the earlier `wCurrentFloor` cite was wrong) is replaced in place
         by `call GateDecisionFork`+3 nops; the fork routes gate 0 → vanilla maze, gate 1 →
         `CustomGate1Setup` (`wMapID=$6D`), all others → untouched RNG gating. Descent uses a
         `gate_flag=$80` exit (mirror of special rooms `$50/$51`). The descent **transition feel**
         (whoosh + continuous BGM, not the hub→gate dissolve + BGM restart) is fixed by a transient
         `wInGateworld=$01` set **only during the transition** (`CustomDescentInGate` @ `$0B`
         `jr_00b_466b`); display-time `wInGateworld` must stay `0` or the room engine's gate/maze
         branches freeze the game. Test ROM `DWM-gate-rotation-v3.gbc`. (GATE_GENERATION.md §7.5.)
         *Alternative/general mechanism still valid for many-room rotations:* point a `rst $00`
         dispatch slot (`$16:$5C32` table, ROM-verified idx0=`$5C42`) at a custom-id handler and
         open its `FloorTypeSelectionTable2` weight. POC forces `$6D` every non-boss floor;
         occasional placement = gate the fork branch behind the RNG roll / a weight table.


### Phase2C: palette derivation

- [x] **Room-palette derivation from ROM (S39).** `tools/derive_room_palette.py`
      reproduces any room's runtime BG palette: colours 0/2 from the room/gate
      palette pointer (`$17:$476F` normal / `$17:$51F5` gate), engine-forced
      idx1=`$6bff`/idx3=`$0000`, screen-scan, clean refusal when unresolvable.
      Validated 30/30 SameBoy dumps + the gate floor. (GATE_GENERATION.md §7.1.)


### B1

- [x] **B1 — Round-trip encoder (keystone).** `tools/build_breeding.py` decodes
      + re-emits BOTH vanilla tables. *Accept:* `$4974`+`$4B30` byte-identical to
      ROM; clean build still `1ca6579…`; verifier PASS. (Decoder half done S12.)
      **DONE (Session 13):** `tools/build_breeding.py --selftest` proves both
      tables round-trip byte-identical to the ROM slices (special $4B30 4126 B
      incl $FF; family $4974 444 B incl $0000), the `db`-text emission re-parses
      to the same bytes, and the disassembly `db` bytes equal the ROM
      (`--check-disasm`). Decode independently reconciles with the hand-authored
      `breeding_complete.json` (825/825 special, 197/197 family slots, 0 diffs).
      Data deliverable: `extracted/breeding_tables.json` (Tier A, `_generator`
      stamped). Verifier PASS 4/4; clean build unchanged. Family encoding
      confirmed positional (result species == slot index; 197 recipes + 24
      separators + 1 terminator = 222 pairs).


### B2

- [x] **B2 — Relocation harness.** Bank `$69` scanner + special table mirrored
      there; bank $16 redirected via `rst $10`; vanilla tables left in place.
      *Accept:* breeding identical to vanilla (regression) in SameBoy; saving OK.
      **DONE (Session 13):** special-table scan ($46F2–$470F, 30 B) replaced
      in-place with `ld hl,$6900` + `rst $10` + 26-byte NOP pad (zero shift);
      faithful port of the scan loop + per-entry check in `patches/bank_069.asm`
      (`db $69`, jump table, scanner, then the table). `rst $10` ABI decoded
      from ROM bytes (H=bank, L=entry<$80; far func ends `ret` → returns to the
      bank-$16 plus-clamp at $4710). Relocated table sourced from the **patched**
      `bank_016.asm` (via `build_breeding.py --emit-relocation`), so it carries
      existing custom recipes. Verifier PASS 4/4; full-ROM diff shows bank $16
      changed only in the 30-byte window. User-confirmed in SameBoy: Anteater×
      BattleRex→GoldSlime (both orders) + vanilla crosses unchanged; saving OK.
      *Note:* rev 1 wrongly sourced the table from vanilla and silently reverted
      the Session-12 recipe (parents fell through to the family table); fixed by
      sourcing from patched bank_016. The `--emit-relocation` self-check now
      asserts relocated == patched table.


### B3

- [x] **B3 — Capacity 1×–2×.** Raise special capacity to ≥1650; add recipes past
      index 824. *Accept:* a recipe at index >824 fires in-game.
      **DONE (Session 15):** the bank `$69` scanner walks to the `$FF` terminator
      with no hardcoded count, so `build_breeding.py` appends recipes from
      `extracted/breeding_extra_recipes.json` after the 825 base entries and
      re-terminates (`SPECIAL_CAPACITY_MAX = 1650`; bank `$69` fits 2× with
      headroom). Proof recipe at index 825: **BattleRex(Pedigree) × MadCat(Mate)
      → DracoLord** — user-confirmed DracoLord in SameBoy (patched ROM
      `f1cd94b1…`; clean build still `1ca6579…`). Picked because it is UNSHADOWED
      by all 825 base entries (the forward order MadCat×BattleRex is the vanilla
      → Yeti recipe at index 187, which would win first — see KEY_LESSONS S15).
      Self-checks: base 825 == patched bank_016 table; S12 recipe intact; appended
      bytes placed + `$FF`-terminated; emit-time SHADOW CHECK fails the build on a
      dead appended recipe. Focused diff: 4 bank-`$69` bytes + checksum.
      *Open follow-up:* fold "base 825 of relocated table == patched bank_016
      table" into `verify_integrity.py` so future table edits can't silently
      diverge (the tool asserts it; the verifier does not yet).


### B4

- [x] **B4 — Family-defaults rewrite.** New family×family map compiled in-place
      (family table `$16:$4974`, same length = zero shift; result = slot index, so
      the compiler inverts `A×B→C` to slot order and rejects positional conflicts;
      preserve the `$FA` wildcard + two-pass search). *Accept:* 8–10 sample crosses
      give NEW results in SameBoy; untouched crosses unchanged. *Note:* family
      table is strictly 1:1 (one cross per result species, no many→one) — put
      flexible/many→one family×family in the SPECIAL table instead (works now).
      **DONE (Session 16, user-confirmed in SameBoy).** `build_breeding.py --emit-family`
      reads `extracted/breeding_family_defaults.json` (positional `result→{p1,p2}`
      overrides), applies them to the vanilla family decode, validates positional 1:1 +
      444-byte zero-shift + shadow classes, and rewrites only the `FamilyRecipeTable` db
      block in `patches/bank_016.asm`. Authored proof set (zero-collateral permutation of
      the three Dragon-mate matchers + one NEW recipe at empty separator slot 37):
      Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj, Beast×Dragon→Wyvern,
      Dragon×Dragon→GreatDrak. **5 changed bytes total** in bank `$16` (focused diff vs the
      B3 ROM = those 5 + 1 checksum byte; the B3 baseline rebuilt as the recorded `f1cd94b1…`).
      User-confirmed: FunkyBird×BattleRex→DrakSlime, Snaily×BattleRex→Almiraj,
      Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; clean build still `1ca6579…`).
      Beast×Dragon→Wyvern is present but correctly shadowed for MadCat by SPECIAL entry 187
      (MadCat×BattleRex→Yeti) — precedence, not a bug. Untouched BattleRex×Healer→DragonKid
      (vanilla family slot 20) unchanged. Method + precedence: KEY_LESSONS "Session 16".


### B5

- [x] **B5 — Full special-table authoring + overhaul spec.** Extend
      `build_breeding.py` to own the WHOLE special table as authored data (base +
      overrides + appends) and emit it to bank `$69`, leaving bank `$16` fully
      dead; supports edit-in-place of any base entry (e.g. **replace Yeti** =
      change entry 187 result byte) and append. Includes a precedence/shadow
      validator (first-match-wins across the whole table). Author the complete
      `special` + `family_defaults` (incl. Spirit-as-a-breedable-family), build a
      test ROM. *Accept:* user playtest sign-off on the rewritten recipe set.
      **DONE (Session 17, user-confirmed in SameBoy).** `build_breeding.py
      --emit-special` decodes the 825 vanilla entries from the ROM as the base,
      applies `overrides` (edit any entry, by `index` or by parent `match`) and
      `appends` from `extracted/breeding_special.json`, runs a whole-table
      first-match-wins shadow validator (ERRORS on a shadowed append/override;
      WARNS on new collateral shadowing and on a result-species change that other
      entries still produce), and emits only `patches/bank_069.asm`. Bank `$16`'s
      special table stays byte-identical to the ROM (single source = JSON → bank
      `$69`). Self-checks: emitted == authored bytes + `$FF`; untouched base ==
      vanilla; overrides present at their indices; capacity ≤ 1650. Proof
      (confirmed): MadCat×BattleRex → **DracoLord** (in-place edit of entry 187,
      was Yeti), Darkdrium×BattleRex → **Armorpion** (unshadowed append),
      Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides
      at dead entries 693/803). Patched ROM `c95f62ce…`; clean build still
      `1ca6579…`. **Supersedes B3's `--emit-relocation` + `breeding_extra_recipes.json`
      as the canonical bank `$69` emitter.** *Note:* the spec carries `base`,
      `overrides`, `appends`; this is the editor's emit backend — the actual recipe
      REWRITE (Spirit-as-breedable, new results across the board) is authored by hand
      in the editor UI later (B5 delivers the machinery, not the content).
      *Folded into `verify_integrity.py`? No — see B3 open follow-up; the tool
      self-asserts, the verifier does not yet run `--emit-special` self-checks.*


### B6

- [~] **B6 — Family reassignment + ??? → "Spirit".** Same-size family-byte edits
      (offset $00 of each 43-byte monster-info entry `$03:$4461`).
      **REASSIGNMENT DONE + reader-gate CLEARED (Session 18, user-confirmed in
      SameBoy).** `tools/build_family_reassign.py` (spec
      `extracted/breeding_family_reassign.json`, validated `from`==vanilla) emits
      `patches/bank_003.asm` as exact-line db edits (zero shift). Monsters move
      between ANY families incl. in/out of ??? (Boss=9). **Reader trace (the gate)
      cleared:** family-byte readers outside breeding are DISPLAY/struct-copy only
      (bank `$01` battle copy, `$04` FamilyTextPtrTable text dispatch, `$07`
      sprite/icon, `$09` VRAM index, `$14` recruit stamp); none gate scout/recruit/
      AI/resistance on family==9 — eligibility is the enemy-stats joinability byte
      (`$14 +$3`) + boss table (`$14:$4897`), independent. Annotated inline at bank
      `$03` `label443f`. **Three family representations found** (BREEDING_SYSTEM
      "B6"): breeding=live byte; status/menus=struct +$0A stamped at creation
      (snapshot — pre-existing monsters keep old value, correct for a fresh hack);
      library=id-range (see below). **Dynamic library PROOF OF CONCEPT done**
      (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
      redirected to a family-byte scan; all 8 reassigned monsters group correctly
      in SameBoy. POC only (lags ~221 far-loads/render; bearable). *Still TODO,
      split out below:* the ??? → "Spirit" RENAME (the doc's old `FamilyTextPtrTable`
      entry-9 claim was WRONG — that's a per-family monster-text dispatch, not the
      family-name string; find the real string first); the production library table;
      the 11th-family feature.


### B7

- [x] **B7 — Production library grouping table (replaces the B6 POC).**
      **DONE (Session 19, user-confirmed in SameBoy — zero lag, reassigned monsters
      under correct tabs).** `tools/build_library_table.py` emits a precomputed
      **family→members** table into bank `$12` trailing free space (`$7B9B+`) at build
      time and rewrites `SetItem_6242` zero-shift (`jp LibScanByFamily`, 82-byte body →
      `jp` + 79 `nop`). The walker reads the table directly — **zero far-loads, zero
      scratch RAM** (the POC's two costs eliminated), and restores vanilla blank-slot
      semantics ($E0 for unseen / id for seen) the POC had dropped. Table format is a
      pointer table + length-prefixed member lists (additive for an 11th family);
      family assignment sourced from the vanilla family byte + `breeding_family_reassign.json`
      (the SAME spec `bank_003`/B6 consumes, kept in lock-step). Build-time validation:
      `--selftest` proves no-reassign grouping reproduces the vanilla bounds table
      exactly (parity); every family ≤ buffer capacity (32); free-space fit; ids ≤ 255.
      Data deliverable `extracted/library_grouping.json`. **Extension-aware (no hardcoded
      221):** species ids are 1 byte (256-ceiling); `COLLECTIBLE_MAX` (→255) and
      `NUM_FAMILIES` (→11, B9) are the only knobs — table + walker are already count/id
      agnostic. The 6 special non-collectible entries (215–220: TERRY? story enemy +
      4 summon tiers + 1 blank) are enumerated and PROTECTED (excluded, never a
      reassignment target). Test ROM `065943f6…`; clean build still `1ca6579…`. Method:
      KEY_LESSONS "Session 19 — Breeding B7"; format: BREEDING_SYSTEM "Dynamic library
      → PRODUCTION (B7, done)". *Open follow-up:* tool not yet folded into
      `verify_integrity.py` (self-asserts via `--selftest`; the verifier does not run it).


### B8

- [~] **B8 — ??? → "Spirit" rename (10 families, no insert).** **PREREQ SOLVED
      (S20):** the "family name" is an ICON font tile, not a string — there is no name
      string to edit (`FamilyTextPtrTable` confirmed a red herring). 10 icons at
      `$4F:$4110-$41A0`, text bytes `$10-$19`, addr = `$4010 + byte*16`; detail line is
      `<$F0><icon>"family"` (bank `$4D`), tab strip blits the same tiles. So a
      rename-only is "swap the `$19` (???) icon tile." **NOT the chosen route** — per
      the S19/S20 user decision Spirit is ADDED (B9), not a 10-family replace; this row
      stays as the solved-trace record. *Accept (if ever taken):* the ??? tab shows the
      new icon; clean build still `1ca6579…`.


### B9

- [~] **B9 — Add an 11th family (keep ??? AND add Spirit).** **VRAM CORRUPTION FIXED +
      ICON SHIPPED (2026-06-19, user-confirmed in SameBoy; built ON TOP of the gate fix).**
      The family-10 catch→map VRAM wipe is fixed (`ClampFamIdx` in ROM0 clamps the
      10-entry family-indexed GFX table `01:$4BAD` so family 10 can't read OOB; the
      species-indexed `$499D`/`$49DF` follower lookup is left alone). The Spirit whip
      (option 5) ships on font byte **$19 (`$4F:$41A0`)**, overwriting vanilla ??? — NOT
      the free $1A slot, which the menu blanks at runtime. Followers, library grouping,
      and family attribution confirmed correct; clean build `1ca6579…`; integrity PASS.
      See KEY_LESSONS "Spirit B9 Lessons" + PROJECT_STATE (2026-06-19 block). *Remaining
      polish (not blocking play):* the "$1A vs $19" line in the S20 notes below is stale;
      tab-strip/nav-grid layout for an 11th visible tab is the only open UI nicety.
      ~~**ICON HALF DONE (S20,~~
      pending SameBoy sign-off).** The family-icon path is traced (see B8) and the 11th
      icon's free slot is found: **byte `$1A` → `$4F:$41B0`** (blank filler; charmap
      "20-23 are blank"). `patches/bank_04f.asm` inserts the user's "Fire Whip Spirit"
      art there as a same-size 16-byte 2bpp tile (zero shift; bank `$4F` otherwise
      byte-identical to vanilla). Tool `tools/build_family_icon.py` + data
      `extracted/family_icons.json` (Variants A/B: head on palette index 0 for a yellow
      head if the menu palette allows, else index 2). Verifier PASS 4/4 (bank_04f added
      to patch set). Test ROM `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN
      (rest of B9, next session):** (1) confirm the "yellow head" palette in SameBoy
      (menu BG pal via `LoadGBCPalettes`→`rst $10` `$17:$03`); (2) wire Spirit as
      family 11 — the `$4D` detail line (`$F0 $1A "family"`), the tab-strip 11th cell
      (`LoadItem_4241` `b=5,c=10` grid + tab graphics), the family-code (`$FA` wildcard
      question), `NUM_FAMILIES`→11 in `build_library_table.py`, family reshuffle. Icon
      is not yet referenced by any family, so view it via SameBoy's VRAM viewer until
      wired. Scope (full): BREEDING_SYSTEM "Family icons (B8/B9)" + "Future — 11th family".
      *Decision (user, S19/S20):* Spirit is ADDED as the 11th family, then families
      reshuffled.


### BUG breeding cutscene

- [x] **BUG — breeding cutscene: parent sprites glitch.** **FIXED Session 14.**
      Observed Session 13 while playtesting B2; confirmed **not caused by B2**. Root
      cause was an incomplete bank `$0B` labelization: three raw pointer refs into the
      bank's shift region (`$4974` sprite-pointer table; `$42c8`/`$4308` gate table)
      were never converted to labels, so the custom dispatch's shift left them stale —
      and in `patches/bank_00b.asm` the sprite ref was additionally **mislabeled** to
      `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`).
      Fixed by re-sectioning both tables into labeled `dw`/`db` (disassembly stays
      byte-identical to `1ca657…`) and repointing the sprite consumer. User-confirmed
      in SameBoy (clean build still `1ca657…`; patched ROM `b43a04fe…`). See
      KEY_LESSONS "Session 12 Lessons — Bank $0B repointing" and PROJECT_STATE.



### Archived ROADMAP narratives — Phases D / F / N (cut 2026-07-02)

### PhaseD: seams

- [x] **Annotate the new-species fork SEAMS in clean disassembly (labels/comments
      only, byte-perfect `1ca6579…`).** The "which site is the seam" knowledge currently
      lives only in patches + MONSTER_DATA. Propagate it as comments at the clean anchors:
      `bank_003 label443f`/`SaveMon_4446` (single info indexer; id≥224 fork point),
      `bank_014 LoadEnemyStats` + the `$7EAD` trailing free run (16-bit EID → append, no
      fork), `bank_001 EncounterPool_000` (slot = EID(+10,×2)/weight(+20); empty slot =
      insertion point), and the **8 follower gfx-ID copies** (`$01 $06 $07 $09 $0b $12 $18
      $59` — the mgbdis defaults `FieldPtrLookupTable`/`TextDataPtrLookup`/`TileRefLookupTable`
      etc. don't reveal they're copies; rename/annotate so a swap knows to repoint all 8).
      CAUTION: a mislabel that resolves to the wrong address passes review but glitches at
      runtime (SESSION_PROTOCOL §4) — verify the build stays `1ca6579…` after each label.
      *(Flagged S30, deferred from the two-defect-fix session — own scoped pass. PARTIAL: the
      follower render seams `bank_011 HramUnk11_406e` (attr read + overshoot) and `bank_001
      GetActiveMonsterStatus` (overworld walk loader + clamp) annotated when N4 was finished —
      build still `1ca6579…`.*
      ***S33 — the name/text/lineage/follower DISPLAY seams DONE*** (labels/comments only,
      build `1ca6579…`, integrity 4/4, all referenced labels sym-verified to their addresses):
      bank `$41` `$4007` mode→table config list (modes 5/7/8/11 documented) + the corrective
      `FamilyCodePtrTable` block (species-indexed 2-letter default-nick, NOT family; legacy
      labels) + `Func_Bank41_GetText/GetPutText`; ROM0 `SaveBankAndSwitch $092F`/`TextHandler_0940
      $0940` two-level `[mode][id]` lookup + overshoot hazard + `LoadModeBaseRedirect $00F0` fork
      cross-ref; bank `$12` `LoadItem_6456`/`LoadItem_65a8`/`CmpItem_65cb` lineage chain; and the
      **8 follower gfx-ID copies** at their add-base sites (`$01:$49a7`→`ScreenTransDataTable`,
      `$06:$4d7e`→`MapNPCPosDataTable`, `$07:$66b8`→`TileRefLookupTable`, `$09:$61fb`→
      `FieldPtrLookupTable`, `$0b:$490f`→`SpritePtrTable_4974`, `$12:$65de`→`ItemSlotPtrTable`
      [= the lineage parent-icon table, doubles as the menu copy], `$18:$40bf`→`TextDataPtrLookup`,
      `$59:$42ca`→`SaveSlotPtrTable`); + one optional cross-ref at bank `$16` `$0301` parent-family
      load. CORRECTIONS recorded in source + MONSTER_DATA: **ItemNamePtrTable = mode 8** (not 11);
      **`$4739` overshoots at id≥215, fork covers id≥224**.
      ***S38 — the DATA-TABLE seams DONE*** (labels/comments only, build `1ca6579…`, integrity
      4/4; new label `EnemyStatsTrailingFree` sym-verified to `14:7ead`, cross-ref patch labels
      `FamilyRecipeResolve`/`NewSpeciesInfoCopy` confirmed to exist): `bank_003 label443f`/
      `SaveMon_4446` (single info indexer; patched `cp $e0` → bank `$6A` fork; also reached as
      `$03` entry 1 by breeding's `$0301` parent-family load); `bank_014 LoadEnemyStats` (16-bit
      EID → NO fork) + new label `EnemyStatsTrailingFree` @ `$7EAD` (append region — records that
      the 487-entry table ends at `$7BAC` but `$7BAC..$7EAC` is CODE, so EIDs 487–517 are unusable
      and the first grid-aligned slot is EID 518 `$7EB3`); `bank_001 EncounterPool_000` (empty
      slot = EID 0/wt 0 = in-place insertion point, Iron-Rule-2 safe); `bank_016 label16_485c`
      (entry-1 recipe lookup overshoots the 222-entry `FamilyRecipeTable` → `FamilyRecipeResolve`
      DISPLAY fork) + the two `$0301` parent→family conversion sites (new species resolves a real
      family as a breeding PARENT via the forked info loader). **STILL PENDING (own pass, NOT a
      new-species seam — general breeding mechanics): bank `$16` breeding-determination internals
      proper (`LoadBrd_4653` plus/special, `LoadBrd_45d5/45ff` family scan, special→family→pedigree
      precedence) — deferred to a breeding-mechanics annotation pass.**


### PhaseD: resection

- [~] **Re-section misassembled data tables → labeled `db`/`dw`.** mgbdis decoded
      many in-bank DATA tables as fake instructions (`rst $38`, `db $fc`,
      `ld hl,sp+$nn`, stray `stop`, etc. appearing mid-routine). These pass the build
      (bytes are identical) but READ as garbage code, so a future session can't edit
      the table in source and wastes time re-deriving it from raw bytes — it bit S18
      (the library bounds table) and earlier ($0B sprite/gate tables, fixed S14).
      Convert each to a labeled `db`/`dw` block; **the build MUST stay `1ca6579…`**
      after each (a wrong split changes bytes → fails instantly — same guard as the
      S14 labelization rule, KEY_LESSONS). Drive this by what the editor must EDIT,
      not completionism. *Accept:* targeted tables read as `db`/`dw` with names; MD5
      unchanged; the editor can address them by label.
      **DONE (Session 26 + Session 27): bank `$12` library/family data — COMPLETE.**
      `tools/resection_library_tables.py` converted `LibraryFamilyTabBounds` (`$6294`,
      the S18 case), the two tab-column cursor-position tables (`$564a`/`$5a8e`), and
      the **entire contiguous window-draw layout run `$710c..$7b9b` (29 layouts)**.
      Session 26 did the directly-referenced subset (`$710c/$71aa/$71f4`/`$759a`/`$7b42`/`$7b6c`);
      **Session 27 finished the two remaining contiguous gaps** (`$724e..$759a` = 10
      layouts, `$75c0..$7b42` = 13 layouts), including the 380-B `$79c6` full-screen
      view whose fake `jr` labels (`$7a05`…`$7aca`) vanished cleanly with their
      in-range `jr` sources. 44 raw-pointer reference sites labelized in total; the 21
      `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/`$6101`) correctly
      LEFT raw. Clean build still `1ca6579…`, integrity PASS 4/4. All 29 layouts also
      decoded to `extracted/library_layouts.json` (`--dump-json`). Format + addresses
      in DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)". The tool uses a
      zero-byte probe-build to map source line → address (no opcode-size summing — the
      S22 trap), is per-table idempotent, and is re-runnable from the clean tree
      (verified: clean-tree run reproduces the byte-perfect build + identical 29-label set).
      **NEXT (per-session, one each):**
      (1) ✅ **Finish bank `$12`** — DONE (Session 27, above). The whole `$710c..$7b9b`
          run now reads as labeled `db`/`dw`; `$79c6` converted; far-call descriptors left.
      (2) **Tick the STALE BOXES below** — bank `$03`/`$14`/`$16` look already
          `db`-converted (`$14`/`$16` clean; `$03` has 23 `rst $38` runs to confirm as
          padding vs data). Cheap verify-and-check-off.
      (3) **Editor-driven only:** bank `$01` encounter pools → `db` (Encounters #2 needs
          to edit pools), bank `$51` transitions, bank `$50` event state machine — do
          these when the feature is built, not for completionism.
      (4) **Checked, SKIP (no editor value, mis-split risk):** the `$ff`-padding banks
          `$08/$15/$2c/$33/$55/$66` from the old seed list — verified mostly filler
          (`$08`: 2061, `$55`: 2112 `rst $38`). Not discrete tables.


### GFX-1

- [x] **GFX-1 — Graphics system: gfx-ID indirection + sprite decompressor → annotate + tool.** ✅ DONE (Session 22)
  *DONE Session 22 — see PROJECT_STATE "Session 22" + KEY_LESSONS "Session 22" +
  MONSTER_DATA "Monster sprite graphics system". Delivered: (a) battle gfx-ID table
  `$00:$2B9F` re-sectioned to `MonsterBattleGfxTable` (`tools/resection_battle_gfx_table.py`,
  build still `1ca6579…`, 23 cross-refs preserved); (b) `dwm/sprite_codec.py` — shared
  LZ codec, decode byte-exact, `decode(encode(x))==x` on all 442 streams; (c)
  `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` (all 221,
  count-parameterised); (d) `tools/build_sprite_swap.py` generalised species-agnostic.
  ACCEPT criterion adjusted: round-trip is SEMANTIC (`decode(encode)==x`), NOT vanilla
  byte-identical re-encode (no editor value — documented). Dracky→Anteater swap
  user-confirmed in SameBoy. Doc errors below FIXED in the re-section comments.
  REMAINING (moved to editor-backend / GFX-3): cross-bank free-space allocator (swap
  tool knows bank `$36` only); follower-sprite extraction + animation-frame layout.*
  *Original verified facts (kept for reference):*
  - **gfx-ID = `(bank<<8)|index`.** High byte = ROM bank, low byte = index.
  - **Resolver `DecompressTileLayout` @ `$00:$1627`:** switches to `bank` (`ld[$2100],a`
    low bits; `swap a/rra/and 3 → ld[$4100],a` high bits — also twiddles SRAM bank,
    restored after, harmless). Reads per-bank pointer table at **`$<bank>:$4001 + index*2`**
    → stream addr in `$4000–$7FFF`.
  - **Stream header (3 bytes):** `[declen_lo, declen_hi, runmark]`, then LZ body.
    Decompressor path `WaitDMATransfer $00:$1577` → `TextScrollWindow` → writes to VRAM dest HL.
  - **LZ body:** byte≠runmark → literal; byte==runmark → back-ref: next 2 bytes `b0,b1`,
    offset = `b0 | ((b1>>4)&0xF)<<8` (**ABSOLUTE** index into output base `$ac/$ad` = VRAM dest),
    count = `(b1&0xF)+4`, extension if low-nibble=`$F` (count = next_byte + `$13`).
  - **KEY ARCHITECTURE:** back-refs point into a **SHARED VRAM tile pool pre-loaded before
    the per-monster stream**, so one monster stream does NOT decode standalone (Dracky's
    battle stream is ~9 on-disk bytes → 576 decompressed). **POC lever:** a stream with NO
    runmark byte in its body = pure literal copy = self-contained (ignores the shared pool).
    `tools/build_sprite_swap.py` (added this session) uses exactly this to repoint Dracky.
    *(Gotcha: fill the WHOLE tile field with the backdrop index, not just the sprite
    footprint — else the surround renders as palette index 0. For Dracky's battle palette
    that index 0 is red; backdrop is index 1. Fixed in the tool via `BG_INDEX`/`BODY_INDICES`.)*
  - **Battle path (VERIFIED):** `SetFld_466d` (bank `$07`, ~line 1008) reads species (`$caca`),
    indexes table at **`$00:$2B9F`** by `species*2`, DMAs to VRAM **`$8B00`**. Dracky (sp 78)
    → gfx-ID **`$3627`** (bank `$36` idx `$27`; 576 B / 36 tiles / 48×48; runmark `$02`).
    Word lives at ROM0 `$2C3B` = `27 36`.
  - **Follower path (VERIFIED):** table `ScreenTransDataTable` @ `$01:$49DF`, loader
    `GetActiveMonsterStatus` @ `$01:$4986`, index `(species+$10)*2`; plus a family-shared
    2nd load via `$01:$4BAD`. Dracky follower = gfx-ID **`$383E`** (bank `$38` idx `$3E`; 256 B / 16 tiles).
  - **DOC ERRORS to fix while annotating:** `bank_038.asm` header says "gate dungeon tileset J"
    but it ALSO holds monster follower sprites; `bank_036.asm` pointer table is labeled
    "Cross-bank dispatch table (40 entries)" but is actually the **gfx pointer table**.
  - **DISCARD (bogus):** an earlier `$382E` battle guess came from scan-tables at
    `$07:$6E14`/`$09:$6B10` that have **NO code references**; `$382E` is a dungeon tile, not Dracky.
  - **Deliverables:** labels/comments on the resolver, decompressor, pointer tables, and both
    species→gfx-ID tables; fold a proper decode/encode into the tool; extract the gfx-ID
    tables to JSON (tool ships with data). **Accept:** clean build still `1ca6579…`; tool
    round-trips a sprite byte-identically; Dracky→clam swap reproducible.



### GFX-2

- [x] **GFX-2 — Monster palette system + recolour + cross-bank sprite backbone.** ✅ DONE (Session 23)
  *DONE Session 23 — see PROJECT_STATE "Session 23" + KEY_LESSONS "Session 23" +
  MONSTER_DATA "Monster battle palette system". Delivered: (a) `dwm/sprite_bank.py` —
  cross-bank overflow allocator (places streams in reserved `$7E–$7F`/`$7C/$7A/$79`
  with a `$4001` pointer table; resolver reads `$<bank>:$4001+index*2` with no bank
  gating, so ANY of 221 monsters repointable regardless of source bank); (b)
  `tools/build_sprite_swap.py` rewritten — cross-bank, `--relocate` (lossless proof) /
  `--png` / `--payload`, `--palette` recolour, `--build-rom` focused test ROM; (c) the
  monster battle palette SOLVED — per-species table `MonsterBattlePalettes @ $17:$62FD`
  (was mislabeled `RoomAttrDataBlocks`), 8 B/species, loaded by entry 6 (`$1706`); found
  via SameBoy BG-slot-4 dump + ROM grep; annotated in `bank_017.asm` (byte-perfect);
  (d) `tools/extract_monster_palettes.py` + `extracted/monster_palettes.json`;
  `extracted/monster_sprites.json` regenerated (all 221, was a 3-monster subset).
  Proofs (user-confirmed in SameBoy): Slime relocated cross-bank renders identically;
  DWM2 clam→Dracky battle + correct purple palette; and the full combined ROM (clam +
  Dracky→Spirit family + custom room with random encounters + breeding/library) clean.
  REMAINING (GFX-3): follower path needs `$01:$49DF` re-section + its own palette table
  (find the same way) + the family-shared `$4bad` block.*
  *Original verified facts (kept for reference):*
  - **Why needed:** the clam swap renders correctly but in Dracky's palette {red, white,
    gold/brown, black} — no purple available from tiles alone. Recolour = editing palette data.
  - **VERIFIED (probe ROM this session):** Dracky's battle palette indices are
    **0=red, 1=white/transparent (backdrop), 2=gold/brown, 3=black** (index 1 is the backdrop).
  - **Traced (speculative chain):** CGB upload routines live in **bank `$17`** (`rBCPS/rBCPD/rOCPS/rOCPD`
    writes); bank `$00` has buffers `wBGPalette/wObj1Palette/wObj2Palette` + loaders
    `SetGBCPalette`/`SetPaletteGBC`/`LoadGBCPalettes`. `SetGBCPalette(a=palID)` →(GBC)→
    `SetPaletteGBC` stores ID at `$c850`, then `ld hl,$1704; rst $10` (far-call into bank `$17`)
    does the upload from a palette table. **The per-monster/family palette SELECTION point is
    NOT yet pinned** — the battle display init (bank `$07` ~lines 1090–1180) reads family
    (`$cacb`) + species and calls `FuncFld_6942` etc.; start tracing there. NOTE the
    `SetGBCPalette` calls in bank `$07` at lines 2460/2609 are SCENE palettes (warp/gate id `$03`),
    **not** the monster's — don't be misled.
  - **NEW LEAD (Session 22, user SameBoy VRAM data):** the enemy monster's tiles use ONE
    **shared OBJ palette slot — slot 4** (confirmed: Dracky AND a blue slime both show OBJ
    attribute `04` in the VRAM viewer). So the SLOT is fixed; the per-species COLOURS are written
    into slot 4 at battle-init. This means recolour = edit the **per-species colour data loaded
    into slot 4**, NOT a slot/palette-ID assignment. Concrete entry point: `FuncFld_6942` (bank
    `$07` ~line 6567) and `SetGBCPalette` — note `FuncFld_6942` does `ld h,$04` (matches slot 4).
    Trace from there to the colour table that feeds the `$1704`/`rst $10` upload.
  - **Recolour approach (speculative):** find the palette DATA table in bank `$17` reached via the
    `rst $10`/`$1704` path, indexed by the monster/family palette ID; edit the 4 RGB555 colours,
    OR repoint selection to a custom palette. **First confirm scope** (per-family vs per-monster):
    a family palette edit recolours Dracky's whole family. **Accept:** clam renders in corrected
    (e.g. purple) colours in SameBoy.



### GFX-3

- [x] **GFX-3 — Walking/follower sprite swap.** ✅ DONE (Session 24)
  *DONE Session 24 — see PROJECT_STATE "Session 24" + MONSTER_DATA "Follower /
  walking-sprite system" + KEY_LESSONS "Session 24" + TOOLS_AND_DATA. User-confirmed in
  SameBoy: blue dragon → DarkDrium follower, all 4 directions perfect.*
  **Delivered:**
  - **Re-section:** `ScreenTransDataTable` @ `$01:$49DF` → labeled `dw` block
    (`tools/resection_follower_gfx_table.py`; 231 entries `species+$10` + `FollowerFamilyGfxTable`
    @ `$4BAD`; build still `1ca6579…`). `build_sprite_swap.py --kind follower --payload F.bin`
    repoints + DMAs a 16-tile (256 B) self-contained literal stream.
  - **Render engine reverse-engineered:** `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0
    `$0d91`). Metasprite list of 4-byte **(dy, dx, tile_offset, attr)** entries, `$80`-term;
    OAM tile = `tile_offset + [$ffc9]` (follower base `$20/$30/$40` per party slot); OAM attr
    = `[$ffca] XOR attr` (X-flip bit5). 2-level table, sprite-type `$ffc7`(=`[$ca91]`) →
    frame/dir `$ffc8`. Head-mirror = two entries sharing a tile_offset, one X-flipped.
  - **OBJ transparency:** idx0 = HARDWARE-transparent for OBJ (battle BG used idx1 — opposite).
    8 OBJ palettes @ `$17:$5615`.
  - **118-layout library** (`tools/extract_follower_layouts.py` → `extracted/follower_layouts.json`):
    76 non-sharing (disjoint down/up/side → any distinct art renders clean; 202 types) + 42
    sharing (blob-only; 58 types). **Layout is per-monster, not universal** — this is why a
    symmetric blob (clam/Healer) hides layout errors and a directional dragon exposes them.
  - **Tooling:** `tools/follower_frame_picker.html` (drag 6 boxes, engine-accurate preview,
    export coords/payload) + numbered-tile calibration ROM method (each VRAM tile shows its hex
    index + flip-foot; `--palette` override = black digit / red foot for terrain legibility).
  *Original plan (for reference):*
  GFX-3 — Walking/follower sprite swap. Rides the Session-23 cross-bank backbone
  (`dwm/sprite_bank.py` + `build_sprite_swap.py`), but via the FOLLOWER path. Prereqs now
  known: (1) **re-section `ScreenTransDataTable` @ `$01:$49DF`** from mgbdis fake
  instructions to a labeled `dw` block (byte-perfect, same job as the S22 battle gfx
  table — preserve any cross-bank referenced labels), then `build_sprite_swap.py --kind
  follower` can repoint it (the tool already has the follower table wired, gated until the
  re-section lands); (2) the follower likely has its OWN palette table — find it the same
  way GFX-2 found the battle one (SameBoy dump of the follower's palette slot + ROM grep);
  (3) handle the **family-shared `$4bad` second DMA** (the B9-clamped 10-entry family GFX
  table) — verify in SameBoy whether it overlaps the swapped walk frames. Follower = 16
  tiles (`$383E` for Dracky); the 16-tile stream holds the full walk-animation frame set.



### GFX-4

- [x] **GFX-4 — Monster → follower-layout auto-map (completes GFX-3 automation).** ✅ DONE (Session 25)
  *DONE Session 25 — see PROJECT_STATE "Session 25" + MONSTER_DATA "Monster → layout dispatch" +
  KEY_LESSONS "Session 25" + TOOLS_AND_DATA. User-confirmed in SameBoy: Healer→Dragon clone and
  Dracky→custom blue-dragon (imported art), correct all directions, consistent across overworld +
  menu + library.*
  **Delivered:**
  - Level-1 layout tables LOCATED at fixed `$10:$407f` (species 0–127) / `$11:$407f` (species 128+),
    indexed by species; per-species attr/palette table at `$10:$417f` / `$11:$412d` (bit6=Y-flip, bit5=X-flip, low3=OBJ palette). (`[$caca]` is the SPECIES,
    not a "sprite-class" byte; bank `$05` is the ObjTest viewer path, not the follower path — both
    pre-GFX-4 doc errors, corrected.)
  - `tools/extract_monster_follower_layouts.py` + `extracted/monster_follower_layouts.json` (every
    species → layout id + addresses + sharing). `--selftest` reproduces Healer/DarkDrium anchors and
    confirms all 215 collectible species map.
  - `extracted/follower_layouts.json` REGENERATED & REPLACED — **155 complete layouts** (old 118 dropped
    the 3-entry small/blob layouts), canonical `$10/$11` addresses.
  - **8 follower-art table copies** discovered (`$01 $06 $07 $09 $0b $12 $18 $59`); a consistent swap
    must repoint all 8 (layout/attr are single/shared).
  - `tools/build_follower_reassign.py` — reassignment primitive: clone layout+art+attr from another
    same-bank monster, OR import custom 16-tile art (placed cross-bank, all-8-copies repointed) and set
    layout (default layout 0) + palette. Builds focused test ROMs; clean build stays `1ca6579…`.
  *Original plan (for reference):*
  layouts** (`extracted/follower_layouts.json`). The one remaining link is which layout each
  of the ~215 monsters uses, so the editor can (a) slice imported art into the correct tiles
  automatically, and (b) reassign a monster to a clean non-sharing layout on demand.
  **Known structure (from GFX-3):**
  - Render path: `AdjustGateFloorIndex` (`$01`) sets `$ffc7 = [$ca91]`, base `$ffc9 =
    $20/$30/$40`, calls `$0402` (`NPCSpriteLoadAlt`) → `SaveScr_40cd`.
  - `$ffc7 = [$ca91] = GetActiveMonsterStatus` return = `$01` (if bit7 of `[$cb0b]`) else
    `[$caca] + $10`. So a monster's layout is driven by its **sprite-class byte `[$caca]`**.
  - The 118 layouts are the **level-2** frame-pointer tables (6 ptrs each: down/right/up × 2),
    living in banks `$05`/`$10`/`$11`. A **level-1** table indexes them by `$ffc7`, with the
    BANK chosen by `$ffc7` magnitude (`NPCInteractDispatch` routing: `<$10`→`$04`,
    `$10–$8F`→`$10` (sub `$10`), `≥$90`→`$11` (sub `$90`)). Bank starts are code, so the
    level-1 tables are NOT at `$4000` — they must be located.
  - **TODO:** (1) locate the level-1 dispatch table(s) per bank; (2) extract each monster's
    `[$caca]` sprite-class from the monster data table; (3) compose monster → `$ffc7` → layout
    id; emit `extracted/monster_follower_layouts.json`; (4) wire into `follower_frame_picker.html`
    + `build_sprite_swap.py` so imports default to a non-sharing layout and reassignment is a
    same-size `[$caca]` edit. **Accept:** every monster maps to a layout; a distinct-art import
    on any monster renders clean (matching the DarkDrium-dragon result).


### T1

- [x] **T1 — Re-section keystone (bank `$47`). DONE (S43, byte-perfect).**
      `tools/resection_text_bank.py` converts a corpus bank's contiguous DTE string run
      from mgbdis fake-instructions to `TextStr_<bank>_<addr>:` + `db` blocks (one label
      per text id, decoded text in a comment), labels/comments only. Region from data
      (first string addr `text_id_map.json`; end = bank trailing-fill scan); `R_start/R_end`
      snapped to real line boundaries via a probe-build line→address map (same machinery as
      `resection_library_tables.py`) so no fake instruction is split; emits exact ROM bytes.
      Idempotent, re-runnable from clean tree. **bank `$47`: 69 strings, run `$4174-$5b74`,
      5607 fake lines replaced; clean build stays `1ca6579…`, integrity PASS 4/4.** Method +
      per-bank bounds in TEXT_SYSTEM.md "Source re-section". *Accept met:* bank reads as
      labeled `db` with decoded comments; MD5 unchanged.


### S1

- [x] **S1 — Skill data foundation + round-trip keystone (S44).** *Reshaped on audit:* the
      bank `$52` function table was already re-sectioned, so the real work was the data tables.
      Decoded + FAQ-validated `SkillMPCostTable` ($07:$570C) and `SkillLearnReqTable`
      ($06:$50E0, incl. prereqs); `gen_skill_records.py` → `skill_records.json` (222 records,
      `kind` = 155 skill / 37 item_effect / 30 internal, family-cut codes, monster/enemy usage);
      `build_skill_tables.py --selftest` proves the function/MP/learn tables re-emit
      **byte-identical**. Corrected bank `$52` header ($4211→$6CC7, 256→222, 140→115). Found id
      215 "Sheldodge" = the **Bug-family cut**; renamed → "BugCut" in `patches/bank_041.asm`
      (**SameBoy-confirmed**). Comment-only annotation of the two tables in `bank_006/007`
      (flagged the `TilesetLookupTable` mislabel at `$570C`; rename + full `dw` re-section
      deferred pending SameBoy confirmation of the `$56E8` fn role). MD5 unchanged; integrity PASS.


### S2a

  - [x] **S2a — Alias EFFECTS POC (S45, SameBoy-confirmed).** Net-new ids $DE "Scorch"
        (reuses Blaze handler) + $DF "Smite" (NEW handler, 80 dmg) on starter EID 1, via the
        **skill-alias framework** (commit-time templatize to Blaze + `$db86` stash + `$db8a==0`
        guard + `FarSkillFork`). Works in battle. **Narrow:** single custom-caster, Blaze-shaped
        presentation only; enemy-real-Blaze edge case unclosed. `BATTLE_SKILL_SYSTEM.md` §1–§6.


### S2b

  - [x] **S2b — Presentation foundation + record round-trip keystone (S46, byte-neutral;
        NOT yet user-tested).** Proved handler=effect TYPE (shared) / record=per-skill params.
        Decoded the **record table** `$54:$4013`→`$41CF` (222×19B): field map FAQ-validated
        (+0 effect_class, +1 effect_category, +2 target_mode, +3 ai_weight, +4 mp_cost,
        +5 status_id, +6 damage_class, +11/+13/+15/+17 power min/range — 31/32 FAQ ranges exact).
        `build_skill_tables.py --selftest` re-emits ptr table + data **byte-identical**; the 4218B
        block **re-sectioned to `db`** in `bank_054.asm`. Decoded the **item-effect/meat** system
        (`$52:$4625`, meat 194–198 → `$58:$591E`) and the **animation dispatch** (`$52:$5460–$54f8`
        → `$dd6f`/`$dd70` → bank `$4c`/`$55`). MD5 unchanged, integrity PASS. `BATTLE_SKILL_SYSTEM.md` §7–§10.


### S2c

  - [x] **S2c — Effect-script MESSAGE format (RE, discovery). [2026-06-28]**
        *Reframed on RE:* bank `$4c` is **not** a novel effect-bytecode interpreter — it is the
        shared text VM, and the `$dd70/71` "pointer" is a **packed pair of message ids** (low=hit,
        high=miss) resolved via the mode-0 two-level table at `$4c:$4019`. *Accept met +
        validated:* Blaze `$b882` decoded to bytes (`$4c:529f` + `$4c:5871`); **67/67**
        statically-resolved skills' messages cross-checked against the categorized FAQ
        (`extracted/skill_faq.json`), 0 contradictions. Tool
        `tools/decode_effect_messages.py` (`--selftest`, `--validate`) →
        `extracted/effect_messages.json` (222 skills, 203 message ids). Format in
        BATTLE_SKILL_SYSTEM.md §9.


### S2c-anim

  - [x] **S2c-anim — Animation FORMAT / renderer (RE, discovery). [RENDERER REVERSED + EMULATOR-VERIFIED 2026-06-28]**
        The `$dd68` renderer is a **metasprite/OAM engine** (same 4-byte `dy,dx,tile,attr`
        $80-term format as the follower system). Full chain emulator-verified: skill id →
        `$5f:$52F0` → side-select tables `$5f:$58dd/$59c3/$5aa9` → routine dispatch
        `$5f:$5441` → routine table `$5f:$58bd` (index `$0d`=`$55cc`=`ret`=NO VISUAL) → sets
        `$dd68` anim-type → builder `$5c:$40fc`/`$5d:$4122`/`$5e:$413a` (de=`$4071`, two-level
        `[$c7]`anim/`[$c8]`frame → metasprites). **3 presentation layers** mapped: (1) sprite
        anim, (2) sound+flash (`$56ed/$57d5`→`$da81`; heal chime, TatsuCall `$da83` blink),
        (3) vertical screen-shake `$5f:$4c0c` (SCY via `$da84`/`$bb`). See §11. Tool:
        `decode_battle_animations.py` → `extracted/battle_animations.json` (45 anims/~600 frames).
        *Reuse* a known animation on a new id = table edit (`$58dd/$59c3/$5aa9`). *Authoring a
        novel animation* = add metasprite frame lists + a `$4071`-table entry (now fully
        specified; **remaining static-only:** per-bank table extent + tile-graphics VRAM source).


### S2d-audit

  - [x] **S2d-audit — Skill-ID bucketing audit (de-aliasing FOUNDATION, RE/discovery). [S48, 2026-06-28]**
        Byte-neutral. The prerequisite S45 skipped: a complete map of where the engine buckets the
        working skill id (`$db8a`, 254 reads / 9 banks). **Surface reduces to a small verified fork
        set** — 204 equality reads (max `$C5`, custom id matches none), 15 windowed range gates (fall
        through to defaults), exhaustive enemy-AI `$57` pass (148 reads, ZERO mishandle a custom id;
        high-id sub-dispatch guarded by `cp $d9; ret nc`). **Keystone = the record-table indexer
        `$54:$4013` (3 sites `$5251/$5276/$529E`)**: one fork fixes magnitude/targeting/MP-in-record/
        status/ai_weight + the AI. HW-confirmed (SameBoy): `$52:$66D9` writes `$db4c=$db8a`; `$535F`
        divert is a minor path; menu Flee ≠ skill `$DB`. **Keystone fork PROVEN byte-neutrally
        implementable** (5-byte `call Fork`+nop+nop trampoline, RGBDS-assembled + byte-executed,
        in-bank tables in `$54`'s ~10550 free bytes). Other forks: MP (3 readers, mirror `record+4`),
        sound (`$55:$4067`), name (repoint), anim (none for no-visual). Tool
        `tools/map_skill_id_buckets.py` → `extracted/skill_id_bucket_map.json`. Full RE: **§12.**


### S2d

  - [x] **S2d — Proper per-id custom-skill records + PRESENTATION (skill #1 live). [S49, 2026-06-29, v32]**
        Skill **MagicBurn (`$E0`)** ships non-aliased, end-to-end in SameBoy (user-confirmed):
        own record (½ current MP → all foes), result text, **announcement**, **animation**,
        **hit-flash**, **cast sound** — via clean dynamic indirection (own record/handler/name +
        `AnnounceTemplateTable` slot + `$4c:$7326` message pool + `GetPresentId` presentation
        proxy in `$5f`), no per-aspect hacks. Integrity PASS 4/4, byte-perfect. The earlier
        "anim blocked on `$5f` cleanup" is **solved**. Full system + per-skill recipe:
        **BATTLE_SKILL_SYSTEM.md §13**.


### S2e

  - [x] **S2e — Custom skill #2 (Tame `$E1`) — system GENERALIZES. [S50, 2026-06-30, user-confirmed]**
    Recruit + anti-abuse damage (ATK/4), single-target. Built the reusable **custom-message
    render fork** (`$FD`→per-skill pool string, `LoadB4c_Fork`; MagicBurn migrated onto it) and
    the **presentation-timing** path (per-id anim-wait gate `$53:$5b07` + fixed frame delay
    `wTameDelay` sequences note→hit; damage sound moved off the note onto the text). Full RE:
    BATTLE_SKILL_SYSTEM §13.5 + §11.7; TEXT_SYSTEM ($FD fork); KEY_LESSONS (S50). **Deferred:**
    Tame Stage 2 (revert meter crank $0640→$000A; 3 upgrade tiers via learn-chain fork bank $06;
    make natural to Slime via a $03:$4461 slot). **Known minor defect:** per-enemy-sprite blink
    unsolved (not wBGPalette/whole-screen, not OBP-only; likely an OAM visibility toggle — §11.7).


### S2e-orig (deleted, superseded)

  - [ ] **S2e-orig (superseded desc) — Custom skill #2 (prove the system generalizes).** Add a skill of a
        DIFFERENT shape than MagicBurn to stress parts skill #1 didn't: a **non-damage** skill
        (ally heal, a buff, or a status effect) and/or a **single-target** one. *Accept:* it
        works in SameBoy with its own record/handler/name/announce/presentation, no aliasing.
        **SHOVEL-READY:** follow the 5-step recipe in **§13.4** — each layer is a one-line edit;
        nothing is rebuilt. Watch the two open follow-ups in §13.4 (custom-id skill-NAME insert
        for name-inserting announce templates; a 2nd bespoke-message render path beyond `$FD`) —
        a heal that reuses a self-contained stock announce template hits neither.


### Recommended-order (old)

**Recommended order:** T1 ✅ → S1 ✅ → S2a ✅ → S2b ✅ (S46) → S2c-msg ✅ → S2c-anim ✅ → S2d-audit ✅ (S48) → S2d ✅ (S49, skill #1 live) → **S2e** (next — custom skill #2) / S2f (field skill) / S3 → S4 → M1 → M2 → M3 / T2-roll-out,
slotting the text roll-out into spare sessions. Cheap high-confidence wins early; fire the
two RE discovery sessions (M1, S3) before their authoring items depend on them.

### N1

- [x] **N1 — Scope / RE + slot map (DONE, Session 28).** `tools/map_species_slots.py`
      + `extracted/species_slot_map.json` (256-slot map, self-checking). Verified:
      single indexers (info `$03:SaveMon_4446` ×43, enemy-stats `$14:LoadEnemyStats`
      ×25 with 16-bit EID); slot geography (215–219 special, 220–223 empty, 224–255
      free); the 4 hand-decoded top-range `cp`-ladder sites (flagged for N6 — since
      RESOLVED as `$db8a` skill/effect gates, NOT species gates) vs ~40 false-positive
      `cp $dd` hits. No bytes changed; integrity PASS 4/4.


### N2

- [x] **N2 — Info-table fork (keystone). DONE (S29 impl, S30 verified + made reproducible).**
      `SaveMon_4446`/`label443f` forked zero-shift (id ≥ 224 → bank `$6A` high table via
      `ld hl,$6a00; rst $10`); `MonsterInfoTable` stays pinned at `$4461`, ids 0–220
      byte-identical (only the 2 B6 family-byte reassigns differ). Authored by
      `tools/build_new_species.py` (`extracted/new_species.json` → `patches/bank_06a.asm`),
      byte-exact round-trip validated. Gorbunok (id 224 = Dracky info, family→Slime).
      *Accept met:* id 224 loads correct 43 B; clean build `1ca6579…`; SameBoy-confirmed
      (S30: caught, correct Slime-family stats).


### N3

- [x] **N3 — Enemy-stats. DONE (no fork needed).** EID is 16-bit, so a new entry placed in
      bank `$14` trailing free at EID×25+`$4C1D` is read by vanilla `LoadEnemyStats` with no
      code change. EID 518 → `$14:$7EB3` (Slime EID 2 clone, monster_id→224). Tool
      `build_new_species.py` → `patches/bank_014.asm`. SameBoy-confirmed (S30: fightable/
      catchable). Wild-encounter wiring: same-size `EncounterPoolData` edit (pool 0 slot 3 =
      EID 518 wt 1), tool-owned in `patches/bank_001.asm` (S30 — was a hand-edit before).


### N4

- [x] **N4 — Sprite + palette. DONE (user-confirmed v7).** Tool
      `tools/build_new_species_follower.py` builds a standalone test ROM (patches/ untouched,
      clean build stays byte-perfect) giving id 224 a real follower + battle sprite + palettes:
      • **Follower art:** all **8** gfx-ID copies forked byte-neutral to a real overflow stream
        (`$7e00`); the overworld loader `GetActiveMonsterStatus` ($01) clamp narrowed `cp $e0`→`cp $e1`
        so id 224 reaches the fork (the placeholder clamp had pinned it to DarkDrium).
      • **Follower layout:** level-1 slot `$11:$413f` → Armorpion's layout-0 level-2 `$4184` (proven
        upright, matches `pack_png_layout0`).
      • **Follower attr (palette + flip):** the per-species attr read (`HramUnk11_406e`) overshoots its
        87-entry table into live layout data at `$418d=$41` — bit6 was a stray **Y-flip** (upside-down
        tiles) and low3=1 the **green** palette. Forked the read (`$11:$406e`→`$792d`) to hand id 224 a
        clean attr (no flip, OBJ palette 2 = blue). Both cosmetic bugs were this one overshoot byte.
      • **Battle:** gfx `$00:$2d5f` `$320f`→`$7e01`; palette reader `label17_41d0` forked (resolver
        `$17:$6ce0`) to a custom blue palette. (Full mechanism: MONSTER_DATA.md "NEW species followers".)
      **Follow-up status:** the **FOLLOWER half is now baked into `patches/*.asm`** — Milestone **G1,
      DONE (S34, user-playtested OK, all 4 directions).** id-indexed (content-sized) gfx-ID tables in all
      8 banks, layout slot, attr fork, clamp; new `patches/bank_011/059/07e.asm` + tool
      `tools/bake_follower_overflow.py`; in verify_integrity PATCH lists; integrity PASS 4/4.
      Orientation fixed at root: art stored **un-flipped** (no `--flip-y`), clean-attr mask **`$B8`**
      (preserves the engine's bit5 X-flip for LEFT). The **BATTLE half is now baked too** — Milestone
      **G2, DONE (this session).** Battle gfx `$00:$2d5f` `$320f`→`$7e01` (a **same-size 2-byte repoint**,
      no fork: the species-indexed gfx table `$2b9f` has a real padding slot for id 224, unlike the
      follower tables that overshoot); the dragon battle pose packed as a 2nd overflow entry
      (`Battle_sp224` @ `$7e01`, follower stays `$7e00`) by the extended `tools/bake_follower_overflow.py`
      (`--battle-art/--battle-spec`); battle palette reader `label17_41d0` forked byte-neutral to
      `HighBattlePal` in bank `$17` filler tail (id≥224 → custom blue palette `67 4d ff 6b ff 7f 00 00`,
      else vanilla `$62fd+species*8`). New `examples/follower_swap/gorbunok_battle.json`; bank `$000/017/07e`
      in verify_integrity PATCH lists already; integrity PASS 4/4, user-playtested OK. (Full mechanism:
      MONSTER_DATA.md "NEW species battle sprite".)  **Remaining new-species item → G3:** new_species.json
      schema fold.


### N5

- [x] **N5 — Name + joinability + breeding/library wiring. DONE (S32, user-tested).** Name
      DONE ("Gorbunok" @ `$41:$7E46`). Library DONE + reproducible. Joinability via EID 2 clone.
      **Breeding now DONE — all three paths, user-confirmed:**
      - **Result-path:** Snaily(4) × BattleRex(42) → Gorbunok, a verified-free cross (no special,
        no family default) appended in `extracted/breeding_special.json`. `build_breeding.py`
        extended to admit a declared new-species id (>220) as a recipe result. Bank `$69`.
      - **Parent-path:** works with zero new code — breeding loads parent family via the forked
        `$0301` loader, so Gorbunok resolves to its Slime family `$F0`. Verified by simulation +
        user playtest (Funkybird×Gorbunok→Picky, Dran×Gorbunok→DragonKid, Gorbunok×Funkybird→
        Healer, AntEater×Gorbunok→Tonguella, Gorbunok×AntEater→SpotSlime).
      - **Display-path:** `FamilyRecipeResolve` (`patches/bank_016.asm`) returns the parent pair
        `db $04,$2a` so the encyclopedia shows the Snaily+BattleRex icons.
      - **Hatch:** crashed on the first build — bank `$0b` follower-gfx copy overshot for id 224
        (user pinned via SameBoy breakpoint `$0b:$48ac`). Fixed with `FollowerArtResolve0b`
        (`patches/bank_00b.asm`), same byte-neutral pattern as `$07/$09/$18`.
      - **Default-nickname / "take X with you" narration:** both used the 2-letter `FamilyCode`
        short-name table (`$4739`, 215 entries) which overshot for id 224 into `ItemName[9]` =
        "SkyBell". Fixed via `LoadModeBaseRedirect` (16 bytes in the `$00F0` ROM0 padding,
        `patches/bank_000.asm`): mode-7 lookups for id≥224 redirect to a new-species SHORT-name
        entry (first 4 letters, "Gorb") at bank `$41` tail (`$7FF9`). Generic (no per-monster
        handcoding); gated on `$4739` so all other text is byte-identical.
      - **[x] SUB-ITEM (DONE, S38 — user-confirmed in SameBoy):** library/encyclopedia lineage
        showed parent *icons* correctly but "?????" next to each instead of "Snaily"/"BattleRex".
        Root cause (S32): the parent-name line is rendered via `LoadItem_6456` (`$12:$6456`) → bank
        `$4d` entry 2, **mode 0 = line 1** (`$4d:$400b`), indexed by the **offspring** id; slot 224
        held the vanilla shared "?????    ?????" placeholder @ `$53C4` (256-entry table, NOT an
        overshoot — un-authored slot, shared with 220/225). **FIX (S38):** first verified from clean
        source that the lineage path routes through the fork (bank `$4d` entry 2 = `call SetB4d_43b9`
        → `HighDetailTextFork` → `HighModeTable4D` for id≥224), then wired `HighModeTable4D` mode-0 →
        new `HighMode0Ptrs` → `GorbunokRecipeLine` (`patches/bank_04d.asm`). **Also corrected a
        latent format bug** in the S32-staged string: real recipe lines use TWO fixed 9-char fields
        (e.g. slot 200 "Servant  GreatDrak", slot 214 "DeathMoreWatabou"), so the single-spaced
        staged string would have mis-columned parent 2 — rebuilt as `"Snaily   BattleRex"` (names
        sym-verified vs `MonsterNamePtrTable $41:$4339`). id≥224-gated → ids 0–223 byte-identical;
        built-ROM check `[mode0base+224*2] → GorbunokRecipeLine` → "Snaily   BattleRex". Test ROM
        `DWM-lineage-fix-v1.gbc`. Breeding itself unaffected. **Phase N now has only G3 open.**


### N6

- [x] **N6 — Top-range gates verified (DONE, S31): NOT species gates → no patch.**
      `bank_05f/057/058/052` all branch on `$db8a`, which is a battle skill/effect/
      animation id (written only from constants + skill tables), never a species byte.
      A new species 224 cannot reach them, so they were false positives in the S28
      slot-map. Phase N requires no species-gate patch. (Detail in MONSTER_DATA.md
      "Species ID geography" → N6; DOC_AUDIT.md.)


### S29 trailing blockquote (all items resolved or folded into G3)

> **S29 progress (stage1ac / Gorbunok id 224 track).** The **encyclopedia DETAIL page
> freeze** — the last blocker for the new-species *display* feature set — is FIXED
> (`TEXT_SYSTEM.md`): the text engine's mode×species double indirection
> (`SaveBankAndSwitch $092F`) overshot the 215-entry line-2 description table at
> `$4D:$420B`. Forked via `HighDetailTextFork` (`patches/bank_04d.asm`). Also fixed the
> independent 222-entry `FamilyRecipeTable` overshoot (`FamilyRecipeResolve`,
> `patches/bank_016.asm`). Detail page user-confirmed clean (mirrors Dracky), ROM
> `DWM-Gorbunok-stage1ac-v16.gbc`. Every species-indexed table and its overshoot status
> is now catalogued in `MONSTER_DATA.md` (Species ID geography).
>
> **Next steps / deferred (next session):**
> 1. **Custom Gorbunok sprite + palette** (the N4 work) — currently a DarkDrium
>    placeholder (`MonsterBattleGfxTable[224]=$320F`); follower sprite also deferred.
> 2. **Bespoke Gorbunok description string** — line 2 currently reuses Dracky's
>    (`$60BC`) as a valid placeholder; author a real string (needs font-glyph encoding
>    like the name) and point `HighLine2Ptrs[0]` at it.
> 3. **Optional: make Gorbunok breedable** — wild-only today (recipe = `$FF,$FF`); both
>    the result-path (`SpecialRecipeTable` append) and parent-path (extend
>    `FamilyRecipeResolve`) are documented in `BREEDING_SYSTEM.md`.
> 4. **Re-check N4/N5/N6 formal acceptance** against the stage1ac implementation and
>    tick the boxes whose acceptance tests are now met.


> Session 65 (2026-07-18 — **CF4: custom-room WRAM migration into the
> CF3-freed window + SRAM-expansion audit. BUILT; v7 USER-CONFIRMED S66
> (test ROM v7 `de0c5a672e7e7e1fb834dd7afe70b9e7`, patched).**
> User decisions: buffers move to the window head; counter region 640 B;
> the $DE74 scratch block stays; persistent-pool doctrine = flags now,
> SRAM expansion later (E3); 56-B SRAM tail = untouched emergency reserve.
> **Pre-work finding (changes the S58 plan)**: the freed window
> $CC80-$D664 is TRANSIENT PERMANENTLY — its save-image address
> $A3BA-$AD9E is CF3's live farm, so entries 5/6 skip it in BOTH copy
> directions; the S58 "EXPLOIT the vanilla block copy" decision was
> foreclosed by S60's build and cannot be revived (annotated at the
> decision text; DOC_AUDIT S65).
> **As built**: wCustomNPCBuffer→$CC80, wCustomExitBuffer→$CD00
> (label-only; the 4 operand sites live in the bank $60 template TEXT which
> is unchanged — sha256 pins + TEMPLATE_SIZE untouched); STEP_COUNTER_BASE
> $DE74→$CD80, WRAM_REGION default/max 640 (hard cap = the $D000 wram0
> section boundary, validated in project.py); static `ds 7` at $DE74 keeps
> wRoomRecScratch pinned $DE7B (scratch/Tame/flag/CF3-mailbox block
> unmoved; ClearAllWRAM $1EE0 extension still required for it);
> wCustomPool $D001-$D664 (1,636 B transient reserve). **Init guarantee**
> (the copy-skip corollary of S55's init lesson): bank $73 entry 6 tail
> zeroes the window after the main-image restore copy (gated on unique src
> end $B124; the 4 callers are enumerated in the entry header) — with
> ClearAllWRAM (power-on) and CF3NewGameClear (new game) this makes every
> gameplay entry window-zeroed; reload-in-room now deterministically step-0
> (also closes the S55-accepted cross-save staleness).
> **Census scare resolved**: 136 vanilla literal refs inside the window are
> ALL data-as-code artifacts ($CD = CALL opcode minting fake $CDxx
> operands; "PaletteStoreCD80" etc. are auto-names on instruction soup);
> structural proof = the vanilla array occupied the window. audit_wram.py
> models it (FREED_WINDOWS, F-class; S54 detection power selftest-pinned
> via a $CAC5 probe; arg guard added) + wram_usage.json regenerated
> together. known_RAM_map's unsourced "link+arena time-share" clause
> refuted via the S56 access map and removed.
> **SRAM expansion (user request) audited, NOT built — BLOCKED, banked
> into E3 + ARCHITECTURE "SRAM banking"**: header is $1B/8 KB; RST_18
> writes RAMB:=rom_bank>>5 on every rst $10 ($FFA3 = shadow; bank $40 has
> a genuine di-bracketed 32 KB multi-bank SRAM wipe — the engine family
> carries the infrastructure); under 32 KB, CF3 (bank $73) would run on
> RAMB=3 and the audio ISR's bank $74 dispatch flips RAMB every vblank —
> RAMB discipline in CF3's SRAM entry points must land first. Free SRAM
> today: tail $BFC8-$BFFF (56 B).
> Doc repairs: PROJECT_COMPILER §2.7 stale pre-S57 flag pool → 32-flag
> pool; §2.6 rewritten; quick-start + §1 md5 re-pinned WITH a stale-pin
> grep this time. Compiler: example project (region_size 640, hole
> 0xCD84), REFERENCE_MD5 `de0c5a67…` (patched), 25/25 --rom; compat==hand
> re-proven file-identical. Verifier PASS 5/5; clean build `1ca6579…`.
> **v7 acceptance MET (user, S66 — "no issues")**: enter $6B/$6C/$70, NPC interact, exits
> both ways, step advance, save-in-room → reload → scroll (expect step-0),
> egg give in-room.
>
>

> Session 71 headline (2026-07-26 — **FX1: ACTIVE FARM 17 → 37 SLOTS. SHIPPED, USER-CONFIRMED (farm menus >17, sleep whole-swap, save/reload, breeding + 21-hatch session: "everything works"). Exp-scale VETOED → S71v2 vanilla rate, pin `46ba6991…` (patched; v1 `9c3af0d4…`, v2 delta = drain payout only, PyBoy-verified).** Array = 40 slots (20-39 = the evicted sleep pool's bank-0 home $B124; staging INDICES 20/21→40/41, addresses unchanged); pool → SRAM bank 2 ("P1", 40-slot whole-swap mirror, bank $73 entries 10-12); "F2" one-time reformat + checksum v3 + snapshot "R4" dual-region; roster lists + compaction map → wMonList $D001; exp payout halved at drain (veto-pending). PyBoy-verified on the user's .sav: reformat preserves the save (after fixing an F2-ordering bug that WIPED it), R3→R4 upgrade, 25-farm canonicalize/lists/rewind/dual-snapshot/drain/battle. User accept pending: farm menus >17, sleep whole-swap, save, trade, breeding, join.)
>
>
> Session 71 (2026-07-26 — **FX1: farm expansion 17 → 37 active slots.
> BUILT S71, NOT user-tested.** Owning: MONSTER_DATA "FX1 as built (S71)";
> ARCHITECTURE SRAM map; KEY_LESSONS S71. User decisions: 37 farm;
> whole-swap sleep (pool = full 40-slot non-party mirror in SRAM BANK 2,
> $A010+c*$95, "P1" magic); exp "scale" = drain payout halved (aggregate
> 37/32 ≈ vanilla 17/16, per-monster growth HALF vanilla — flagged for
> veto). Mechanics: GMDP computed-window decode gains two windows
> ([$D665,$E208]−$2541 → $B124 farm 20-39; [$E209,$E332]−$0BA4 → staging,
> whose INDICES moved 20/21→40/41 because computed index 20 IS $D665);
> stride hops re-cut (19→20 +$385; 39→staging +$199D); ~150 adjudicated
> vanilla-bank edits (bounds $14→$28, staging index writers, $C0D8 roster
> lists + canonicalizer map → wMonList $D001 64-B carve — 40 entries
> overflow $C0D8's ~36-B safe extent; drop/pick working sets, skill copy,
> family buffer, encounter scratch adjudicated STAY); give-opcode full
> fallback `ld c,$13`→`$27` (latent vanilla-shape bug); sleep machinery →
> bank $73 entries 10 (record swap, per-byte RAMB-2, pin-safe)/11 (pool
> zero+magic)/12 (census) via same-size rewrites in banks $12/$07; trade
> recv → first-empty 3-39; checksum v3 (excl. $B124-$BCC7; heals
> vanilla/v1/v2) behind the "F2" reformat gate ($BFC8-9) whose ORDER IS
> LOAD-BEARING (legacy sums before stamp, v3 after — the first build wiped
> the user's save, caught by PyBoy pre-delivery; KEY_LESSONS); snapshot v4
> "R4" dual-region ($A1BF×95 + $B124×94 chunks, 28-B lazy-tail no-op
> overlap; R3 auto-upgrade). PyBoy battery on the real .sav: reformat
> preserves save; R3→R4; 25-farm canonicalize + compaction across the
> slot-19 boundary; farm list = 0..27,$FF in wMonList; unsaved pokes
> persist bank0 across power-cycle then REWIND on continue; seed-path
> dual-region commit + reboot restore (markers intact); drain pays
> extended slots pending/2 + levels + zeroes; encounter battle round-trip
> clean. Compiler re-pinned 38/38 `9c3af0d434f3d5bcd617677a42129778`
> (S71 patched build; prev a5a5e0d5 S70v3 patched). **USER-CONFIRMED
> same session** (farm menus >17, sleep whole-swap, save/reload, breeding
> + a 21-egg hatch run: "everything works, as far as I can test"; the
> "hatchling shown last" observation = first-empty insertion after the
> early slots filled + order-preserving compaction — vanilla semantics,
> newly visible past 17; explained in MONSTER_DATA). **Exp-scale VETOED →
> S71v2**: drain pays FULL pending (vanilla per-monster rate; halving
> block removed, payout reads wPendingFarmExp directly; wPoolBounce
> keeps only its pool-swap role). v2 PyBoy-verified: 512 pending → 512
> paid in BOTH farm regions + silent levels. Re-pinned 38/38
> `46ba69918c7ddfdfcd8a441d967debb6` (S71v2 patched; prev 9c3af0d4
> S71v1 patched). v2 delta vs the user-confirmed v1 = the drain payout
> amount only.**)
>
>

> Session 72 (2026-07-31 — **Phase 3 item 1: editor walking skeleton +
> VISUAL ROOM DISPLAY (user-directed extension same session).
> BUILT S72, NOT yet user-tested. Byte-neutral** (no patch/ROM changes;
> pins untouched). Owning: EDITOR_DESIGN (S72 amendments + new §11 with
> as-built notes); ROADMAP Phase 3 + new boxes. As built: `editor2/app/`
> PySide6 window (main.py: toolbar, open/reload project, recent-project
> restore, room list, **Room tab = rendered display** + Fields tab,
> build-log dock, ROM-MD5 gate `1ca6579…` + custom-emulator preference
> via QSettings; room_view.py: zoom 1-3×, NPC/spawn/exit markers;
> build_worker.py: QThread over the UNCHANGED core pipeline — GUI build ==
> CLI build by construction) + `editor2/core/render.py` (headless room
> renderer from the last built ROM + game.sym: CustomRoomPtrTable screens
> / $26DD+Custom26DDTable tileset / CustomRoomAttr base(+2) attrs /
> CustomRoomPalPtr palettes with the forced idx1/idx3 rule, dw $0000 →
> derive() borrow with neutral slots 4-7 stand-in; screens bounded by
> project.json; ZERO new format code — reuses
> render_screen/decompress_lz/derive) + `editor2/core/emulator.py`
> (cross-platform launch: macOS `open -Ra`-probed SameBoy → `open`;
> Windows startfile; Linux sameboy → xdg-open; `{rom}` custom command) +
> `editor2/tests/test_app.py` (offscreen smoke, PySide6-absent → SKIP like
> verifier check 5; room-view pixel assert + placeholder skip; `--rom`
> asserts GUI-path md5 == test_compiler REFERENCE_MD5 — **machine-verified
> this session: 7 rooms listed, room $6B/$70 render with correct
> palettes (amber $70 matches the S42 proof room), GUI build
> byte-identical to `46ba6991…` (the S71v2 patched pin)**). Renderer
> EMULATOR-VALIDATED per the new §11 rule: PyBoy in-game capture of $6B
> (user's real .sav, CONTINUE → warp) shows the identical color set the
> renderer emits. USER DECISIONS (S72): editor is CROSS-PLATFORM
> (Win/Linux possible, primary macOS), real native-widget app not HTML —
> EDITOR_DESIGN reframed; preview strategy = simulate only table-derived
> renders, emulate the rest via an embedded-PyBoy panel (EDITOR_DESIGN
> §11, new Phase 3 box). Gap-audit boxes ADDED (user-directed): Phase 2
> preserved-systems flag-audit + orphaned-trigger validator (was cited by
> EDITOR_DESIGN but never boxed); **E7 Milayou player art
> (campaign-blocking, zero prior coverage)**; E8 shop RE (user: hex
> editors edit stock/prices — likely shallow); **E9 item authoring incl.
> the USER SPEC: WarpWing → single-slot like BeastTail + permanent (not
> consumed) for warping anything**; Phase 3 NPC sprite-id catalog promoted
> from the S70 residual. Repo-layout doc fix: `editor2/` row added (was
> missing). LATE S72 (first user run): Pillow added to run deps +
> graceful import error; **RGBDS v0.6.1 preflight** in
> builder.check_toolchain (the user's brew rgbasm v1.0.1 produced the raw
> hardware.inc SECTION/ENDM wall — now a one-line versioned error with
> install steps) + app "Set RGBDS folder" preference (build_rom
> rgbds_dir kwarg, PATH prepended for make only); user decision: the
> 0.6.1 pin is PERMANENT (vendored-toolchain policy; bundling hides it —
> EDITOR_DESIGN "Toolchain preflight").**)
>
>

---

## S74 (aged out of PROJECT_STATE in S76, verbatim)

- **S74** (2026-08-01, v2 2026-08-02): Earthquake chain $E5-$E8 — sweep fork + victory gate (allies hit even on a battle-winning cast), tier-scaled shake bursts (step-2 tick, entry 4), wind anim removed at the anim-index source (GetAnimPresentId → quiet id $12/idx $0D), 2-line announce, SKIL descriptions, flying export. ROM0 back to vanilla. Owner: BATTLE_SKILL_SYSTEM 13.7 (+13.7.9). v3 (2026-08-02b): shakes moved into the cast-anim slot (announce -> shakes -> blink/damage, the v2 simultaneity fixed), 3-line ally banner, fly-dodge beats ("But X flew above it!", both sides, solo-caster silent). v4 (2026-08-02c): banner "Allies are caught/in a seismic wave!" fits the 2-line box; fly line is party-side only (enemies keep "Has no effect"), keyed on $db89; the party-hit refire is gone and quake beats use vanilla per-beat damage sounds (damaged beats ding, flyers stay silent). PyBoy-verified, awaiting user test. Patched pin `d1f5eb49…`.


## S74-S76 verbose blocks (moved verbatim from PROJECT_STATE at S78)

> Last verified: 2026-08-06 (Session 76 — **standalone randomizer, and the
> German build brought in scope**. USER-TESTED and signed off. No patches are
> applied by any of it: `randomizer/` rewrites data tables only, so saves stay
> valid across builds and reseeds.) — verifier PASS 6/6, clean `1ca6579…`
> untouched. S75v4 patched pin `ce1e7369…` unchanged (this session touched no
> patch).
>
> S76 in three parts. (1) **Region portability**: the German build
> (`08bca718…`) carries every mechanical table at the SAME offset with
> IDENTICAL bytes except the two in bank `$14`, shifted exactly `+$70`; boss
> trigger EIDs proven region-independent by script-token census. One codebase
> serves both. (2) **The randomizer** — bosses, breeding, encounters, skills,
> growth, resistances, exp curves, arena, starter — built on the invariant that
> an enemy row keeps its level, six stat words and exp reward, so only identity
> and moves change and pacing is preserved by construction. (3) **Two shipped
> difficulty bugs, both caught by the user, both now regression-tested**: enemy
> moves were banded on `SkillLearnReqTable` (a LEARN gate, not a DAMAGE gate),
> which put flat 10-16 all-foes breath on Gate-of-Beginning enemies; and
> encounter pools were bucketed by quantile rather than exact level, which moved
> level-4/5 rows (ATK 26-35) into a level-1 gate. `randomizer/audit_threat.py`
> now proves per-row damage parity across all 487 enemy rows (currently 0 rows
> harder than vanilla, 0 bosses harder, both builds).
>
> S76 also decoded the **library recipe TEXT** (bank `$4D`, dispatch entry =
> species + 5): hand-authored strings that read nothing, while the parent
> SPRITES beside them resolve live through bank `$16` entry 1. Editing
> `FamilyRecipeTable` moved the sprites and left the words frozen — user-caught,
> emulator-reproduced, now regenerated by `randomizer/librarytext.py` behind a
> reconstruct-before-write gate (193/197 vanilla strings rebuilt byte-for-byte;
> the 4 that differ are vanilla TYPOS, which is what proved the strings were
> hand-authored). Power-calibration numbers and the coherence sets an editor
> must maintain are written up explicitly for editor use.
>
> Last verified: 2026-08-02 (Session 75 — **custom skill #5 $E9 "Mourn":
> v1 mechanics USER-CONFIRMED; v2 banner-ordering PyBoy-verified; v3/v4 =
> the Dracky-crash investigation: TWO byte-neutral fences + the crash-config
> VALIDATOR (verify_integrity check 6 + editor-builder-integrated)** —
> verifier PASS 6/6, compiler 39/39, clean `1ca6579…` untouched, S75v4
> patched pin `ce1e7369…` (supersedes v2 `762c0df0…`, v1 `a914e489…`, S74
> `d1f5eb49…`).)
>
> S75 crash investigation (user-reported wild-gate-Dracky freeze: black →
> white → frozen; SameBoy backtrace = garbage execution at $4d:$4a87 with a
> WRAM return address $d7b5 and $58/$50 FX-driver frames). Findings, in
> order of hard-won honesty: (1) **RETRACTION — the rig "bank_006
> regression" was an input-alignment artifact**: the A-only masher wedges
> in the post-battle join menus at unlucky cadences on EVERY ROM incl. S74
> (measured: S74 stalls at cadences 19/23/27/29; the earlier 3-cadence
> "S74 clean" sample was luck). Timing-shifting ANY code moves which
> cadences stall. (2) The S21 Clam stream is VALID (decodes to exactly 36
> tiles via dwm.sprite_codec — same as the original Dracky stream); the
> stream-size theory is dead. (3) Two REAL latent hazards found and fenced
> byte-neutrally: **LearnCode2Guard06** (bank $06 $7F1F, jp-trampoline at
> Jump_006_50b5: custom ids $E1+ can never stat-learn via the unexercised
> code-2 display path — they divert to the skip-record path; vanilla ids
> unchanged) and **SlotProbeGuard50** (bank $50, CmpBtl_6383 head
> trampoline + 13 tail-fill bytes: the level probe rejects slot index >=
> $28; measured: the exp walker leaves $cac0==40 post-increment and a
> stale-$cac0 re-probe processes phantom slot 40 whose "record"
> $CAC1+40*$95=$E209 is ECHO RAM aliasing battle state at $C209, with a
> post-probe exp WRITE into the alias when the residue looks alive). (4)
> **tools/validate_custom_data.py**: hard-errors on crash-capable configs —
> universal-qualifier learn rows without the code-2 fence, missing slot
> fence, learn-record structural violations (18-byte stride, level range,
> prereq refs, scan-bound == last id + 1), and bank-$36 sprite redirects
> whose replacement stream does not decode to the original's exact tile
> count. Wired into verify_integrity as check 6 AND editor2/core/builder
> build_rom (the editor refuses to hand back a crash-config ROM);
> test_compiler gains a PASS/FAIL validator test (39 tests). (5) The
> user's actual crash is NOT yet reproduced (field-triggered battles all
> clean; the $58:$401D id-keyed FX-pointer lookup fires only with the
> basic-attack action id in tested modes — custom ids route through the
> forked skill pipeline; the $58 backtrace frames are victims of prior
> stack corruption, not the origin). User given a SameBoy trap kit
> (watchpoints on the corruption channels) to catch the origin on next
> occurrence.)
>
> Session 75 (2026-08-02 — **custom skill #5: $E9 "Mourn" (user-directed):
> single-foe attack, damage = the VANILLA ATK-vs-DEF physical roll ×
> (dead allies + 1) — 0 dead (all alive or caster alone) = 1×, 1 dead = 2×,
> 2 dead = 3×; MP 10; natural learn standalone lvl 3; announce "used
> Mourn!"; conditional boost banner "Fallen allies / lend power!" (renders
> + 40-frame hold ONLY when the multiplier fired); presentation = EvilSlash
> ($40 proxy) played TWICE back-to-back in the cast-anim slot. BUILT,
> PyBoy-verified (0/1/2-dead multipliers incl. persistence across 8+ rounds
> AFTER the engine's KO scan, MP deduct + afford stop, double-slash + clean
> release, announce→banner→damage ordering measured safe, kill chain +
> victory, Tremor/Infernos/plain-attack regressions), NOT user-tested; the
> deterministic queue-poke rig stood in for a real-menu commit (§13.8 rig
> caveats)**. Owning docs: BATTLE_SKILL_SYSTEM §13.8 (defense-calc dispatch
> pattern = FarSkillFork returns a per-id pointer-holder: MournDispatchPtr
> $52:$7FFA -> MournDispatch52 in the $6c56 dead-code window = `call
> CalcDefenseWrapper / jp CustomDispatch52_shared`; the $dd1b THREE-STATE
> finding $00 alive/$01 processed-KO/$FF empty — presence must test != $FF;
> the sticky-terminal $FF slash counter), KEY_LESSONS (6 new incl. the
> TriggerBattle-mimic battle rig $DA03/04+$DA02+$DA09+$C905+$C8EB.6 and the
> original-ROM-.sav checksum rejection), wram.asm (wMournBoosted $DEBA,
> wMournSlashes $DEBB). As built: banks $72 (SkillMourn + QuakeAnimHold72
> .mourn replay), $52 (2nd trampoline, 6 dead bytes + 2 tail bytes), $53
> (MournGate_delay + ladder jp), $4c (2 msgs + LoadB4c_MournBoost, pool
> nops 1:1), $54/$07/$41/$56/$58/$5f/$06/$14 one-line recipe rows; bank $07
> was FULL — 3 bytes reclaimed in MPPtrFromId via `ld h,HIGH(table)` with a
> link-time page ASSERT; bank $41 name funded from the dead $00 fill before
> Scorch. v1 notes: real-menu battle commit not rig-exercised; one -13
> among eleven 2× events (possible apply-time variance — watch); an
> abnormally aborted action leaves the $FF terminal -> next cast skips its
> animation once, self-heals. v2 (2026-08-02b, after user
> confirmation of v1 mechanics): banner moved BEFORE the attack animation —
> MournCountDead shared counter evaluated in the anim fork on slot entry;
> banner render + $FE hold (45 f + ~43 f typing, driver deferred — bounded,
> measured safe) precede the two slash plays; handler keeps only the
> multiplier; MournGate_delay now a natural pass-through; bank $72 only.
> PyBoy: banner pixels identical to the v1-confirmed string, persists
> through the slashes, announce replaces it; 2x/0-dead/Tremor/MP all
> re-verified. Awaiting user test of the ordering.)
>
> Last verified: 2026-08-01 (Session 74 — **custom skill chain $E5-$E8
> "Earthquake" (Tremor/Quake/QuakeMore/QuakeMost) BUILT + PyBoy-verified
> end-to-end; NOT yet user-tested** — verifier PASS 5/5, clean `1ca6579…`
> untouched, S74 patched build (pin recorded below; the S73 patched pin
> `224b1176…` is superseded).)
>
> Session 74 (2026-08-01 — **custom skill #4: the 4-tier Earthquake chain
> $E5-$E8 (user-directed): all-foes earth damage 40-60/90-120/150-190/
> 240-270 (top = 1.5x WhiteAir), ALSO hits the caster's own side for 1/3,
> skips caster + ALL flying combatants both sides, screen-shake + GreatTree
> rumble ($68) presentation, MP 5/10/16/24, learn chain lvl 2/4/6/8 each
> tier requiring the previous. BUILT, PyBoy-verified (damage both sides,
> 1/3 ally division, caster + flying skips, crossover banner, repeat casts,
> MP deduct, MagicBurn/attack/Infernos regressions), NOT user-tested; a
> real-menu commit was not scriptable — the deterministic queue-poke rig
> stood in (see §13.7 rig caveats)**. Owning docs: BATTLE_SKILL_SYSTEM
> §13.7 (sweep-fork architecture + the TWO traps: looping-SE `$dd80`
> deadlock with the ROM0 vector-gap stopper stub, and `$db88` mid-sweep
> contamination -> wQuakeCaster/phase-keyed division), TOOLS_AND_DATA
> (dump_flying_flags.py -> extracted/flying_flags.json: 221 species, 48
> flying, per-species ROM offset for the editor), MONSTER_DATA (+$04 edit
> note), KEY_LESSONS (4 new), DOC_AUDIT (stale-$17 record story corrected).
> As built: bank $52 sweep window $719C -> QuakeSweep72 (rst-return-via-DE);
> bank $72 SkillQuake + QuakePowerTable + QuakeSweep72; bank $53 gate
> (QuakeGate_delay: ally-banner render + hold + delay==8 damage-pair refire)
> + widened TameSound suppressors ($E1-$E8) + QuakeFirstTgt53; bank $00
> QuakeShakeEnd stub in the AUDITED-DEAD vector-gap bytes $0051-$0057/
> $005C-$005F + 4-for-4 wobble window at $0574 (SFX-$00 stopper when the
> shake ends — `$c8b1` has no vanilla writers so it is Quake-only); banks
> $54/$07/$06/$41/$4c/$58/$5f/$14 as per §13.7 (records POWER WORDS ZERO —
> nonzero powers loop the presentation; bank $07 index rebase $DE->$E0 +
> `inc a` byte-trick to fit; bank $06 second learn table past $7F7F with
> tail bytes verified unmoved). WRAM: wQuakePhase $DEB4, wQuakeAllyMsg
> $DEB5, wQuakeCaster $DEB6. v1 limitations (v2 items): single-line
> wordings (vanilla multi-line battle enders `63 FC 10 EC F2` undecoded),
> Infernos flame visual under the shake, ~80-frame rumble then stopper,
> all-enemies-flying = no-op cast, first-match caster derivation, blank
> $E5-$E8 descriptions (bank $056), earth-resistance slot deferred.)
>

>

## S77 verbose block (moved verbatim from PROJECT_STATE at S79)

> Last verified: 2026-08-06 (Session 77 — **randomizer part 2**: breeding tree
> regeneration, stratification, and a rebuild of skill assignment onto vanilla
> placement.) — verifier PASS 6/6, clean `1ca6579…` untouched. S75v4 patched pin
> `ce1e7369…` unchanged.
>
> S77's central finding: **the skill record's power field is 0 on 43 of the 222
> skills**, because their handler computes damage internally (Sacrifice,
> MegaMagic, BeDragon, GigaSlash, Beat, Kamikaze, SamsiCall). Every rule that
> banded or capped on power was blind to exactly the dangerous ones, which
> produced six separate "how is this in gate 1" bugs, each patched individually
> before the pattern was seen. The fix needed no formula tracing: **vanilla's own
> placement** (min level, median level, row count per skill) is a complete danger
> rating for all 222. See BATTLE_SKILL_SYSTEM "The record power field is BLIND".
>
> Second finding, equally load-bearing: **every validation this project had was
> an aggregate** — "0 rows harder than vanilla", correlations, depth profiles,
> multiset equality — and all of them passed on a build with a species at 23x
> vanilla MP growth and a skill on 44 rows instead of 1. `profile_check.py` adds
> per-ENTITY envelope checks and found five real defects immediately. This is the
> validation layer the editor needs too (PROJECT_COMPILER "Validation the editor
> must run").
>
> Also decoded/measured this session: breeding depth is a function of matcher
> SPECIFICITY (family x family can never exceed depth 1); boss joins are tree
> roots and collapse depth if identity runs after generation; vanilla keeps 0 of
> 15 early-encounter species free of specific x specific recipes; vanilla's
> never-join rate climbs 0%/20%/62%/70%/88% by boss level band, which is what
> protects the 82% breed-only endgame showcase.
>
> NOT yet resolved and listed in ROADMAP: starter roll is unconstrained and is
> likely the biggest driver of early-game difficulty variance; 27 growth pairs
> and 2 skills still fail `profile_check`; a combat simulator is blocked on
> finishing the damage formula.
>

> Last verified: 2026-08-13 (Session 80 — **combat-simulator arc part 3:
> the ENEMY AI decision machine, traced and differentially validated
> 26/26 over 10 EIDs.** Byte-neutral: no patches touched; verifier PASS;
> clean and S75v4 patched pins unchanged. Everything lives in
> `simulator/ai.py` + `measure_ai.py` + `validate_ai.py` +
> BATTLE_SKILL_SYSTEM §15.10; RAM rows in known_RAM_map [S80].)
>
> The machine is **bank $57** (S79's "$58" was imprecise; $58 entry 11 =
> the cat-1 plain-attack score service only), phase 5/$d9ed=1, sub-state
> $D9EE. Pinned + validated: enemy_stats ai_weights → category bases
> (+17/+19/+18 → $DC44/$DC4C/$DC54 = dmg/status/heal; +20 → $DC5C, the
> state-0 act/flee preamble); category score = base//10 + plan_adj +
> swapped-r16 % ladder-mod; the quirky partial sort + the not-rank1 +$1E
> cat1 "runner-up" bonus (hidden $73AB check — KEY_LESSONS); option
> lists $DC64 {tag, skill}; per-skill sums (record ai_weight + rand%16);
> tag filter + effect-class evaluator dispatch ($DD26 +10-bump/veto
> accumulator; chains stubbed); pick argmax with RNG-bit0 ties; commit
> writes skill only (target $FF, resolved later). $dd0b per-actor modes:
> 0 lightweight picker / 1 full machine / 2 finisher scan. **S79 stall
> ROOT CAUSE: retry $76A9 increments $dd02 unbounded.** PyBoy hook trap
> found (hooks shift input timing → dense-cadence protocol,
> PYBOY_DEBUGGING). Residuals → ROADMAP S81 (rule chains, target
> resolution, tactics plan adjusts, loop validation).
>
> Last verified: 2026-08-10 (Session 79 — **combat-simulator arc part 2:
> TURN ORDER, the action machine, and the status layer.** Byte-neutral:
> no patches touched; verifier PASS 6/6, clean `1ca6579…` and S75v4
> patched pin `ce1e7369…` both unchanged. Everything below lives in
> `simulator/` + BATTLE_SKILL_SYSTEM §15.6-15.9.)
>
> Turn order is now formula-exact and differentially validated **143/143
> over 47 rounds** (incl. a 4-actor round): TurnOrderBuild `$58:$54D1`
> rolls key = AGL−span+rand (span = 1+AGL/4+AGL/16 ≈31%, one GenerateRNG
> step per ready combatant, $DD13[slot]==2 = ready), floors at 2, boosts
> the defensive-interception class {Ironize/Imitate/Cover/Guardian/Dodge/
> Defence/StrongD/SuckAll/BladeD/IRONIZE} +$0600, SquallHit +$0400,
> forces PsycheUp last ($0001), then a literal ties-swap bubble sort
> (9th pair out-of-bounds — modelled verbatim) compacts into **$DB79**
> (cursor $DB82). The ROADMAP breadcrumb was falsified: BattleFunc_6a13/
> 6a49 are the Upper/AglUp stat-CAP helpers, not flee/order.
>
> All four §15.6 traced-only items MEASURED: slot-2 ×0.8 (rig `--party3`;
> 45→36 with ti=1 control unchanged), RainSlash (4-hit cap, per-hit
> ×8/10, ×6/10, then ×0.4×2; dead-target side-walk), Sacrifice (CURRENT
> HP, not max — kill 180 / survivor 179 at HP 180/Max 250, 4/4 branches,
> zero RNG steps), and the arena variants — which falsified two forks:
> Kamikaze's `$6259` and WindBeast's `$642B` "arena" branches key on
> **$C86C (LINK)**; real arena (db73=2) takes the boss/enemy-side paths
> (Kamikaze arena = (casterHP−1)/2 = 99, measured). damage.py corrected;
> S78 corpus still 698/698.
>
> Also mapped: the 28-state action machine ($52:$6C60; ROADMAP knew 8),
> the apply-step exclusion ids by name (gate = $DD6F bit5), phase 9 =
> END-OF-ROUND DoT processor (poison MaxHP/16 / heavy MaxHP/6 + caps),
> $DB77/$DB78 pending-action pair + META action codes (>= ~$BA; $E9 =
> flee-class), and the measured status byte map ($DB00-block: sleep/
> paralyze/poison/confusion/curse/StopSpell/Surround/MouthShut/DanceShut/
> LureDance one-shots) with the sleep wake roll ported exactly from
> $53:$4AEB (37.9/62.9/88/100% by counter). Round core assembled in
> `simulator/battle.py` — components engine-exact, **loop glue NOT yet
> differentially validated** (S80, with AI).
>
> Hazards logged for the romhack: the enemy-AI phase-5 machine can stall
> (re-roll loop on flee-class $E9) under degenerate state — reproduced by
> rig-forcing HP>MaxHP, now structurally avoided in both rigs; ROOT CAUSE
> found S80 (unbounded $dd02 retry at $57:$76A9); enemies with custom
> skill ids need an AI-table audit before the editor exposes movepools
> (S81). Open residuals now tracked in ROADMAP S81: rule chains, target
> resolution, $DB07 timer statuses, +2 bit1 DoT applier, curse magnitude,
> sleep-application writer, MISS/dodge, meta-actions.
>
> Last verified: 2026-08-10 (Session 78 — **combat-simulator arc part 1:
> the DAMAGE LAYER, traced and differentially validated.** Byte-neutral: no
> patches touched; verifier PASS 6/6, clean `1ca6579…` and S75v4 patched pin
> `ce1e7369…` both unchanged. New top-level package `simulator/`.)
>
> The whole damage pipeline is now formula-exact: the physical roll
> (`CalcSkillDefense`, three regimes + the 3rd-party-slot ×0.8 + zero floor),
> record spells (min + RNG1 mod (range+1), side-selected, **DEF does NOT
> reduce spell damage** — S77's open question), resistances (27 levels packed
> 2-bit MSB-first at $DD28+slot*7 — 15/15 element cores matched the FAQ),
> every multiplier/hit ladder incl. the guard-bit rows, and all 43
> handler-computed specials (MegaMagic = 2MP+2L ±10% — the old "(…)/4" note
> was wrong; WindBeast/Vacuum level-based; Kamikaze/Sacrifice/Ramming;
> slashes with a 1.3125× amplify row; BiAttack/QuadHits ATK-rewrites). The
> Python model (`simulator/damage.py`) replays emulator captures **698/698
> exact** (`simulator/validate_damage.py` + `s78_master_events.json`;
> measured on the patched build + the user's hacked .sav via the S75 rig +
> waypoint hooks).
>
> The discovery of the session: **$DB73 is the battle TYPE** (wild 0 / boss 1
> / arena 2; $FF is just its loss value), and bank $53's `LoadBtlC_51aa`
> gates {Beat, Defeat, Sacrifice, Kamikaze, Paralyze, $6B, K.O.Dance} to
> AUTO-FAIL vs enemies in boss battles — the classic no-death-on-bosses rule,
> now in code. Corollary for all future rig work: the S75 rig sets $DA09=1,
> so rig battles are BOSS-typed; poke $db73=0 for wild-battle semantics.
> Kamikaze forks on it (wild: targetHP−1; boss: (casterHP−1)/2 — both
> measured).
>
> User directions logged: full simulator for the romhack (not just
> randomizer); acceptance must cover BOTH control variants (gates/bosses =
> per-monster commands; arena = tactics only); AI to be reverse-engineered in
> a later session of this arc; EDITOR_DESIGN §11's never-simulate rule
> superseded (amended in place — differential validation is the guardrail
> now). DWM-original.sav is REJECTED by the English vanilla ROM (title shows
> only NEW GAME); user confirms NO saves are from the German build, so the
> likely origin is an older PATCHED build (pre/post-S69 checksum formats are
> mutually rejecting) — the vanilla-formula ground truth remains the patched
> ROM + DWM-hacked.sav pair, which is fine since patches leave the damage
> machinery untouched.
> Not yet measured (traced only, marked in §15.6): slot-2 ×0.8, arena
> variants, RainSlash hits 2+, Sacrifice magnitudes. S79: turn order, apply
> step, status durations, AI. Owning: BATTLE_SKILL_SYSTEM §15,
> TOOLS_AND_DATA §2.10, known_RAM_map, ROADMAP S78.
>

## S82 block (moved verbatim from PROJECT_STATE, S85)

> Last verified: 2026-08-15 (Session 82 — **ANNOTATION CATCH-UP part 1
> (Iron Rule 6 gate): the bank-$57 AI decision machine is now annotated
> in source.** Byte-neutral: labels/comments/data-resection only; no
> patches touched; verifier PASS 6/6; clean `1ca6579…` and S75v4 patched
> pin `ce1e7369…` both unchanged. Built S82, NOT yet user-tested (no
> test ROM this session — byte-neutral acceptance = verifier PASS +
> unchanged hashes). Tool: `tools/resection_ai_bank57.py` (idempotent;
> probe-build line→addr mapping; probe AND final builds asserted
> byte-perfect). ROADMAP S82 box ticked; **S83 (banks $52/$53/$58) is
> the remaining annotation gate** before the S81 residuals / pacing
> layer unblock.)
>
> As annotated: state dispatch AIDecisionStateDispatch_6e0e + inline
> AIStateDispatchTable_6e12 converted to dw (states 0-7 named
> AIState0Preamble_6e2a … AIState7ChainWalker_7865);
> AIRuleChainIndex_4302 + the three category chains converted to labeled
> dw lists — counts BYTE-VERIFIED **39/85/40** (S81's "61" for cat2 was
> a miscount; DOC_AUDIT S82); all 131 rule routines labeled (~30
> semantic with S80/S81-provenance comments incl. the $4E36 vanilla-bug
> block; rest neutral AIRule_<addr>); stage/helper renames with
> repo-wide reference updates (AIState1CategoryScores_7129,
> AICategoryRank_7322, AICat1RunnerUpCheck_73a5, AISatAdd_455f
> [ex-AddBToHL16 — its "16-bit" description was wrong],
> AIScanSlots_4456, AIRetryAllZero_76a9, AIChainZeroCell_788b /
> AIChainApplyDelta_78a2, AICallRuleAtHL_78ca, preamble family, …).
> Comment fixes from byte-reads: **CheckMonsterSlot ($00:$2FA5) header
> said "CF=valid" — INVERTED** (CF SET = NOT a live monster; 101
> bank-$57 call sites; DOC_AUDIT S82); DATA_STRUCTURES helper rows
> corrected. Clarified in-session: §15.10.5's "$5206 resist service" is
> the rst $10 FAR-CALL operand (bank $52 entry 6), not a bank-$57
> address — doc idiom, no fix needed. Residuals (ROADMAP S82 box): rule
> BODY re-emission (inline rst $00 handler tables desynced mgbdis inside
> many bodies; all 131 heads boundary-align, probe-verified) +
> DanceShut/MouthShut + DeMagic/ThickFog rule addresses unidentified
> among the neutral labels. Owning: disassembly/bank_057.asm itself +
> BATTLE_SKILL_SYSTEM §15.10.5, DOC_AUDIT S82 (3 rows), KEY_LESSONS S82
> (2 lessons), TOOLS_AND_DATA (tool row), ROADMAP S82.

## S83 block (moved verbatim from PROJECT_STATE, S85; the block had lost its "Last verified: 2026-08-20 (Session 83" header line in S84)

> (Iron Rule 6 gate CLEARED): the battle core — banks $52/$53/$58 — is
> now annotated in source.** Byte-neutral: labels/comments/data-resection
> only; verifier PASS 6/6; clean `1ca6579…` unchanged; patched build
> assembles with all renames propagated (patches/bank_052/053/058/072).
> Built S83, NOT yet user-tested (byte-neutral acceptance = verifier
> PASS + unchanged hashes). Tool: `tools/resection_battle_core.py`
> (idempotent per bank; S82 probe-build technique; probe AND final
> builds asserted byte-perfect). **The S81 remainder and the pacing
> layer are UNBLOCKED** (ROADMAP).)
>
> As annotated — bank $52: CalcSkillDefense regime comment; renames
> DamageSlot2AdjustFloor_61ec, RecordDamageRoll_679c, MegaMagicDamage_653e,
> KamikazeDamage_6232, ResLadderBreath_676c/ResLadderElemSlash_6782,
> HitLadderBeat_6749/HitLadderKamikaze_6733, DamageMul8/6/4Tenths_69xx,
> UpperStatCapCheck_6a13/AglUpStatCapCheck_6a49 (falsified-breadcrumb
> note kept), SkillHandlerDispatch_6cc7, ConfusionActionRewrite_7ab5;
> new BattleActionMachine_6c4d + **28-state BtlActStateTable_6c60
> converted to dw** (states byte-verified; $12 duplicates 0; $1A = KO);
> BtlActState2Apply_6d56 (the $6D83 cp ladder IS the id-exclusion list —
> code, not data); GroupVictimLoopA/B_71b5/71ed; BtlOutcomeHitPath_4200/
> MissPath_4225; ConfusionActionTable_7aff → db (**bank $52**, not $53 —
> DOC_AUDIT S83). Bank $53: BtlPerActorSetup_44ca + 9-dw
> SetupSubStateTable_44ce; ActPhaseDispatch_51e8 + **16-dw
> ActPhaseStateTable_51ec** (geometry exact, $51EC+32=$520C);
> PerActorStatusGates_4558; TargetReResolve_4799,
> DeadTargetRedirectScan_47e8, SleepWakeRoll_4aeb, CurseSelfHit_4c50,
> BossProtectionGate_51aa (ladder byte-verified: LINK skip, enemy-side,
> db73==1, skills $12/$13/$14/$3E/$69/$6B/$71); SacrificeEntry_670e /
> SacrificeResolve_67a9. Bank $58: TurnOrderBuild_54d1 (+init
> byte-verified), TurnOrderKeyRoll_5662 (formula), TurnOrderSort_55c2
> (ties+9th-pair), TurnOrderCompact_5707, TurnOrderDefensiveBoost_56cf,
> QueuePlainAttack_54ce; head region re-emitted as **14 rst $10 service
> slots + the previously-undocumented 230-dw per-skill table
> BtlSkillTargetDispatch_401d** (skill names inline; structure-only
> claims). **CORRECTION (DOC_AUDIT S83): §15.10.6's resolver far-call is
> bank $58 ENTRY 8** (BtlQueueFetchService_5498 → per-skill dispatch),
> not "entry 4"; TargetSlotResolver_6379 (dw slot 4) is the measured
> RNG-fishing resolver, and TargetSelfWrite_6367 (byte-read) is the
> 23-skill self-target service. **BREADCRUMB: $50:$4C87 is the ROM's
> only direct entry-4 far-call — candidate for the OPEN post-commit
> target write site (NOT measured).** rst $10 convention pinned against
> $00:$0020: addr = $4001 + 2·L, L = entry index. Owning: the three
> bank sources + BATTLE_SKILL_SYSTEM §15 (renamed citations + §15.10.6
> fix), DOC_AUDIT S83 (2 rows), KEY_LESSONS S83, TOOLS_AND_DATA (tool
> row), ROADMAP S83.
