# Shops

The **Shops** tab holds every shop's list and every item's price.

**Shops:** the game's five — the **Bazaar item shop**, the **Starry Night
shop**, the **Bookstore**, the **Rare item shop** and the **gate-floor shop**
(the shop room inside gates) — and your own (**New shop…**, **Rename…**,
**Delete**). Pick one to see its list.

**A list** holds 1 to **20 items** (the game shows four per page; left /
right turns the page). **Add** puts the item picked in the box after the
selected row, **Remove**, **▲ / ▼** reorder. **Original list** puts a game
shop back the way it was.

**Who sells it:**

- the game's five sell where the game puts them (the tab says where: the
  game picks the list by the screen the shopkeeper stands on);
- **your shops** sell wherever you make an NPC a shopkeeper: Rooms tab →
  select the NPC → **Shopkeeper…** → pick the shop and, if you like, a
  greeting (empty = the game's "Item shop. May I help you?"). The NPC then
  opens the game's BUY / SELL menu with your list and says "Thank you. Come
  again!" at the end. A shopkeeper can sell a game shop's list too, and
  can speak its own **shop menu lines** ("What will you buy?", …): pick a
  line set in the same dialog (line sets: the *Services* tab).

**Prices** are per item — the same in every shop. Type a new **Buy price**
(0-65535 gold) in the table; orange = changed. **Shops pay** is what a shop
gives when the player sells: 3/4 of the price for most items, 1/10 for the
staffs, the full price in the gate-floor shop (the game's rule).

**Item sets by flag…** (S129): other lists a shop sells while flags / story
checks hold — e.g. "after chapter 2 the Bazaar sells the Shields". The first
set whose conditions all hold is sold; none = the shop's own list. Read each
time BUY opens. A set holds 1-20 items and up to 8 conditions.

Deleting a shop makes its shopkeepers stop selling (they no longer talk);
Undo brings it all back.
