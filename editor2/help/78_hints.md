# Breeding hints: monuments and archives

When you scramble the breeding table, the player needs clues. **Breeding hints** give
them clues inside the game:

- A **monument** stands in one of your rooms, usually a room served on gate floors.
  Reading it **teaches one breeding cross** the player has not found yet, for example
  *"Grizzly with Skullgon makes GulpBeast!"*. It can also say the cross as a **riddle**.
- An **archive** holds one family. It lists the crosses of that family the player has
  learned so far, with **"(bred)"** on the ones they have made.
- **Breeding** exactly a hint's cross also teaches it, and marks it bred.

Each hint is **one exact cross**: one row of the special breeding table, such as
Grizzly × Skullgon → GulpBeast. If a monster can be made by 70 crosses, each cross is a
separate hint. You choose which crosses are hints, so a hint can show one piece of the
puzzle and leave the rest for the player to find by breeding.

The example built while writing this page uses the user's project +
`examples/s158_hints_demo/build_demo.py`:

> In Cities_FOUNT the HINT GUIDE sends you to THE STONE GARDEN, which has three pillars.
> The left pillar teaches any family. The middle one teaches the Slime family in riddles.
> The right one teaches the Dragon family: a few words, then the riddle, then the cross.
> The BREEDER's MadCat with a Healer makes a FangSlime, which is one of the hints. The
> EXIT GUIDE goes to THE GREAT ARCHIVE, which has eleven bookcases, one per family.
> THE RUNE CRYPT on gate 2's floor 2 has one more pillar.

**Order of work:** 1 the pool → 2 monuments → 3 archives → 4 the words → 5 riddles →
6 build and test.

## 1. The hint pool (Breeding tab → Hints)

The **Hints** page lists every special recipe that can be a hint. A recipe can be a hint
only if it really decides an egg for some parents. A recipe that another recipe always
beats would be a lie, so it is left out.

**Family recipes are never hints.** Each monster's library page already shows its
family recipe, so the player can read it there.

- **Blacklist** (the default): every recipe is a hint unless you **untick** it.
  This suits development, while the table is still changing.
- **Whitelist**: only the recipes you **tick** are hints. This suits the finished game:
  pick a few crosses per family.

Both lists are kept, so switching modes loses nothing.

The page has these controls:

- **Family**, **Find a monster** and **In the pool / Not in the pool** filter the list.
- **Put the shown in the pool** and **Take the shown out** tick or untick everything
  the filters show.
- **Riddle…** (or double-click) gives the selected cross a riddle.
- **Words…** sets what every monument and archive says.
- **Family words…** sets how a family parent reads (by default *"any Dragon"*, at most
  12 letters) and the **(bred)** mark.
- **Renumber…** is described below.

**The pool follows your breeding table.** Each time you build, the hints are worked out
from the table as it stands. If you change or remove a recipe, its hint changes or goes
with it. A cross you ticked that is no longer in the table shows as **gone** (grey).
If the cross comes back, so does its hint.

**Numbers.** Each hint has a **number**, which is its place in the save. The editor
writes the numbers into the project and keeps them. Taking a hint out of the pool keeps
its number, so a save made earlier still knows what the player learned.
**Renumber…** starts the numbers from 0 again. Use it once, before release: a save made
with the old numbers would mix up what the player learned.

## 2. A monument (Rooms tab, + Monument (O))

1. Draw the monument's art on a cell: a stone, a pillar, a tablet. The editor does not
   draw anything for you.
2. Select the cell (the Select tool, **V**) and press **+ Monument (O)**.
3. The monument is an **examine spot**: the player presses A while facing it. Its marker
   on the canvas is **Mo**.

The panel sets:

- **teaches**: *every family*, or only the families you tick. A family here means the
  family of the monster the cross **makes**.
- **skip children the player has owned**: on by default. The monument does not teach a
  cross whose child the player has ever had. This uses the library's record: a monster
  that joined, was given or was bred. Turn it off when you want a monument to show
  several crosses for the same monster.
- **shows**:
  - *the cross*: the names.
  - *the riddle (else the cross)*: the cross's riddle, or the names when the cross has
    no riddle.
  - *the riddle, then the cross*: both. A cross without a riddle shows only the names,
    once.
- **Its words…**: words of its own (see section 4).
- **in states**: on which room states it stands.

**In the game:**

- A monument picks at random among the hints it can teach that the player has **not
  learned yet**, and teaches it at once.
- Reading it again during the **same visit** repeats the same hint.
- The **next visit** (leaving and coming back, another floor, another dive) teaches
  another.
- When nothing is left to teach, it says its **worn-away** words: *"The words on this
  stone have worn away…"*.
- A room holds up to **8** monuments.

**In a gate:** put the room on gate floors (Rooms tab, *Inside gates* / Gates tab). Each
floor the room appears on is a new visit.

## 3. An archive (Rooms tab, + Archive (K))

1. Draw the archive's art: a bookcase with the family's emblem.
2. Select the cell and press **+ Archive (K)**. The editor asks for the family.
3. The marker shows in the **family's colour** with its letters, for example **ASl**,
   **ADr**, **ABe**. Change the family in the panel.

