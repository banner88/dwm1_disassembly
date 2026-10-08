# Balance

The **Balance** tab answers one question for every key fight of the story:
*how strong does a player's team have to be to win it?* — for the original
game and for your project, side by side, so you can see whether your gates,
bosses and arena teams land "in the same general area" as the original.

*Built in S130, not yet tested by a user: tell us what reads wrong.*

## Reading the numbers

The tab opens in a **simple view**: one number per fight.

- **The number** is the team level a *well-built* team needs to win 9
  battles out of 10 — the best 3 monsters and 8 skills you could have at that
  point in the story, ordered every turn (in the arena, where you cannot give
  orders, on its best tactic). "Lv 32" = such a team at level 32 wins 9 of 10.
  **Lower = easier.** Hover a number for one sentence about it.
- **Can't win (38 %)** = not even that team at level 99 wins 9 of 10; the
  percentage is how often it *does* win at 99.
- **Colours**: green = easy, through yellow and orange, to red = hard;
  purple = can't win even at level 99 (deeper purple = further from it). The
  strip above the table is the key.
- **Original game / Your project / Change**: your project's number next to
  the original game's for the same point of the story. **Change** says it in
  words: *much harder (+12)*, *harder (+5)*, *about the same*, *easier (−4)*,
  *much easier (−10)* — how many levels more (or fewer) your project asks.
  A step's own row shows its hardest fight.
- **Compute your project** works your numbers out (minutes per story step
  the first time; anything unchanged is remembered). **Show the team** shows
  the best team behind the number for the selected step or fight.

**Show details** (top right) adds everything else: the casual and strong
players, the 50 % level, gate dives, the unmodelled share, notes, the profile
choices and the breeding setting. The rest of this topic explains them.

## The number

For each fight the tab shows the **team level** at which teams a player
might have at that point of the story win:

- **l90** — 90 % of their battles (the main number),
- **l50** — half of their battles (a coin flip).

Lower = easier. The numbers come from the battle simulator (the same one
the Encounters tab uses), many battles per level. The level is searched from
**below** (1, 2, 4, 8 … up to the first level that wins, then narrowed
down), so the number is the first level that is enough — a win rate that
dips again at very high levels does not hide it.

**99+ (17 %)** means not even a team at level 99 wins that often; the
percentage is how often level-99 teams *do* win (for a dive: how many dives
clear). Hover it for more: **enemies left with N % HP** — how much of the
enemies' HP is left when a battle ends, on average. So two "99+" fights are
not the same: one won 80 % of the time at 99 is nearly there, one won 0 %
with the enemies at 90 % HP is far beyond.

**Postgame "99+"** mostly means *beyond a rolled team*, not impossible: the
postgame wants monsters bred over many generations, deeper than the model
rolls (strong teams breed up to 2 generations, 3 in the postgame; casual
teams breed once). Compare such fights by their reading at 99.

## Three kinds of player (profiles)

- **player** — **the main number** (the first, bold columns): how *you*
  play. One general **skill kit** per story step — the 3 monsters and up to
  8 skills each that a skilled player would bring there — found by search,
  the way a player experiments until they get past the wall: start from good
  rolled teams, swap a monster or a skill, keep what wins more against the
  step's hardest fights. Only skills the members can really have learned at
  the level count, and only monsters the player could have by then (joined,
  or bred once breeding is open). The kit is raised to each team level and
  fights under **your orders**: every turn the battle menu's Command, chosen
  one action ahead by a planner. In the **arena** the menu has no Command
  ("NO SP SK"), so the kit tries Charge, Mixed, Cautious and NO SP SK and
  keeps the best — the Notes and the kit view name that tactic. Bred members
  always obey (WLD 0); joined ones may refuse an order, as in the game.
  Status locks such as Sleep on a boss are used when the boss's resistances
  allow them — as the game does.
- **casual** — a team made of what was at hand: monsters that could join on
  the way, kept as they come (their first skills).
- **strong** — the best of several tries per member, bred for skills once
  breeding is open (up to 2 generations of crosses, 3 in the postgame), the
  best 8 skills kept; members are rated by their offence and at most one
  heal, so a strong team is not three healers.

