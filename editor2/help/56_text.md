# Text

The **Text** tab (S150) holds every text the game can show — and every one
can be **rewritten, any length**. One sub-tab per kind:

- **Dialogue** — the 2,560 text ids: everything people (and monsters) say,
  story scenes, signs, system questions;
- **Battle** — the battle messages;
- **Items** — item names, descriptions and the 48 item use lines (the Items
  tab edits the same names and descriptions, plus everything else of an item);
- **Menus & field** — menu words, field messages, spell messages;
- **Credits** (once your project has its own credits pages — Cutscenes →
  Title & ending… — their words are edited there; "TO BE CONTINUED" stays here);
- **Window words** (S165 / S166) — the words of the menus' windows that are
  pictures, not texts, and the words a window cuts out of a text (below);
- **Other tabs** — the monster and skill descriptions (read only here: the
  Monsters and Skills tabs own them).

Each page: search by words (across line breaks), by an id (`$0123`) or a row
(`#12`); narrow by kind; **Edited only** (✎); **Save as text file…**. On the
Dialogue page, **Names a monster** lists every text that spells a monster's
name, under its old and its new name (the Monsters tab's **Texts that name
it…** opens it).

**Editing:** pick a line; the field below shows it as text: a new line = the
next line of the box (or the next row of a table), `▼` = the box break,
`{…}` = the game's codes (a name inserted, a pause, a sound). The picture
beside it is the line in the game's own font — cells past the box are red.
**Apply** (Ctrl+Return) stores it, one undo step; **Original** puts the game's
back. **with its copies** (ticked): every id that showed the same words gets
the edit too.

Limits: item names and personalities at most 9 letters, the families'
default names at most 4 (the game draws them in fixed fields); anything else
any length (an edited text sits in a bank of its own). The Capacity tab
counts the edited texts.

## Window words (S165, S166)

Some words on screen are not texts at all: the field menu's **INFO ITEM /
SKIL OPTN**, the stats page's **ATK DEF AGL INT WLD**, **HP: / MP:**,
**MASTER:**, **NEXT LV**, the ITEM window's **USE / DEL**, SKIL's **USE MP**,
OPTN's **TEXT SPD / CH ORDER / CH PLAN / JOURNAL**, the tactics **CHARGE /
MIXED / CAUTIOUS / COMMAND**, the save box's **YES / NO**, and the title
menu's **CONTINUE / NEW GAME / VS MODE / BREEDING**. Each letter is a small
picture (a tile) the screen keeps loaded, so the **Window words** page edits
them with two limits:

- **the same length at most** — a shorter word is filled with blank cells (the
  window's frame never moves; the blank before each menu entry is where the
  cursor arrow sits, so a word never grows into it);
- **only the letters that screen has** — the field menus keep **A-Y without Q
  (no Z), capitals only, and the digits**; the title menu has the whole font
  (upper and lower case). The last column lists them; a word with another letter
  is refused with that letter named.

Double-click **Your word** to type; empty (or **Original**) = the game's word.
A word that sits in several windows is one row per window — the field menu's
INFO and the INFO list's header are two rows (change both to keep them
alike). Measured in the game: the new word shows in the window, nothing else
moves.

**The other screens (S166).** The page also lists the windows of the **shop**
(BUY / SELL / EXIT, YES / NO), the **farm** (DROP OFF … SLEEP / EXIT, WHO,
INFO / OK), the **Monster Namer**, **Grandpa** (BREED / HATCH, WHO, INFO / OK),
the **egg appraiser** (EVAL / BLESS / EXIT, INFO / OK), the **egg page** (DAD: /
MOM: / MASTER:) and the **battle** (FIGHT / ITEM / PLAN / RUN, the tactics,
ATK / SKIL / DEF). Each screen loads its own small set of letters — the shop has
no A or C, the battle menu no B or O — so the last column differs per window;
pick a word from those letters. Use the **Window** list to see one screen.

**Words cut out of a text (S166).** A few windows show a TEXT the game draws
into the window and cuts at fixed places: the Vault's **PUT / TAKE / EXIT**
(the text `PUT TAKEEXIT`, four cells a word), its **ITEM / GOLD / EXIT**
(`ITEMGOLDEXIT`), Grandpa's **EXIT** (`EXIT INFO`). Their rows say *any letter
— a word of the text …, cells …*: any letter of the font (capitals, small
letters, digits), at most the word's cells; the editor rewrites the text row
for you (Text → Menus & field shows it, e.g. `STOWGET EXIT`). Editing such a row
by hand on Menus & field warns when a word no longer sits in its cells.

Not editable: the naming keyboard (its cells ARE the letters you type), the
egg page's pedigree picture, the battle's join question and the full-party
windows (their letters are moved around by a part of the game not decoded
yet), the link-cable screens (VS MODE / BREEDING: no second Game Boy to reach
them), and windows no tour has opened.

**Line widths (S166).** On the other Text pages a line longer than the window
it is drawn in gets a warning — battle messages, level-up and spell lines,
item descriptions and use lines (18 cells), item names and personalities (9),
the credits (roles 20, names 11). A name the game fills in ({ins 00} …)
counts 9 cells; a line no longer than the game's own never warns.

