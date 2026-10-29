# Skills

The **Skills** tab edits the game's 222 original skills, the ten **custom
skills** built into every build (MagicBurn, Tame / TameMore / TameMost, Anchor,
Tremor / Quake / QuakeMore / QuakeMost, Mourn) and your project's **new
skills**. Pick one on the left (search by name or number; the list can show
only skills, battle actions / boss moves, battle items, the custom skills or
your new ones). **Bold** = changed from the original. Every field has a tooltip
saying what the game does with it. **Back to the original skill** puts every
field back (a new skill: back to what its base gives it).

## Name and SKIL text

- **Name** — 1-9 letters, digits, space and `' , . ! ? - &`. Every menu, battle
  message ("Slib casts Blaze!") and the library use it. Other tabs' skill lists
  follow the new name.
- **SKIL text** — the info box of the field SKIL menu: up to 3 lines of 18
  cells (`'s`, `'t` and `..` are one cell). The picture is the game's own font.
  The battle actions and items (ids 151-212) and RUN / IRONIZE / Ahhh share an
  empty text in the original game; typing one gives that skill its own.

The bar under the list shows how full the name and text blocks are. A name or
text that no longer fits its block moves to spare room automatically (names:
the bank $41 space new monsters' names share; texts: a 2,993-byte spare area).

## MP and learning

- **MP** — the game keeps the cost twice: the battle charges one copy (0-255),
  the field SKIL menu shows and charges the other. The editor sets both.
  Farewell and MegaMagic take **all** MP (the game empties it in their own code,
  so their cost is not a number); StepGuard and MapMagic are field-only.
- **Learned at level** and **at least** HP / MP / ATK / DEF / AGL / INT — a
  monster learns the skill at a level-up when the skill is in its learnable set
  (its three natural skills and what they evolve into) and it meets the level
  and every stat. Below the level it cannot cast it yet.
- **Evolves from** — up to 5 skills: a monster that knows one of them learns
  this one **in its place** (Blaze → Blazemore → Blazemost).
- Ids $DA-$DD (LIFE, RUN, IRONIZE, Ahhh) have no learn row (those bytes are
  code); they can still be a monster's natural skill.

## Power

Damage or healing is a random value from **min** to **max**. Your monsters use
the first pair, enemies the second (enemy Blaze is weaker than yours). Some
skills compute their effect in code and ignore these numbers; the note says
which skills share this skill's effect code. The built-in custom skills set
their damage in code, so their power boxes are off (Quake's numbers are under
**Its own numbers and lines**).

**Element** — the resistance the skill's DAMAGE tests (Fire, Ice, Lightning …):
the target's level 0-3 in it cuts the damage (spells: 1 = 85 %, 2 = half,
3 = immune; breaths and slashes have their own ladders). Only skills whose
damage really tests a resistance have one — measured for all 222 originals:
the fire / heat / explosion / wind / ice / lightning spells, the breaths,
BigBang, RockThrow, MegaMagic, Ramming, the elemental slashes, MultiCut,
WindBeast, Vacuum, GigaSlash (38). Pick another resistance, or **none** (the
damage ignores resistances). The list is grouped like the Resistances tab, and
**Earth** (S159) is there: Tremor / Quake / QuakeMore / QuakeMost or a new skill with
Earth test the monsters' Earth level. The Resistances tab lists which skills test which
resistance and moves them by right-click — see *Resistances (and Earth)*. The built-in custom skills deal raw damage; giving
one an element runs it through the spell ladder. The AI's element (Monster AI)
follows your choice.

## Targets

One foe / all foes / one ally / all allies / the user itself. The battle menu
asks for a target only for "one …"; an "all …" skill is applied to every monster
on that side. Moving a skill to the OTHER side (a heal aimed at foes) rarely
makes sense — its effect code was written for one side — so test it in battle.

LoneWolf, Punish, Finish, Rupture and Blunt offer exactly two: **one foe** (the
monster AI then picks the best foe for the skill — Rupture one with an ailment,
Punish the most buffed, Finish the most hurt, Blunt the strongest) or **all
foes** (each foe in turn). The other built-in custom skills keep their own.

## Monster AI

Only the enemy / tactics AI reads these four; they never change what the skill
does:

- **Plan** — attack, status / weaken or heal / support. The AI first picks a
  plan, then a skill of that plan.
- **Weight** (0-255) — how much the AI likes it.
- **Element** — the resistance the AI assumes the skill tests (it avoids
  targets that resist it). The real element is chosen by the effect code.
- **Damage class** — none / spell damage / breath damage.

