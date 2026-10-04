"""families.py — the Families page's document model (S104, ROADMAP P3.10a).

Reads and writes the parts of project.json `gamedata` that are about
families (PROJECT_COMPILER §2.20):
  gamedata.monsters.<id>.family     which family a species belongs to
  gamedata.families.<name>.dialogue the arena-lobby party dialogue voice
  gamedata.families.spirit.names    Spirit's 8 default names
  gamedata.families.<name>.icon     the family's 8 x 8 icon (S107, P3.10 part 2c)
The project stores only differences from the original game: setting a value
back to vanilla removes the key (and any object it leaves empty).
Every setter validates by building the gamedata model (the same code the
compiler runs), so the GUI can never save what the build would refuse.
"""

import copy
import os

from editor2.core import gamedata as G

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class FamiliesMixin:
    # ------------------------------------------------------------ reading
    def _gd_model(self, gd=None):
        """The compiler's own model of `gd` (default: the document's). Project
        enemy EIDs come from the same Project code the build uses."""
        from editor2.core.project import Project
        data = copy.deepcopy(self.data)
        if gd is not None:
            data['gamedata'] = gd
        try:
            prj = Project(data, self.project_dir)
        except Exception:
            prj = None
        if prj is not None:
            # S105: the compiler's own construction (project enemies by EID and
            # by id, the project's custom.species) — one source of truth
            return prj.gamedata()
        try:
            return G.Gamedata(data.get('gamedata') or {}, REPO, [])
        except G.GamedataError:
            # S119b: this fallback has no project enemies — an encounter list naming
            # one ("klamutra") crashed the editor at open; the game's own data then
            return G.Gamedata({}, REPO, [])

    def species_names(self):
        return G.monster_names(REPO)

    def vanilla_family(self, sid):
        return G._rows(G.vanilla(REPO), 'monster_info')[sid][0]

    def family_members(self):
        """{family: [species ids]} for the collectible species 0-214."""
        g = self._gd_model()
        out = {f: [] for f in range(G.NUM_FAMILIES)}
        for sid in range(G.COLLECTIBLE_MAX + 1):
            f = g.monster[sid][0]
            if f in out:
                out[f].append(sid)
        return out

    def family_voice(self, fam):
        return self._gd_model().voice[fam]

    def spirit_names(self):
        return list(self._gd_model().spirit_names)

    def family_icon_grids(self):
        """All 11 icons from ONE model build (the list / combo icons)."""
        return [[list(r) for r in g] for g in self._gd_model().icons]

    def family_icon(self, fam):
        """The family's icon as the game will draw it: 8 x 8 grid of 0-3."""
        return [list(r) for r in self._gd_model().icons[int(fam)]]

    def vanilla_family_icon(self, fam):
        """The icon the game ships (Spirit: the S104 ghost wisp)."""
        return G.vanilla_icons(REPO)[int(fam)]

    # ------------------------------------------------------------ writing
    def _commit_gamedata(self, gd):
        gd = {k: v for k, v in gd.items() if v not in ({}, None) or str(k).startswith('_')}
        self._gd_model(gd)                          # raises GamedataError if invalid
        self.data['gamedata'] = gd

    def set_monster_family(self, sid, fam):
        sid, fam = int(sid), int(fam)
        if sid in G.PROTECTED_SPECIES or not 0 <= sid <= G.COLLECTIBLE_MAX:
            raise G.GamedataError(f"species {sid} cannot change family")
        gd = copy.deepcopy(self.data.get('gamedata') or {})
        mons = gd.setdefault('monsters', {})
        o = mons.setdefault(str(sid), {})
        if fam == self.vanilla_family(sid):
            o.pop('family', None)
        else:
            o['family'] = G.FAMILY_NAMES[fam]
        if not o:
            mons.pop(str(sid))
        self._commit_gamedata(gd)

    def set_family_voice(self, fam, voice):
        fam = int(fam)
        if voice not in G.VOICES:
            raise G.GamedataError(f"dialogue voice {voice!r}: one of A-D")
        gd = copy.deepcopy(self.data.get('gamedata') or {})
        fams = gd.setdefault('families', {})
        key = self._family_key(fams, fam)
        o = fams.setdefault(key, {})
        if voice == G.VOICE_OF[fam]:
            o.pop('dialogue', None)
        else:
            o['dialogue'] = voice
        if not o:
            fams.pop(key)
        self._commit_gamedata(gd)

    def set_spirit_names(self, names):
        names = [str(n).strip() for n in names]
        gd = copy.deepcopy(self.data.get('gamedata') or {})
        fams = gd.setdefault('families', {})
        key = self._family_key(fams, 10)
        o = fams.setdefault(key, {})
        if names == G.SPIRIT_NAMES_DEFAULT:
            o.pop('names', None)
        else:
            o['names'] = names
        if not o:
            fams.pop(key)
        self._commit_gamedata(gd)

    def set_family_icon(self, fam, grid):
        """S107 (P3.10 part 2c): the family's icon (8 x 8 grid of 0-3) — the
        compiler writes it into the font glyph AND the gfx stream. The
        original icon again removes the key."""
        fam = int(fam)
        rows = G.icon_rows(G.icon_grid(G.icon_rows(grid), f'families.{fam}.icon'))
        gd = copy.deepcopy(self.data.get('gamedata') or {})
        fams = gd.setdefault('families', {})
        key = self._family_key(fams, fam)
        o = fams.setdefault(key, {})
        if rows == G.icon_rows(self.vanilla_family_icon(fam)):
            o.pop('icon', None)
        else:
            o['icon'] = rows
        if not o:
            fams.pop(key)
        self._commit_gamedata(gd)

    @staticmethod
    def _family_key(fams, fam):
        """The existing key naming family `fam` (any spelling), else its name."""
        for k in fams:
            if str(k).startswith('_'):
                continue
            try:
                if G.family_index(k, 'families') == fam:
                    return k
            except G.GamedataError:
                pass
        return G.FAMILY_NAMES[fam].lower()
