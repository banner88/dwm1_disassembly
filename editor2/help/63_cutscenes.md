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

**Limits (this version):** the tab shows and plays scenes; writing your own
cutscenes comes next (the cutscene editor). A few game scenes need things
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
