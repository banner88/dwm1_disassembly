# Animations

The **Animations** tab makes **new battle animations** from the frames of the
game's 45 (a "mashup": Zap's bolt, then Bang's burst, then a pause …). The
game's own 45 animations are never changed; yours get the numbers **$2D** and
up (at most 32). A skill shows one through the **Skills** tab → **Animation**.

## The list

**New…** asks which stock animation to start from (a copy of all its steps)
and a name. **Duplicate**, **Rename…**, **Up** / **Down** (the order is the
number; skills follow by name) and **Delete** (refused while a skill shows it —
the message names the skills).

## The preview

Plays the animation as the game draws it — the sprites at the middle of the
foes on the battle screen's cream, 2x, 60 frames per second — with its
**sounds** (the game's own sound engine, recorded). **Loop** repeats it;
**Sound** mutes it. Selecting a step shows its frame. The line above it gives
the length, which stock animations its frames come from and the tile count, and
the skills that show it.

## Steps

The steps play in order. Each is one of:

- **a frame** of a stock animation, shown for **Frames** screen frames (1-256;
  60 = one second) — the thumbnail is the frame, **From** the animation;
- **a sound** — starts as the next frame starts; it takes no time;
- **a blank** — nothing shown, for its frames (a pause).

**Add frames…** opens any stock animation: play it, pick its steps (Ctrl /
Shift for several, **Select all**) and OK inserts them after the selected step,
with their timing and sounds. **Add sound…** lists the 35 sound effects the
animations use (it plays the one you pick). **Add blank**, **Remove**, **Up** /
**Down** (one step). Every edit is one undo step.

## Limits

- Frames from at most **4** different stock animations: each keeps its own
  colours, and an animation has four sprite palettes.
- At most **128** different tiles over all its frames (the tile block the game
  loads them into) — the meter shows the count. Big explosions use many.
- At most 200 different frames and 120 steps.
- An animation's steps are its whole timeline: the looping projectile of
  Firebal / IceBolt (the game's own "go back" step) is not something a new
  animation can do — copy its frames a few times instead.
- New tile art (drawing your own frames) is not possible yet.

## In the game

A new animation is a set of tables in two new banks ($6F engine + frames, $70
tiles); the game's animation code reads a number of $2D and up from there and
everything else as before. The developers' animation viewer (game mode 5,
"Effect") lists the new ones too. Build the ROM and use the skill in a battle:
what you see in the preview is what plays (measured frame by frame in the
emulator for all 45 stock animations and a mashup).