Casual and strong fight on their own AI tactics. A fight that needs much
more for casual than for strong (or player) is one that rewards preparation.
Hide their columns with **show casual / strong**; **Change compares** picks
the profile the Change column compares (player by default), **Chart** the
one the chart draws.

## The team model

Rolled teams follow how the game raises monsters (creation, breeding, birth,
level-ups and skill learning are the game's own rules, checked against the
game):

- **Who can be in a team** at a story step: the starter, every monster that
  can join from the wild lists met so far, the bosses of the gates already
  cleared that join, and — once breeding is open — their offspring.
- **The same exp for every member.** Battle exp is shared evenly, so every
  member has the same exp; the *team level* is the level that exp gives on
  the exp curve most monsters use. Monsters on a slower curve are a few
  levels behind, faster ones ahead.
- **Members stuck at their level cap** below 85 % of the team level are
  swapped for another, as a player replaces a monster that stopped growing.
  The *Notes* column says when members still reach clearly less than the
  team level (caps).
- **Breeding** opens after the F class in the original game. For your
  project choose **Breeding opens after** above the table (a story step);
  it is saved in the project (one undo step, meta.balance) and only this tab
  reads it — the game is not changed.

## Story curve

One block per story step in the original order: every gate (its floors in
runs that use the same list, its boss fight or fights), every arena class,
Starry Night, Monster Grandpa's match. Postgame steps are marked, and a green
line shows where breeding opens. A step's own row shows its hardest fight.

Columns: the original game's casual l90 / l50 and strong l90, your project's
same three, **Change** (your project minus the original, coloured *much
harder / harder / similar / easier* — the band grows with the level: three
levels matter at L5, not at L60), **Unmodelled** and **Notes**. Hover a
number for the win rate, rounds, HP left and the level members really
reached.

**Level colours.** Every level cell (original and project, step rows, dive
rows, and the Fight page's level results) is coloured by its band, cool to
warm: 1-10 green, 11-20, 21-30, 31-40 yellow, 41-50, 51-60 orange, 61-75,
76-98 red; **99+** is purple, deeper the more battles level-99 teams still
lose. The strip above the table is the key. The **Change** column keeps its
own colours (much harder / harder / similar / easier).

Your project keeps the story's positions: gate *n* is still the *n*-th gate
of the story, the G class still follows the first gate — each position shows
*your* content there. A fight only one side has is shown with "—" on the
other.

**Dives.** Under each gate two rows: the gate's maze floors in a row
*without healing* (HP and MP carry over), then the boss — the team level at
which 90 % of dives get through. **direct** walks straight to the stairs (the
fewest battles: a lower bound), **sweep** walks every floor whole (the most
battles: an upper bound). A real player lands between.

**Outside the story** (your project only): new gates (32 and up) and rooms
with their own battles have no place in the original story, so they get a
number of their own and *lands like* — the original fights with the closest
number.

**Computing.** Your project's numbers are computed only when you ask:
**Compute player**, **Compute casual**, **Compute strong** (every fight) or
**Compute selected** (the selected rows; a step row = all its fights; player,
and casual / strong when shown). For player each step's kit is searched
first — minutes per step ("optimising kit for …" in the progress bar), then
cached like the fights. Casual takes a few seconds per fight, strong about
40 s, a dive longer; everything runs in
the background with a progress bar and **Cancel**, and the rows fill in as
results come. Results are cached per fight in the project's build folder
(build/balance_cache.json): a fight is only computed again when something it
depends on changes (its enemies, their skills, the monsters you can have by
then, growth, exp curves, learning, breeding). So after changing one boss,
**Compute casual** again takes seconds.

**The kit view** (right of the table): select a step or a fight to see the
step's kit — original game and your project (once computed): each monster,
how it is had (joins / bred from which two), plus, the level it reaches,
its skills, the team level the kit was optimised at, what the planner used
it for, and for an arena match the tactic it fights on. **Use this kit as
the current team** puts it, raised to the selected fight's player l90 (else
the kit's own level), on the Team page — the Fight page fights with it.

The chart under the table: each step's hardest fight (the player curve by
default), original (dashed)
against your project (solid). Above the 99 line (the reddish band) are the
fights not won even at 99, placed by *how far*: higher = fewer wins at 99
and more enemy HP left (hollow squares). When both sides are beyond 99, the
**Change** column compares their win rates at 99 instead (e.g. "-20 % at
99" = your project's level-99 teams win 20 % less often).

## Team

Roll a team as a player might have it: **Data** (original game or your
project), **Profile**, **Story step**, **Team level** and **Team #** — teams
0-11 are exactly the teams the numbers use; **Reroll** shows the next one.
Profile **player** gives the step's kit at that team level (searched first
when it is not known yet).
Each member: nickname, monster, level / cap, the six stats, plus, skills and
where it came from (joined from which enemy row, bred from which two).

