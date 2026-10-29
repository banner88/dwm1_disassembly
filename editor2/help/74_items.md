# Items

The **Items** tab (S151) holds every item: the game's 43 (Herb … BookMark),
then your own. Orange = a game item you changed; green = yours.

**Words:** the **Name** (at most 9 letters — the bag and the shops draw it in
a fixed column) and the **Description** (the bag's INFO box: two lines of up
to 18 letters; **Apply** stores it). A game item's words are the same ones
the Text tab's *Items* page edits.

**What it does:** every item runs one of the game's 43 item codes. A game
item runs its own; **your item WORKS LIKE** one of them (pick it in **Works
like**) — a MegaHerb that works like the Herb heals, a HeroSeed that works
like the ATKseed raises ATK, a Feather that works like the WarpWing leaves
the gate. The blue line says what that code does with the item's **Power**:

- heal items: power + 0-10 HP (the SageStone: the whole party);
- the seeds: + power to the stat (up to 999; AGL 511, INT 255);
- the meats: the monster's wildness drops by the power;
- the others (cures, revive, books, staffs, the gate tools) ignore the power.

**Used up** is the chance that one use uses the item up: 100 % = always (the
game's usual), 0 % = never — a permanent item (e.g. a WarpWing that is never
used up), 50 % = one time in two ("The Feather falls apart!" when it breaks).

**Permanent = ONE-ONLY.** An item that is used up 0 % (the game's BeastTail
and ShinyHarp, and any item you set to 0 %) can be held only ONCE — the bag
and the Vault together:

- a shop does not list it while the player holds one, and sells one at a time
  (the "how many?" window stops at 1);
- a give of it when one is held gives nothing and shows the **"already has"
  line** instead of the "bag full" words — in the game's own scripts too (the
  Stable dresser keeps its WarpWing for later). Edit that line in the
  **One-only items** box at the bottom: `{ins 00}` = the item's name, `{hero}`
  = the hero. A Give of 2 or more of a one-only item gives just one (the build
  warns);
- it never lies on a random gate floor, in a treasure chest of the random
  gates, in the rare chest or as a gate Coliseum prize — its share goes to the
  other items of the same table (the panel lists where it was);
- it is always **kept when the party loses a battle** (that box is ticked and
  locked).

Your own hand-made rooms and worlds give what you put there.

**Can be used from the field menu** — off makes a key item: "… uses the
OldKey as a tool. But nothing happens." **Asks which monster** — the WHO box
before the effect (off for items that act on the whole party or nobody).

**Shops and battles lost:** the **Price** (the same in every shop — the
Shops tab edits it too); **Shops pay** follows the game's rule from what the
item works like (3/4, a staff 1/10, the gate-floor shop the full price);
**Shops buy it** puts it on the SELL list; **Kept when the party loses a
battle** — most items are lost then; kept ones stay in the bag.

**Lines:** the **Use line** ("Wrex uses 1 Herb on Slime.") and the **Result
line** ("Slime's wound heals.") are picked from the game's 48 item lines
(edit those words on the Text tab, Items page). Your items can have a line of
their **own**: type it and press **Set** — `{ins 00}` is the hero's name,
`{ins 10}` the monster's, `{ins 20}` the item's; `\n` starts the next line of
the box. Empty + Set = back to a game line.

**In battle:** the game's items 1-37 have a battle half — the item's battle
skill (item skills 176-212; the Skills tab shows them too): **Battle power**
plus a random extra up to **+ random up to**, and **Can be used in battle**.
Your items do in battle what the item they work like does, with its battle
power; the battle text names YOUR item. Items 38-43 (BeastTail … BookMark)
do nothing in battle.

**Field-only for good (S160):** LifeAcorn, MysticNut, the four seeds (13-18),
WarpWing, TinyMedal and the six books (29-36) never worked in battle in the
game ("Can't use this item in battle!"); since S160 their battle-skill ids hold
your new skills (Skills tab), so they have no battle half to edit and stay
field-only — and so does every item of yours that works like one of them. Their
field use is unchanged (a LifeAcorn still raises max HP).

**New item…** asks what it works like and its name and starts with every
field of that item. **Copy** makes a new item with every field of the
selected one. **Delete** (your items; a shop / give / story check that still
uses it stops the build until you change it). **Original** puts a game item
back the way the game has it. You can have **84** items of your own (ids
44-127). Sell them in a shop (Shops tab), give them in a conversation or
cutscene, ask for them in a story check or a quest.

Special cases: the Medal Man counts only the game's TinyMedal, and the gate
map's compass is the game's BeastTail's only — an item working like those
works in the bag, without those extras. The gate-floor chests give the
game's items only (never a one-only one).
