# Cutscenes

The **Cutscenes** tab shows every scene the game plays with its scripts —
the King's speeches, the boss rooms' endings, the arena, the intro — and
the scenes of **your rooms** exactly as the editor builds them. It also
**plays** any of them in the real game, right in the editor.

**The list (left):**

- **Chains** — scenes the player walks between in the game, played one
  after the other. **The intro** = bedtime (the kids run in circles, go to
  bed, Terry wakes up), the east room (Warubou takes Milayou, Watabou
  arrives) and the dresser — which runs by itself through the tree tunnel,
  the Starry Shrine, the old man's walk up GreatTree and the Castle
  minister.
- **Your rooms** — your custom rooms and the game rooms you cloned (a
  clone carries the game's scripts; your talk / conversation / shop
  scripts are shown as the compiler lowers them).
- **Game rooms** — every game room with scenes.

**What a "scene" is:** a script runs from what starts it (entering the room,
talking to someone …) and branches on flags; every branch that shows
something is listed as its own scene. **Only scenes where actors move**
(on) keeps the ones where someone walks, hops, flies, appears or vanishes —
plain talks (the egg appraiser, shopkeepers) are hidden; untick it to see
every scene, talks included. **Search** finds words of a text, a room
name or a step.

**The storyboard (middle):** what starts the scene (entering the room,
talking to an NPC, examining a spot, stepping on one), **Plays when** (the
screen, event flags and story variables on the way to it) and the steps as
sentences — walks ("NPC 2 walks left 2 tiles"), jumps / hops / flights /
appearing / vanishing (the game's movement programs), turns, texts, flags,
music, sounds, room changes, battles. Colour = kind of step. Hover a step
for what the game does exactly; **double-click a branch step** to open the
scene it goes to. A text step shows its whole text below.
**Every step is in words:** a memory write such as `$D92B := 6` reads "Room state
of Castle screen 1 → state 6", a flag names what it marks ("flag $0030 (arena class
G won)", or where the game sets it), rooms / items / monsters / skills / music by
name; the raw step stays at the end in [brackets].
**Names you can trust vs labels:** an NPC is named only when its OWN talk text
names the speaker ("King:…", "Pulio:…"); most NPCs talk as "*" and show as
"NPC 3 (sprite $11)". Room names ("Arena Lobby", "Gate Hub" …) are the
editor's labels, typed by people — the header also says how the GAME enters
the room ("GreatTree screen 1 door (4, 3)"), from the game's own exit tables
and scripts.
A game variable no game code reads (only scripts) is shown with "(meaning
inferred from the scripts that use it)" — that name is our reading, not the game's.

**The picture (right):** the game's own frame for the selected step — the
frame in which the game ran it (a walk or a wait: the frame it finished) —
**recorded** from a silent run of the scene (automatic — or press
**Record frames**); the arrow keys in the step list step through the scene
picture by picture. Without PyBoy it shows the room with the actors where the
scene puts them (numbers = actors; 0 is Terry; faded = hidden; the dot shows
the facing).

**▶ Play scene** (or double-click a scene) opens the **Playback** window:
the game runs the WHOLE scene here, with sound — from what starts it to its
end (a chain: all its scenes). **▶ From this step** plays the scene from the
step selected in the list: the steps before it run fast (no sound, text
skipped) so everyone stands where they should, then it plays normally. It is **set up for you** — no walking
there: the editor starts a new game in the background (once per build,
cached), sets the flags the scene needs, keeps the room's own entry scene
quiet, puts Terry in the room and starts the scene the way the game does
(entering the room, talking to the NPC, examining the spot).

- **Sound:** **View → Mute game playback** (⌘⇧M / Ctrl+Shift+M) mutes
  EVERY Playback window and overrides the window's own Sound box; toggle
  it again for sound.
- **Auto text** (on) presses A on every text box once it has been on screen
  for the **read time**; turn it off to press A yourself. **YES/NO** says
  what auto text answers. **Auto D-pad** gets Terry out of bed (the script
  waits for a direction press there). The naming screen takes the default
  name.
- **Pause**, **Frame ▸** (one frame), **Step ▸▸** (run until the scene's
  next step starts, then stop — the log names the step; turns, flags and
  other steps that take no time run in the same frame as their neighbours
  and are listed together), **◂ Step back** (to before the last Step),
  **⟲ Restart**, **Next scene ⏭** (chains), speed 1× (with sound) / 2× /
  4× / 8×.
- **Keys** (click the picture first): arrows, **Z** or **Space** = A,
  **X** = B, **Enter** = Start, **Backspace** = Select. When a scene is over
  the game keeps running — you can walk around.
