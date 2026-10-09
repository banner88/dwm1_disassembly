# Build and test

**Build & Play** → *Build ROM* (Ctrl+B; saves first) or *Validate project*
(checks without building). *Play in emulator* (Ctrl+R) runs the last build.

The ROM you get is **4 MB** (S134) — twice the original game, so there is room
for a large romhack. Every modern Game Boy Color emulator plays it; on a real
Game Boy it needs a flash cartridge that takes 4 MB ROMs. Your battery save
(`.sav`) is not affected by the size.

**Space for art (S135):** screen layouts, their colour grids and your tilesets
first fill their own banks ($64 for layouts and colour grids, $67 for tilesets);
whatever does not fit goes on into the new half of the 4 MB ROM (banks $80 and
up) by itself — nothing to set. The space meter under the window shows it: the
$64 / $67 bars turn amber when full (not an error any more), and the **new** bar
counts the new banks in use (of 128; hover it for each bank's bytes). Scripts,
texts and NPC lists ($60) do not move yet — that is the next step.

Messages in the **Build log**:

- **ERROR** — the build stops; the message names the room / script / field. A
  window shows it too, with **Copy error**.

Copying from the log: select with the mouse (or click in it and ⌘A / Ctrl+A), then
⌘C / Ctrl+C — or right-click → **Copy all**.
- **WARN** — builds, but read it: e.g. a boss room without a song, too many
  different sprites on a screen, a joinable enemy without a join version.

Test with your own save: gate floors appear when you dive the gate; boss
floors are the last floor of the gate; a **world** is entered through its
portal (the World tab's *Still needs* list and the build warnings say what a
world lacks: a portal, a way out, something that clears it, a room no door
reaches, a room with battles but no list).

**▶ Play here** (Rooms tab, F5 — the topic *Play here*) builds when needed and starts the
game in the room with a game state of your choice; More ▾ → **▶ Play the game here** (any
selected cell) does the same from that cell — it starts your build
right there — see *NPCs*.
