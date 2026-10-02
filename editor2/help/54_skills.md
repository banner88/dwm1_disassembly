# Skills

The **Skills** tab edits the game's 222 original skills. Pick one on the left
(search by name or number; the list can show only skills, only battle actions
/ boss moves, or only battle items). **Bold** = changed from the original game.
Every field has a tooltip saying what the game does with it.
**Back to the original skill** puts every field back.

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
which skills share this skill's effect code.

## Targets

One foe / all foes / one ally / all allies / the user itself. The battle menu
asks for a target only for "one …"; an "all …" skill is applied to every monster
on that side. Moving a skill to the OTHER side (a heal aimed at foes) rarely
makes sense — its effect code was written for one side — so test it in battle.

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

**Looks and sounds like** plays another skill's animation, screen flash and
sounds. What the skill does — its effect, damage, targets and messages — stays
its own. Every original skill can lend its look: all 222 were measured lending
it to attacks, group attacks, heals, group heals, self-buffs and enemy casters
(1,554 battles) and none stalled. A look marked **(other side)** was made for a
skill aimed at the other side (a heal's look on an attack): it usually shows
nothing (measured: Heal with Bang's look draws no explosion). A look marked
**(summon)** only blinks the screen (a summon's "animation" is the summoned
monster). **Announced as** is the line the battle
shows when the skill is used; it is read-only until the dialogue editor.

## Who has it

The monsters that learn it by themselves, the enemy rows that use it, and its
evolve chain — read-only (edit them on the Monsters tab).

## Limits

- Battle items (HERB, seeds, meats, staves …) are skills in the game's tables;
  they are shown read-only here and will be edited with the items (Items tab,
  not built yet).
- The custom skills (MagicBurn, Tame, Anchor, Tremor / Quake, Mourn) are not
  editable yet (ROADMAP P3.11c).
- New animations cannot be drawn; a skill can only borrow an existing look.
