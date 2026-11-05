# Raising monsters: joining, levels, skills, babies

How the game makes and grows the player's monsters — when one joins, at every level
up, when it learns a skill, when two are bred and when the egg hatches. The editor
has an exact copy of these rules (checked against the game's own code: thousands of
joins, level-ups, breeds and hatches, not one difference). The **Balance** tab uses
it to know how long raising a team takes; the Breeding tab's **Try a cross** page
uses it to show the baby (see *Breeding* → [Try a cross: the baby](58_breeding.md#Try%20a%20cross:%20the%20baby)).

## When a monster joins

A monster that joins (beaten in battle, a boss that joins, a gift from a script) is
made from the **battle row** it was fought as (Monsters tab → its rows):

- **HP, MP, ATK, DEF, INT** get one random roll: 80 – 100 % of the row's value.
  **AGL is never rolled** — it is exactly the row's.
- It **knows the row's skills** (up to 4).
- Its **learn queue** (the skills it can still pick up) = its kind's 3 natural
  skills, minus the chain of any it already knows.
- Its **max level** = its kind's level cap, + or − up to 2 at random.
- Its four **AI weights** (Damage / Heal-support / Status / Obedience) are the row's,
  each rolled the same 80 – 100 %.

## Levelling up

At each level up the game, in this order:

1. works out the **stat gains** from each stat's growth curve at the OLD level
   (Monsters tab → growth). From **level 14**, a monster **with a plus** gets up to
   four extra random bonuses to **HP and ATK** — the higher the plus, the more often;
2. runs the **learn check** (next section) with the stats from **before** the gains
   against the NEW level — so a skill whose stat need is just reached arrives one
   level later than you might expect;
3. if it now knows more than 8 skills, asks the player which to **forget**;
4. adds the gains (caps: HP / MP / ATK / DEF 999, AGL 511, INT 255).

At or past its **max level** a monster gets no more exp from battles — and if one big
win carries it past the max anyway, each extra level **takes stats away** instead.
**Monsters on the farm never learn skills.**

## Learning a skill

Every skill has needs: a level and six minimum stats (Skills tab → learning). When
they are all met, the monster learns it in one of three ways:

- **From the learn queue** — a skill with no "evolves from" is learned ONLY this way:
  it must be in the monster's queue.
- **An upgrade** — a skill that evolves from one skill the monster knows replaces it
  (Heal → HealMore → HealAll).
- **A combination** — a skill that needs 2-5 skills, all known, is learned beside them
  (Hustle, GigaSlash …).

## Breeding: the egg

The egg's kind and plus come from the recipes (see *Breeding*). Then:

- **Level 1**, **max level** = its kind's cap + 2 × plus (at most 99) — the plus is
  what lets a bred monster outgrow its kind.
- **Each stat** = (pedigree's + mate's) ÷ 4, then **+ 2 % for every pedigree name that
  is not the player's** — each parent's master, and the two parents of a parent that
  was itself bred (the game keeps their NICKNAMES there, so a bred parent usually
  counts 2): a second-generation baby is about 4 – 8 % stronger.
- **AI weights** = the parents' average — with a bug in the original code: the sum
  loses its carry, so when the two add up past 255 the baby gets (sum − 256) ÷ 2 (two
  200s give 72, not 200). The Try a cross page marks it.
- **Resistances** = its kind's own; each can come out one level higher at random — the
  plus and the parents' own levels for it decide the chance.
- **Gender** — rolled from its kind's male / female share.
- It **knows nothing**. Instead it gets a **learn queue** of up to **25** skills, in
  this order: its own kind's 3 natural skills, the pedigree's kind's 3, the mate's
  kind's 3, then every skill the pedigree knew, then every skill the mate knew. Each
  is turned back into the FIRST skill of its chain (HealAll → Heal: the baby re-learns
  the chain as it grows); a skill already in the queue is not added twice; some skills
  are never passed on; past 25, the rest is lost.

## The egg hatches

At the hatch the game makes the player its master and re-orders the queue — its own
3, the FATHER's kind's 3, the mother's, then the rest — the same skills. (The code has
a "keep each skill by the plus" roll here that the developers switched off: it only
moves the random numbers.) From then on the baby learns its queue as any monster does:
when its level and stats are high enough. That is how a weak-looking baby can carry its
parents' best skills and grow into them.

## In the editor

- **Breeding → Try a cross** — the baby of two parents (typical ones or from your
  save): its stats, max level, AI, resistances, learn queue and the level it learns
  each skill.
- **Balance** — the teams it rolls are joined, bred and raised with these rules.
- **Skills** — each skill's needs (level, stats) and what it evolves from: what
  decides WHEN a monster learns it.
- **Monsters** — the level cap, growth curves, natural skills and battle rows that
  everything above starts from.
