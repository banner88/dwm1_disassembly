# Enemies

**Project enemies** are your own battle rows (Gates tab → **Project
enemies…**, or **Enemies…** inside a Battle step).

- **Add from vanilla…** — start from any vanilla row (the story / gate
  bosses are listed first) and name it.
- Change species, level, exp, the six stats, skills and AI weights. **HP is at
  least 2** (S149): a monster made from the row (one that joins, a gift, a
  breeding mate) gets 80-100% of it, rounded down — HP 1 would give a monster
  with 0 HP that is fainted for good. The game's own rows are HP 2 or more; an
  older project's HP 1 rows are raised to 2 when you open it. The
  species list includes the project's new monster (`custom.species`) — its
  wild and boss rows are project enemies like these.
- **joins?** — *always*, *sometimes* (tier 1 = likely … 6 = unlikely) or
  *never*.
- **join version** — the monster the player gets instead of the one they
  fought (vanilla does this for every story boss: a strong fight row, a
  weaker join row). **Make join version** creates one (stats halved, always
  joins) and links it; edit its stats afterwards.
- **gender** (S149) — of the monster that joins: rolled by the species'
  female ratio (the default), or always male / always female. A join version
  decides for the monster you get.

A project has up to **3,321** enemy rows (S149; was 640): the first ones are
kept with the enemy code, the rest go to new banks of the 4 MB ROM by
themselves.

Battle steps can also use vanilla rows directly (they keep their own join
setting).
