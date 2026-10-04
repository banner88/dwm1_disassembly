# Dialogue

The **Dialogue** tab lists every text the game can show, read from the ROM:

- the **2,560 text ids** — everything people (and monsters) say, story
  scenes, signs, system questions. Each line shows its id ($0000 …) and
  where it lives (bank:address). Many ids show the same text; the copies are
  listed once ("also shown as …" names the others).
- the **text tables**: battle messages, field / item / spell messages, item
  and skill descriptions, the monster descriptions of the library.

Search by words, by a text id (`$0123`) or by an address (`$42:$4142`); narrow
the list by kind; or pick a monster under **Names a monster** to list every
text that spells its name — "Slime", "Slimes", "Slime's", under its original
name and its new one if you renamed it (the Monsters tab's **Texts that name
it…** opens this). Names are matched exactly as written (capitals count), so
the plain word "slime" is not counted as the monster.

S120: the texts are shown with the game's one-cell contractions (`D'ya`,
`I'd`, `it's` …) — before S120 some were mis-read as letter pairs ("Dn'a").

**Save as text file…** writes the current list (one block per text) for
reading or searching elsewhere.

Read-only for now: editing the game's own dialogue comes with the dialogue
editor. A renamed monster's name changes everywhere the game prints it from
its name table — not inside these texts.