**In the game**, the archive works like this:

1. It asks *"The archive of the Slime family. Would you like to read it?"*
2. On YES, it shows the family's learned crosses one box at a time, with **(bred)** on
   the ones made, and asks **"Keep reading?"** after each. After the last one it says
   *"That is all the archive holds."*
3. If the player has learned nothing of that family, it says *"It seems you have not
   found any clues yet…"*.

The order is by the monster each cross makes, then by the table. Several archives may
show the same family.

## 4. The words

Every text is game text: edit it box by box beside the game's own picture of the box.
These inserts work only in hint words:

| insert | shows |
|---|---|
| `{parent1}` | the pedigree: a monster's name, or a family's words such as "any Slime" (12 letters at most) |
| `{parent2}` | the mate, the same way |
| `{child}` | the monster it makes, with " +5" when the cross needs a plus |
| `{bred}` | "(bred)" once the player has made this cross, else the not-bred words (empty) |
| `{family}` | the archive's family name (archive words only) |

The editor counts every insert at its longest, so a line that fits in the editor fits in
the game.

**Words…** on the Hints page sets the words of every monument and archive:

- the monument's cross
- its worn-away words
- the archive's question
- the archive's nothing-yet words
- one entry
- *Keep reading?*
- the end words
- an optional line on NO

A monument or archive can also have **its own** words (its panel, **Its words…**):

- A monument can say words **before** and **after** the cross.

### Fixing the grammar of the default words

The default words are plain placeholders. An archive entry reads, for example:

> any Slime / and MadCat / make FangSlime / (bred)

It has no full stop, and it starts with a small letter. Rewrite the words before you
release your game. Every text is in the editor:

| what to fix | where |
|---|---|
| one archive entry | Breeding tab → Hints → **Words…** → *one entry* |
| the archive's question, nothing-yet words, *Keep reading?*, end words | the same dialog |
| the monument's cross | the same dialog → *the monument's cross* |
| how a family parent reads (*"any Slime"*) and the **(bred)** mark | Hints → **Family words…** |
| one bookcase or one monument only | Rooms tab → select it → **Its words…** |

**Why "any Slime" starts with a small letter:** one family's words are used everywhere
that family is a parent, at the start of a sentence and in the middle of one. Changing
it to *"Any Slime"* would put a capital letter mid-sentence too. Instead, write the
entry so `{parent1}` and `{parent2}` never start a sentence. For example:

| text | lines |
|---|---|
| one entry | `Breed {parent1}` / `with {parent2}` / `for {child}.` / `{bred}` |
| the monument's cross | `Breed {parent1}` / `with {parent2}` / `and {child}` / `is born!` |
| the archive's question | `The {family}` / `family's archive.` / `Would you like to` / `read it?` |

Each line holds **18 letters**. The editor counts every insert at its longest:

- `{parent1}` and `{parent2}`: 12 letters.
- `{child}`: 13 letters, including " +N" when the cross needs a plus.
- `{bred}`: 15 letters.
- `{family}`: "Material", the longest family name.

So `Breed {parent1}` (6 + 12) fits exactly, and the editor refuses a line that could
run over. Finish each sentence with a full stop, "!" or "?". The game prints exactly what
you write. Look at the box's picture beside each line to check it before you build.

## 5. Riddles

Select a cross on the Hints page and press **Riddle…**. A riddle is a few boxes of text:

> A cat gone mad and a slime beside it: a fanged one is born of both.

A monument set to show riddles says the riddle instead of the names. The archive always
shows the real cross. A riddle may use the inserts too, for example `{child}`.

## 6. Build and test

What the player has learned is written into the save **at once**, not at the next save.
Knowledge stays after a reset: a cross read at a monument is still known even if the
player resets without saving. **NEW GAME** forgets everything.

To test, walk to a monument, read it, read it again (the same hint), leave and come back
(a new one). Then open the archive. Breed the cross a hint names and check the archive
shows **(bred)**.

## In project.json

```jsonc
"hints": {"mode": "whitelist",                       // or "blacklist" (default)
          "include": ["Slimex68+0>10"], "exclude": [],
          "numbers": {"Slimex68+0>10": 2},           // the editor keeps these
          "riddles": {"Slimex68+0>10": [["A cat gone mad", "…"]]},
          "family_words": {"Dragon": "a dragon"}, "bred_word": "(bred)",
          "words": {"archive_more": [["Read on?"]]}},
"rooms": [{"monuments": [{"id": "monument_1", "families": ["Slime"], "show": "riddle",
                          "skip_owned": false, "intro": [["An old stone."]]}],
           "archives": [{"id": "archive_1", "family": "Dragon"}], …}]
// a cell: {"kind": "monument", "x": 2, "y": 2, "monument": "monument_1"}
```

A key reads *pedigree* x *mate* + *min plus* > *child*. A matcher is a monster number or
a family name: `"Slimex68+0>10"` = any Slime × MadCat (68) → FangSlime (10).
