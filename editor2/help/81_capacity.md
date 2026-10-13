# Capacity — how much room is left

The **Capacity** tab (next to *Build & Play*) lists every limit your project can
reach, in words: how much you use, of how much, and what happens when it is full.
It is measured from your unsaved project about a second after each edit, the same
way the build counts (S145).

## The two meters under the window

- **ROM space** — how much of the space for your rooms, texts, screens, tilesets
  and animated tiles you use. The 4 MB ROM gives your project about **2 MB** for
  this; everything fills one bank after another by itself, so there is nothing to
  arrange. Hover it for "about N more rooms like your average one".
- **rooms N / ≈…** — your rooms, of about how many fit. Around **950 rooms** the
  table that holds every room's record, songs and battles is full (it grows by 15
  bytes a room); that table fills before the ROM space does for most projects.

A **⚠ n** after them means n limits are nearly full (80 % or more) or full.
Click either meter (or the ⚠) to open the Capacity tab.

## The tab

- **The top line** — ROM space and rooms, then *About N more rooms like your
  average one* (what your rooms cost on average, against the space left — and the
  room table, whichever runs out first). A new project uses a typical room
  (about 3.5 KB) until it has rooms of its own.
- **The rows**, in groups (Space · Rooms · Text and story · Gates, battles and
  monsters · Music):
  - *Used* — green, amber (80 % or more) or red (full);
  - *The fullest* — for a limit that is per room or per screen, the room (and
    screen) that uses the most: the largest room (16 screens is the most: a room is
    at most 4 × 4), the fullest screen (8 people), the screen with the most doors
    (17), the room with the most talk, people, doors and colours (one bank, about
    15 KB), the room with the most animated tiles (one bank, about 15.7 KB).
    One room or screen using ALL of its own allowance shows *all used* in amber
    and is not counted in the ⚠ — it is your choice, not a problem;
  - *When it is full* — what happens: the build stops, the editor refuses
    another, or (for space) the rest goes on into the next bank by itself.
- **Double-click** a row to open what it counts: a room row opens that room on
  the Rooms tab; the others open the tab that edits them (Music, Progression &
  Flags, Gates, …).
- **Measure now** measures at once.
- **View → Show technical ids** adds a *Technical* column (the table, bank or
  range behind each limit) and a list of every bank with its bytes.

## Screens with states, per group of 128 rooms

A screen that has **two or more room states** remembers which one it shows in
one byte, and **every 128 rooms share 640 bytes** for this (the game keeps it in
a fixed part of its memory). Since S146 a screen with **one state** costs nothing:
all of them share one byte that always reads 0 — the original game does the same
for its gate and maze rooms. (A one-state screen whose counter one of your own
scripts reads or writes keeps a byte of its own.) So the limit is 640 screens
*with states* in a group — a room of 4 × 4 screens with states uses 16.

When a group's bytes are **90 % used**, a new room you make goes into the next
group of 128 rooms by itself (the rest is room for states you add later to the
rooms already there). If a group still fills up, the build stops and says so;
the Capacity row *Screens with states* (in *one group of up to 128 rooms* once you
have more than 128) shows how close you are.
A copy of a game room that follows the game's own room state uses none of them.
