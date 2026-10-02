"""breeding_doc.py — the Breeding tab's document model (S113, ROADMAP P3.12;
EDITOR_DESIGN §5.4 "As built S113"; PROJECT_COMPILER §2.29).

Reads and writes `gamedata.breeding` (PROJECT_COMPILER §2.20 + §2.29):
  family.<slot>          the family recipe that makes species <slot> (the one
                         the library page shows) — {p1, p2} or null (none)
  special.overrides      a vanilla special row changed (by vanilla index)
  special.removes        a vanilla special row deleted
  special.appends        new special rows
  special.table          the WHOLE special table (heavy rework / the
                         generator) — then the three above are not used
Matchers are written as a species ID (int) or a family NAME ("Spirit");
a bare species name is never written (family names win — "Slime" = the
family). Only differences from the original game are stored; every setter
validates with the compiler's own model (raises GamedataError) and the
analysis is the resolver's (editor2/core/breeding.py), so what the tab shows
is what the game does.
"""

import copy
import json

from editor2.core import gamedata as G
from editor2.core import breeding as B


def matcher_json(m):
    """A matcher byte -> what the project stores."""
    return G.FAMILY_CODES[m] if B.is_family(m) else int(m)


class BreedingMixin:
    # ------------------------------------------------------------ reading
    def breeding_analysis(self):
        """breeding.Analysis of the current document (cached per content)."""
        from editor2.core.project import Project
        key = json.dumps(self.data, sort_keys=True, default=str)
        cache = getattr(self, '_breed_cache', None)
        if cache and cache[0] == key:
            return cache[1]
        an = B.Analysis(Project(copy.deepcopy(self.data), self.project_dir))
        self._breed_cache = (key, an)
        return an

    def vanilla_breeding_analysis(self):
        """The same read-outs for the original tables + this project's
        monsters (the depth histogram's comparison)."""
        from editor2.core.project import Project
        cache = getattr(self, '_breed_van', None)
        key = json.dumps({k: v for k, v in (self.data.get('gamedata') or {}).items()
                          if k != 'breeding'}, sort_keys=True) + json.dumps(
            (self.data.get('custom') or {}).get('species'), sort_keys=True)
        if cache and cache[0] == key:
            return cache[1]
        d = copy.deepcopy(self.data)
        d.setdefault('gamedata', {}).pop('breeding', None)
        an = B.Analysis(Project(d, self.project_dir))
        self._breed_van = (key, an)
        return an

    def _breeding_gd(self):
        return copy.deepcopy((self.data.get('gamedata') or {}).get('breeding') or {})

    def special_is_table(self):
        return ((self.data.get('gamedata') or {}).get('breeding') or {}).get(
            'special', {}).get('table') is not None

    def special_rows(self):
        """The special table in the order the game scans it: [{row, p1, p2,
        min_plus, result, plus_mod, src: ('vanilla'|'edited'|'added'|'table', n),
        decides: number of (pedigree, mate) pairs it decides}]."""
        an = self.breeding_analysis()
        g = an.g
        out = []
        for i, e in enumerate(g.special):
            out.append({'row': i, 'p1': e[0], 'p2': e[1], 'min_plus': e[2],
                        'result': e[3], 'plus_mod': e[4], 'src': tuple(g.special_src[i]),
                        'decides': an.row_use.get(i, 0)})
        return out

    def removed_special_rows(self):
        """[(vanilla index, row bytes)] the project deleted."""
        return list(self.breeding_analysis().g.special_removed)

    def family_recipe(self, sid):
        """(p1, p2) matcher bytes of the family recipe that makes `sid`, or None."""
        b, c = self.breeding_analysis().g.family[int(sid)]
        return None if (b, c) == (0xFF, 0xFF) else (b, c)

    def vanilla_family_recipe(self, sid):
        b, c = G._rows(G.vanilla(self._repo_root()), 'family_recipes')[int(sid)]
        return None if (b, c) == (0xFF, 0xFF) else (b, c)

    def _repo_root(self):
        import os
        return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

    # ------------------------------------------------------------ writing
    def _commit_breeding(self, br):
        gd = copy.deepcopy(self.data.get('gamedata') or {})
        sp = br.get('special') or {}
        for k in ('overrides', 'appends', 'removes'):
            if k in sp and not sp[k]:
                sp.pop(k)
        if 'special' in br and not sp:
            br.pop('special')
        if 'family' in br and not br['family']:
            br.pop('family')
        if br:
            gd['breeding'] = br
        else:
            gd.pop('breeding', None)
        # the compiler's model refuses what the build would refuse
        from editor2.core.project import Project
        data = copy.deepcopy(self.data)
        data['gamedata'] = gd
        Project(data, self.project_dir).gamedata()
        self.data['gamedata'] = gd
        if not gd:
            self.data.pop('gamedata', None)

    def set_family_recipe(self, sid, p1, p2):
        """The family recipe that makes species `sid` (0-214); p1 = None = no
        family recipe. The library page follows (coherence Set 1)."""
        sid = int(sid)
        if not 0 <= sid <= G.COLLECTIBLE_MAX:
            raise G.GamedataError(f"species {sid}: only 0-214 have a family recipe slot "
                                  "(new species are bred by special recipes)")
        br = self._breeding_gd()
        fam = br.setdefault('family', {})
        new = None if p1 is None else (int(p1), int(p2))
        if new == self.vanilla_family_recipe(sid):
            fam.pop(str(sid), None)
        else:
            fam[str(sid)] = None if new is None else {'p1': matcher_json(new[0]),
                                                      'p2': matcher_json(new[1])}
        self._commit_breeding(br)

    def _row_json(self, v):
        return {'p1': matcher_json(v['p1']), 'p2': matcher_json(v['p2']),
                'min_plus': int(v.get('min_plus', 0)), 'result': int(v['result']),
                'plus_mod': int(v.get('plus_mod', 0))}

    def add_special(self, v):
        """A new special recipe {p1, p2, min_plus, result, plus_mod} — the
        compiler places it by specificity."""
        br = self._breeding_gd()
        sp = br.setdefault('special', {})
        key = 'table' if sp.get('table') is not None else 'appends'
        sp.setdefault(key, []).append(self._row_json(v))
        self._commit_breeding(br)

    def set_special(self, src, v):
        """Change the row that came from `src` (special_rows()[i]['src'])."""
        kind, n = src
        br = self._breeding_gd()
        sp = br.setdefault('special', {})
        row = self._row_json(v)
        if kind in ('vanilla', 'edited'):
            van = G._rows(G.vanilla(self._repo_root()), 'special_recipes')[n]
            ovs = [o for o in sp.get('overrides', []) if o.get('index') != n]
            if bytes([int(v['p1']), int(v['p2']), row['min_plus'], row['result'],
                      row['plus_mod']]) != bytes(van):
                ovs.append(dict({'index': n}, **row))
            sp['overrides'] = sorted(ovs, key=lambda o: o.get('index', 0))
        elif kind == 'added':
            sp['appends'][n] = row
        elif kind == 'table':
            sp['table'][n] = row
        self._commit_breeding(br)

    def remove_special(self, src):
        kind, n = src
        br = self._breeding_gd()
        sp = br.setdefault('special', {})
        if kind in ('vanilla', 'edited'):
            sp['overrides'] = [o for o in sp.get('overrides', []) if o.get('index') != n]
            rem = [r for r in sp.get('removes', []) if r.get('index') != n]
            rem.append({'index': n})
            sp['removes'] = sorted(rem, key=lambda r: r['index'])
        elif kind == 'added':
            sp['appends'].pop(n)
        elif kind == 'table':
            sp['table'].pop(n)
        self._commit_breeding(br)

    def restore_special(self, n):
        """Bring back vanilla special row n (undo a remove / an edit)."""
        br = self._breeding_gd()
        sp = br.setdefault('special', {})
        sp['removes'] = [r for r in sp.get('removes', []) if r.get('index') != n]
        sp['overrides'] = [o for o in sp.get('overrides', []) if o.get('index') != n]
        self._commit_breeding(br)

    def special_to_table(self):
        """Switch to the whole-table form: the current effective table (minus
        rows that can never fire because an identical row comes first — vanilla
        has two) becomes `special.table`."""
        an = self.breeding_analysis()
        rows, seen = [], set()
        for e in an.g.special:
            k = (e[0], e[1], e[2])
            if k in seen:
                continue
            seen.add(k)
            rows.append(self._row_json({'p1': e[0], 'p2': e[1], 'min_plus': e[2],
                                        'result': e[3], 'plus_mod': e[4]}))
        br = self._breeding_gd()
        br['special'] = {'table': rows}
        self._commit_breeding(br)

    def special_to_vanilla(self):
        """Throw away every special-table change (back to the original 825)."""
        br = self._breeding_gd()
        br.pop('special', None)
        self._commit_breeding(br)

    def reset_family_recipes(self):
        br = self._breeding_gd()
        br.pop('family', None)
        self._commit_breeding(br)

    def apply_breeding(self, breeding_gd):
        """Replace gamedata.breeding (the generator's proposal)."""
        self._commit_breeding(copy.deepcopy(breeding_gd))