## Behaviour

The battle rules the skill follows. Each box is one bit some part of the game
reads (decoded by finding every place the game reads a skill's data):

- **cut by Defence / StrongD** — A target guarding with Defence takes half, with StrongD a tenth.
- **misses under Surround** — A caster under Surround misses it 62.5 % of the time (and 37.5 % more under the status +7 blur).
- **keeps its target** — The target chosen when the turn was planned is kept; without it a 'smart' monster re-aims at act time.
- **breath** — A breath: sealed by MouthShut ('its mouth is bound shut'), reflected by TailWind, absorbed by SuckAll; the fire/ice breaths are boosted by SuckAir. Breaths 'spit' instead of 'cast'.
- **dance** — A dance: sealed by DanceShut ('the dance is blocked'); 'dances' instead of 'casts'.
- **spell** — A spell: sealed by StopSpell, broken by a spell-breaking field; 'casts'.
- **physical contact** — A blow: cannot reach a monster in the air (HighJump), halved by BladeD, a target may grab an ally as a shield.
- **reflected by MagicBack / Bounce** — A wall of light (MagicBack, Bounce) on the target turns it back.
- **redirected by Cover / Guardian** — An ally protecting the target (Cover, Guardian) takes it instead.
- **stopped by Ironize** — A target turned to iron (Ironize) is not affected; the action fails.
- **can be a critical hit** — May land a critical hit (or a pitiful one); a caster with ChargeUP armed 'attacks with full force'.
- **doubled by TwinHits** — Twice the damage while the caster is under TwinHits.
- **boosted by ChargeUP** — Two to two-and-a-half times the damage while ChargeUP is armed.
- **can be dodged** — The target may dodge: 50 % under Dodge / SideStep, else by its agility.
- **TakeMagic soaks its MP** — A target with TakeMagic gains the MP this skill cost.
- **Imitate turns it back** — A target with Imitate 'gets even': the skill is sent back.
- **can snap confusion** — A landed hit may bring a confused target back to its senses.
- **follow-up action** — May be a monster's second action in a turn (the extra-action status; its setter was not found in the ROM and it was never seen in 11,000 measured battle events).
- **can't reach the air** — 'But it doesn't reach X!' against a monster in the air (HighJump).

Shown greyed, because nothing in the game reads them (or only for something
else):

- record +0 — a serial number; nothing in the game reads it
- record +1, low half — nothing reads it (the high half is the AI plan)
- flags7 bit2 — nothing reads it
- flags8 bit3 — nothing reads it
- flags9 bit1 — read only for the confusion 'meta' actions (allowed in a boss battle); an ordinary skill ignores it
- flags9 bit6 — nothing reads it
- flags9 bit7 — nothing reads it (no skill sets it)
- record +10 — read for battle ITEMS only (1 = cannot be used in battle)

## Looks and sounds

**Looks like** plays another skill's animation, screen flash and sounds;
**Sounds like** (S111) picks the sounds alone (default: those of the look —
built-in custom skills: Infernos', what they always played). What the skill does — its effect, damage, targets and messages — stays
its own. Every original skill can lend its look: all 222 were measured lending
it to attacks, group attacks, heals, group heals, self-buffs and enemy casters
(1,554 battles) and none stalled. A look marked **(other side)** was made for a
skill aimed at the other side (a heal's look on an attack): it usually shows
nothing (measured: Heal with Bang's look draws no explosion). A look marked
**(summon)** only blinks the screen (a summon's "animation" is the summoned
monster). **Announced as** is the line the battle
shows when the skill is used. For original skills it is one of the game's
battle messages, shared with every skill that uses it — rewrite it on the **Text**
tab → Battle (S150). For custom and new skills you choose: **its own line** (up to
two pages of two lines of 18 cells; `{name}` = the caster, `{skill}` = this
skill's name), one of the game's lines ("{name} casts {skill}!", "… spits
{skill}!" …), or silent.

## Animation

**Animation** (S112) sets what the skill **shows** in battle, separately from
its look (Looks like still decides the sounds and, with "what its look shows",
the animation):

- **what its look shows** — the original game's choice (the default);
- **an animation** — one of the game's 45 (listed by the skill that shows it)
  or one of your project's **new animations** (the **Animations** tab), and how
  it **moves**: at the target, in the middle of the foes, on each target in
  turn, or flying across from the left;
- **a screen effect** — the screen blinks (Radiant, the summons), fades dark,
  shakes (TwinSlash) …;
- **nothing**.

As in the original game it shows only on the **sides where the look shows
something**: the note under the boxes says what the look shows when your
monsters cast the skill and when enemies do. Sprites only ever appear on the
foes' side — an attack cast by an enemy at your monsters shows nothing, and a
heal or buff shows its animation only when an enemy casts it on itself (the
original game does the same). The preview plays it at the game's speed with
its sounds (the Sound box mutes them).

## Its own numbers and lines

Built-in custom skills only — the data their code uses:

- **MagicBurn**: the **share of the current MP it spends** (original 1/2) and
  the **damage to each foe per MP spent** (original 1). With several foes it
  spends again for each foe in turn, on what is left.
- **Tame / TameMore / TameMost**: the taming meter each cast adds (the meter
  the meats fill: FeedMeat 10, PorkChop 100, Sirloin 400; it caps at 1600), and
  the **damage as a share of the caster's ATK** (original 1/4).
- **Tremor / Quake / QuakeMore / QuakeMost**: the damage range to foes, and the
  **share its own side takes** (original 1/3; 0 = allies are not hurt; flyers
  take nothing); Tremor also holds the two extra lines every tier shares (the
  wave turning on its own side; an ally flying over it).
- **Mourn**: the **extra damage per fallen ally**, as a share of the normal hit
  (original 1: 1 fallen = double, 2 = triple), and the line shown when it fires.
- **Anchor**: the **share of the current MP charged on arrival** (original
  3/4), and the four dialogs (cast in a gate, cast in town with an anchor, cast
  in a special room, cast without an anchor).
- **LoneWolf** (a hit): the damage **in a party of two** (original 200 % = ×2)
  and **alone** (400 % = ×4). Every monster of the caster's party counts, alive
  or fallen; a helper (CallHelp, the summons) does not; with three it is a
  plain hit.
- **Punish** (a hit): the **extra damage per buff** on the target (50 % each:
  two buffs = ×2). A buff is any of TwinHits, ALLCHANGE, TakeMagic, Bounce,
  Barrier, MagicBack, TailWind / StormWind, MagicWall, ChargeUP, SuckAir, Focus,
  SideStep, a raised DEF / AGL (Upper, Increase, Speed, SpeedUp), Dodge, Imitate,
  SuckAll, a Defence / StrongD / BladeD stance — never iron or a transformation.
- **Finish** (a hit): the damage **when the target has full HP** (20 % = ×0.2)
  and **when it is near 0 HP** (200 % = ×2); in between it follows the share of
  HP the target has lost. A hit that lands does at least 1.
- **Rupture** (a hit): the damage **when the ailments burst** (300 % = ×3).
  Any ailment counts (poison, sleep, confusion, curse, paralysis, StopSpell,
  Surround, DanceShut, MouthShut); all of them are cleared by the hit. A target
  without one: "But nothing happens!" — the MP is spent.
- **Blunt**: the **ATK lost** as a share of the target's base ATK — a
  percentage, 1-100 (50 % = half, the original; 33 % ≈ a third, 25 % = a quarter);
  at least 1; ATK never drops below 1. It does **not stack**: on a monster
  already blunted it fails ("But nothing happens!", the MP spent), and the monster
  AI does not pick it then. It resists like Sap (the DefDown resistance); DeMagic
  and Surge put the ATK back (then it can be blunted again).
- **Plunder** (no numbers; one foe only): steals ONE buff of the foe at random
  and puts it on the user, as if the user had cast it this round. It picks among
  the foe's buffs the user does not have yet (if the user has them all, among all
  of them — the foe still loses it). The buffs are Punish's list, with a raised
  DEF and a raised AGL counted apart: TwinHits, ALLCHANGE, TakeMagic, Bounce,
  Barrier, MagicBack, TailWind / StormWind, MagicWall, ChargeUP, SuckAir, Focus,
  SideStep, a raised DEF, a raised AGL, Dodge, Imitate, SuckAll, a Defence /
  StrongD / BladeD stance — never iron or a transformation. How it lands on the
  user: lasting buffs as they are; Bounce and MagicBack replace each other; a
  ChargeUP / SuckAir / Focus starts fresh (it powers the user's next round); a
  stance (Dodge, Imitate, SuckAll, Defence …) lasts the rest of this round; a
  buff cast on a whole side moves only the foe's own copy, only to the user. A
  raised DEF / AGL: the foe's stat goes back to its base and the user gets one
  Upper / Speed on itself (+ half its own base, with the usual caps). It always
  lands (no roll, no resistance; MagicBack, Cover and Dodge do not stop it). A
  foe without a buff: "But nothing happens!" — the MP is spent. The monster AI
  uses it only when a foe has a buff to take (+20 per buff on the richest foe)
  and aims it at that foe.
- **Its line** (the six above). LoneWolf, Punish, Finish, Rupture: the line
  that says what the skill tries to do — it replaces "… uses …!" BEFORE the
  attack and stays on screen while the attack plays; then the hit shows the
  game's own "… takes … damage pts!" with its damage sound and shake, as every
  hit does. **Show it**: *every time it is used* (the default — without it the
  skill looks like a normal attack) or *only when the bonus applies* (LoneWolf
  with fewer than three, Punish on a buffed target, Finish above ×1, Rupture
  when there is something to burst). One page of 2 lines; `{name}` = the user
  (the target and the damage are not known yet). Blunt: its line IS the
  result ("… loses … attack!"), up to 3 pages of 2 lines; `{target}` = the
  target, `{amount}` = the ATK lost, `{name}` = the user. Plunder: its line IS
  the result, shown with the cast's look, up to 3 pages of 2 lines; `{name}` =
  the user, `{target}` = the foe, `{buff}` = the name of the skill whose buff was
  taken (Barrier, ChargeUP … ; Upper for a raised DEF, Speed for a raised AGL, the
  stance by its level) — a renamed skill shows its new name. The original:
  "{name} steals / {target}'s" then "{buff}!" — a long foe name and a long buff
  name (MagicBack, TakeMagic, ALLCHANGE) do not fit one line of 18 cells.
  When the stolen buff is a raised DEF or AGL and the user's own stat went up,
  one more page says by how much — **Next page when it steals a raised DEF / AGL**
  (one page of 2 lines; `{amount}` = how much the user's DEF / AGL rose, plus
  `{name}`, `{target}`, `{buff}`). The originals follow the game's own Upper /
  Speed lines: "{name}'s defense / goes up by {amount}!" and "{name}'s speed /
  goes up by {amount}!". Enemies get the same page. A user already at its cap
  gains nothing: then the page is left out. Stealing again and again climbs like
  casting Upper / Speed again and again and stops at the same cap; past it, a
  steal only strips the foe (its stat back to base) — an enemy thief does that too.
- **Repel** (field only, no numbers): cast from the field menu where monsters
  attack, it works like the Repellant — no random battles for the rest of the
  gate floor, or in a room until the party leaves it. It fizzles (no MP spent)
  where no battle can happen or while it is already on. In battle it does
  nothing.

The shares are fractions — type `1/3`, `2/5` or a whole number (top and bottom
up to 255; MP shares at most 1, damage shares at most 4 — 2 for Quake's own
side). Every result is rounded down and stops at 999. MagicBurn's and Anchor's
MP box is off: they spend MP by these shares instead. The percentages (LoneWolf,
Punish, Finish, Rupture) go from 0 to 2000 (×20); the label beside each box
shows the multiplier.

## New skills

**New skill…** adds a skill of your own (up to 16, ids 239-254; 234-238 belong
to the built-ins Plunder … Blunt since S155 — a project that had a new skill
there must re-make it). It runs the
effect of an original skill you pick — its **base** — and everything else is
its own: name, SKIL text, MP, power, targets, monster AI, behaviour, look,
sounds, element, announce line and learning. Only bases measured to behave
exactly like the original under a new id are offered (114 of 155 skills: all
the spells, breaths, slashes and family cuts and many status / support skills;
skills whose code checks its own number — Beat, Vacuum, the heals … — are not).
A new skill is learned by **evolving** from a skill the monster knows (Evolves
from), or given as a natural skill / enemy-row skill on the Monsters tab. New
skills are battle-only (the field menu knows the original skills only).
**Delete** removes a new skill (refused while a monster, an enemy row or
another skill's learning still uses it).

## Who has it

The monsters that learn it by themselves, the enemy rows that use it, and its
evolve chain — read-only (edit them on the Monsters tab).

## Limits

- Battle items (HERB, seeds, meats, staves …) are skills in the game's tables;
  they are shown read-only here and will be edited with the items (Items tab,
  not built yet).
- The custom skills' EFFECTS are their own code; a new skill reuses an
  original skill's effect. A new effect needs code (a session with Claude).
- The built-in custom skill names share bank $41 with the new monsters' names:
  since S155 (and Plunder, S156) about 19 new monsters with 8-letter names AND
  4-letter nicknames are a few letters too many (the Capacity tab / the build
  says so).
- New animations cannot be drawn; a skill can only borrow an existing look.
- Custom skills are never learned "by stats alone" (the S75 crash fence): they
  evolve from a known skill or are a natural skill.