- **Import party from .sav…** — the party of a battery save of the game or
  of a build of your project (nicknames, levels, stats and skills as saved).
- **Pick member…** — any monster at a level, with its plus; the skills start
  as the ones the game teaches it by then, change any of them. It replaces
  the selected member (or joins a team of fewer than three).
- **Remove member.**

## Fight

Pick any fight (story or outside it, original game or your project). The
table lists its battles (a wild list: each group of monsters with its
chance) and every enemy's level, stats and skills.

- **Evaluate current team** — the Team page's team, at its own levels,
  fights it many times: win %, rounds, HP left (of the team's total),
  **enemy HP left** (of the enemies' total), the unmodelled share and **How
  it fought**: *under your orders* (Command every turn; in the arena the best
  of the four tactics, named) or *on its own AI tactics* (the choice next to
  the button).
- **Level needed (rolled teams)** — l90 / l50 for the chosen profile (known
  numbers come from the precomputed or cached results at once); the rates
  shown are those at the level found, or at 99 when even 99 falls short. For
  **player** the step's kit is used; with a what-if the *same* kit fights the
  changed enemy — you see what your change does to the player's best plan.

**Enemy HP left** is the best reading for a boss the team cannot beat: a
what-if that leaves it at 30 % instead of 80 % HP matters even when both
sides win 0 %.

**What-if**: change an enemy's level, stats or four skills and **Apply
what-if** — every run then shows *As is* and *What-if* side by side with the
change, so you see how much a boss's new skillset matters without playing it
fifty times. Changed values are orange in the enemy table. An enemy row's
stats are its own numbers, not made from its level: a new level alone changes
little — change HP, ATK and the others too. **Reset this
enemy** / **Reset what-if** go back. A what-if lives only in the simulator:
it is never saved, never changes the project, the story numbers or the cache.
To keep a change, make it on the Monsters or Arena tab.

## What "unmodelled" means

A few skills do things the simulator does not model (some special effects);
in the simulation they simply do nothing. **Unmodelled** is the share of all
actions at l90 that were such skills (the column shows the highest of the
profiles; hover it for each). Up to a few percent changes little;
20 % or more (orange) means the number leans on skills the simulator cannot
judge — try that fight in the game.

## The original game's numbers

They are computed once, from the original game data, by
tools/build_balance_anchor.py into extracted/balance_vanilla.json, and shown
read-only. When the file is missing the tab says so and the original columns
stay empty; your project can still be computed. When the simulator changes,
the tab warns that the original numbers must be rebuilt to stay comparable.

**Build original-game numbers** (shown while they are missing or out of
date) runs that build on your computer with every CPU core. The player
profile makes it long — an hour or more, depending on your cores. Every
finished part is saved as it finishes (balance_vanilla.json.partial), so
**Stop**, closing the editor or a crash loses nothing: press the button again
and it continues from there. When it finishes, the original columns fill in.

## Limits

- A fight's number is a model, not the game: the AI, the walk and the team a
  real player has differ. Compare your project with the original (the same
  model on both sides), not with absolute expectations.
- Every member of a rolled team has the same exp; real players level a
  favourite faster.
- Items, healing between battles of a floor and running away are not used.
- **player**: the planner looks one action ahead (a real player plans
  further); the kit search is small (a few dozen tries per step), so a better
  kit may exist — a project fight that looks easy for the found kit is not
  proof that no stronger kit breaks it, and one that looks hard may have an
  answer the search missed. One kit serves the whole step, as a player does
  not rebuild the team for every floor.
