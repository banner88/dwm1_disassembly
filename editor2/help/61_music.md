# Music

The **Music** tab is where songs live: the game's own, the DWM2 songs, MIDI
files — and where each one plays (rooms, gates, battles).

**What you hear is the game.** ▶ runs the game's OWN sound engine (the code in
the ROM, on a CPU built into the editor) — checked note for note against the
game for every song and sound effect. Only the very last step (turning the
sound chip's settings into audio) is the editor's, so the tone can differ a
little from a real Game Boy; the notes, timing, loops and effects do not.
Preview needs **numpy** (`pip install numpy`) and an audio output. If a song
does not play, the terminal you started the editor from shows a `[music] …`
line saying why.

## Songs

The list holds:

- **the game's music, jingles and sound effects** (extracted from the ROM;
  each says where the game uses it: rooms, scenes, code — `$27` is the battle
  theme, `$2B` the Starry Night final, `$34` the gate floors, `$02` silence);
- **DWM2 songs** — all 31 of DWM2's songs, converted to this game's engine;
- **the MIDI library** — songs converted earlier;
- **your project's songs** (bold).

Pick one: **▶ Play** (double-click works too), **■ Stop**, **Save as WAV…**
(to listen elsewhere). Type a **name** for any song — the game's too; names
are for you (the editor shows them everywhere), not put into the game.

**Add to the project** puts a DWM2 / MIDI-library song into your project (you
can add the same song twice under two names). **Remove from the project** also
clears every place it was set (they go back to the game's songs).

**Import MIDI…** converts a MIDI file into a song of your project,
automatically: the three melodic MIDI channels that play the longest become
pulse 1, pulse 2 and the wave channel (the lowest one = the wave channel, the
bass), the drum channel (MIDI channel 10) becomes the noise channel; notes are
timed to the game's frames; the song loops. A note lists what was left out.
The converted song is saved in your project (`assets/music/`).

### Limits (the meters at the top)

- **95 song ids** ($9E-$FC): every song takes one per channel (1-6).
- **Two song banks** of 16,000 bytes each (banks $74 and $75). Songs fill the
  first bank in id order; the rest go to the second.
- A song that uses the **sound-effect channels** (some DWM2 jingles) loses that
  channel whenever a sound effect plays.

## Rooms

Every room — yours first, then the game's — with the game's song, **your
song** (plays when you enter, and after loading a save there) and
**battles here** (the song of battles that start in that room).

**Music by flag…** (your rooms, S129): another song while flags / story checks
hold — rules *song while conditions*, the first rule whose conditions all hold
plays (none = the room's song). Read when the room loads (a *Refresh the room*
step changes it at once).

## Gates

Every gate: the song of its **floors** — the maze floors, its special rooms
(treasure / priest / maze rooms) and your rooms served in it that have no song
of their own — and of its **battles**. Empty = the gate theme and the battle
theme. The floor before a VANILLA boss room keeps that boss's own song; before
your own boss room with no song, the gate's song plays (and in that room too).

**Music by flag…** (S129): the floors' song by flags / story checks, the same
rules as a room's (first rule that holds; none = the floors' song).

## Battles

- **every battle** — every battle the game plays its battle theme ($27) for;
- **boss fights** — gate bosses and the battles your conversations start (both
  are the game's "boss" battles);
- **arena battles** and **the Starry Night final** (the battle after the
  tournament's three matches — the one the game gives its own battle music,
  $2B);
- **a song for one fight**: pick the battle's first enemy (your enemies, the
  game's bosses and arena teams) and its song.

The most specific setting wins: one fight › the arena › the room's "battles
here" › the gate's battle song › boss fights › every battle. Link (cable)
battles always keep the game's music.