- The storyboard highlights the step the game is on.
- The game runs **beside** the editor (its own process): if a scene makes
  the game crash, the window says "the game stopped answering" and stops
  it — the editor is fine; press **⟲ Restart**. If the game **resets** (back
  to the title) the log says so in red — that scene's set-up is wrong:
  please report it.

**Room state:** what stands in a room depends on the story (GreatTree's
first screen has the old man in one state and the man by the cliff in
another). The set-up picks the state the game is in when the scene plays —
from the scene's own conditions, else from the flags (the state the game
leaves the room in when it sets them), and always one that holds the NPCs
the scene moves. The header says which state and why. Where the player
starts: the opening bedtime scene plays from a real new game; a scene the
game starts on entering a room puts the player where the game does (the
door / warp / gate arrival, or — for a screen you only reach by walking
across from the next screen, like Warubou's east room — walking in from
that screen). A scene the game
reaches through ANOTHER script's room change (falling through the Farm's
hole, a boss room's warp back) is set up the way that script leaves the
game: the same arrival spot and screen, the same values it writes. A walk that sends
someone where he already stands moves nobody — the header says so (the
Old Man Gate Room's step-on scenes: he only moves when he is not in the
way already).

**Copied rooms** ("Make editable") follow the game's room state like the
original (Rooms → *Follow the game's room state*, on by default), so their
scenes play with the same people as the game's. Before S118c a copy kept
its own state and stayed in state 0 (the copied GreatTree moved the old man
instead of the man by the cliff); opening the project switches existing
copies over.

**Play on:** your last build (your changes included) or the original game.
Your own rooms always play from your **build** — build first (⌘B).
**Start from:** a new game, or **your save file** (a .sav) — use it for
scenes that need a real party (the save must be from a build of this
editor; the original game cannot read it).

**Needs:** `pip install pyboy` (Playback and the recorded pictures). The
first Play of a new build takes a few seconds (the start state is made
once and kept in your project's build/playback folder).

**Limits (this version):** see also *Your own cutscenes* below. A few game scenes need things
the set-up cannot fake (a monster of a given species in the party, a full
bag …): the window says so and starts the scene at its own first step. The
set-up does not fight: a scene that plays **after a battle is won** (a boss
room's exit, what follows Durran's fights) starts at its own first step, and a scene
that **starts** a battle hands it to you (the battle is real — fight it with
the keys, or press Restart). Names the game fills in before a text (the egg
appraiser's baby) show as "Slime" when the set-up has none.
Game scenes that draw tile patches (opcode $24 — treasure chests, doors
opening in the Castle and Bazaar) play right in the game but are not yet
safe inside a CLONED room (see Limits).


## Your own cutscenes (the editor)

**＋ New cutscene…** (top left) makes a scene in one of your rooms (a copy of a
game room works too): its name, the room, the **screen** it plays on and what
starts it. Your scenes are listed under **Your cutscenes (edit)**; click one to
edit it. Everything is in **tiles** of that screen (0-9 across, 0-7 down) and
every actor is a **named** NPC — the game moves NPCs by their number in the
room's list, the editor does that for you.

**What starts it (Plays when):**

- **Entering the room (this screen)** — when the player arrives on the screen
  (a door, a warp, or walking across from the next screen). **Player starts
  at** = where he arrives (filled from the door that leads here); his walks
  are counted from there. Afterwards the room's own arrival script still runs.
- **Talking to an NPC** — pick the NPC (in **＋ New cutscene…** too). Every NPC
  of the screen is in the list; one that has no name yet ("NPC 1 at (7, 3) — no
  name yet") gets one when you pick it — *Shopkeeper* for a shopkeeper, else
  *NPC 1* … (rename it any time: right-click it). After the scene (or when it
  does not play) the NPC does what it always does — says its text, opens its
  shop.
- **Examining a tile** / **Stepping on a tile** — pick the tile (**Pick tile**,
  then click it on the picture); the spot is made for you. Remember: a test ROM
  for other people should put such spots on art that looks like something.
- **Only when flags… ▾** — the scene plays only when these flags are ON (and
  those OFF). **Plays once** — a flag of its own is turned on when it starts,
  so it never plays again (saved with the game).

**What does a step do?** Every step's form starts with a line saying what it does;
hover a step in the list, a step in **＋ Add step ▾**, or any field of the form for
more (e.g. *Wait until everyone stops* = wait for the walks / hops / flights that were
started with "the next step starts at once").

**The picture (the stage)** is the room screen with every actor drawn as the
game draws them, **facing** the way the scene has turned them (the yellow wedge
shows it too), after the step selected in the list. The selected step's
movement is drawn as an **arrow** (walks: the path tile by tile; hops / flights:
an arc; appearing: a ring). Faded = hidden at that moment; *?* after a name =
the editor does not know where he stands there (see below). NPCs nobody has
named are drawn grey ("NPC 2").

- **Drag an actor onto a tile** = he walks there (a new step after the
  selected one — or, when the selected step is that actor's walk / flight, it
  changes where it goes).
- **Right-click an actor**: faces (a direction, or toward someone), appears /
  disappears (instantly or flickering), hops / jumps / leaps…, flies in / off,
  rename; on a cast member: move it, remove it.
- **Right-click an empty tile**: name the NPC standing there, **new cast
  member here**, "(the selected actor) walks here", change the tiles here.
- **Room state shown** — which state of the screen the picture shows (rooms
  with states).

**Actors.** *Player* is always there. An NPC takes part once it has a name:
**Name an NPC…** (or right-click it), or simply pick it in any "Who" list — the
NPCs without a name are listed at the end and named when picked. The name goes on that NPC in every room
state of the screen. A **cast member** (＋ Cast member…) is an NPC that is
hidden until a scene shows it — it "comes out of nowhere": pick its look, name
it, put it on a tile (it appears there, or with *Appear … somewhere else* /
*Fly in … lands on* anywhere). It gets the same NPC number in every state of the
screen (shorter states get invisible pads — the game has 8 NPC slots per
screen). After the room is loaded again it is hidden again (for a lasting
change use the room's state rules).

**Steps** (＋ Add step ▾ adds after the selected step — or into a selected *If
YES / If NO / Then / Otherwise* row; ▲ ▼ ⧉ ✕ move, duplicate, remove):

| Step | What the game does |
|---|---|
| Walk to a tile | the actor walks there (left/right first or up/down first); *the next step starts at once* = he walks while the next steps run (several actors walking together); *run* = double speed; *keep facing* = walks backwards |
| Turn to face | a direction, or toward another actor |
| Appear / Disappear | instantly, flickering (about 4 seconds — the game's own effect) or spinning; *Appear somewhere else* puts a cast member on another tile first |
| Hop / jump / leap… | the game's movement programs (hop, jump, spin jump, jump up, leaps, drops, floating …; some are NPC-only, some player-only) |
| Fly in / fly off | the helper's flight: in = lands on a tile coming from the upper left / right; off = up and away; length and curve |
| Say / Ask YES-NO | the same box editor as NPC conversations: one editor per box, each drawn as the game draws it (red = does not fit; **Fit** / **Fit all** wraps it into boxes; **+ Add box**); top / bottom; YES / NO branches. What you type is kept when you pause (one undo step per pause) |
| If flags… | the steps under *Then* / *Otherwise* |
| Wait / Wait until everyone stops | frames (60 = 1 second) |
| Music / Sound effect | a song (or back to the room's song) / a sound (▶ Hear it) |
| Shake / Fade / Flash | the screen shakes up-down / left-right; fades to black and back; flashes |
| Hide / show the monsters | the player's following monsters (they come back by themselves after the scene) |
| Change tiles of the room | a piece of the screen takes the look it has in another screen / room state of this room (paint the open door there) — until the room is loaded again |
| Turn flags ON / OFF, Give an item / a monster, Battle, Warp the player, Stop here | as in conversations |

**Where the player stands.** In an entry scene the walks of the player are
counted from *Player starts at*; on a step-on spot he stands on it. When the
editor cannot know (a talk: he can stand on any side; after a branch that
moved him differently), his walk goes to the tile **exactly** wherever he is —
the scene then waits for that walk (it cannot run together with others), and
the picture marks him *?*.

**Previews.** **▶ Preview** plays the scene on the picture from the editor's
model (instantly, no build; walking speed, jumps, flights and waits are the
game's measured times; the slider scrubs; *answer YES / NO* picks the way at
questions and flag tests). **▶ Play in the game** saves, builds and plays the
scene in the real game (the Playback window, set up for you: flags, the room,
the trigger) — the exact thing.

**Problems** are listed under the picture (red = it cannot be built: an
unknown actor, an NPC with different numbers in different states, a piece of
tiles past the screen edge …; orange = worth knowing).

## Changing a game scene in a copied room

A copied room ("Make editable") carries the game's own scripts. Pick one of its
scenes under **Your rooms**, select a step and use **Edit step… / Insert step
before… / Delete step**: any of the game's opcodes (named and explained), its
parameters (numbers like `$0020`, RAM / flag names, `@LABEL` of the script for
a branch); the line under it says what the step will do. The copy's chests and
doors that open by a tile patch (opcode $24 / $61) now draw in the copy too
(the patch is copied into your room; before S119 a copy drew nothing there).
