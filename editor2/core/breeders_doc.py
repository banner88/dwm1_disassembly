"""breeders_doc.py — the editor's model of breeding NPCs and breeding pools
(ROADMAP P3.14e2, S127; compiler: editor2/core/breeders.py, PROJECT_COMPILER §2.40).

Mixed into Document. Every mutation edits project data only:
  * custom.scripts[] {"service": {"kind": "grandpa" | "breeder", …}}  (the NPC
    itself is made by ServicesMixin.make_service_npc — Rooms tab → Service…)
  * the breeder's options (mate / pool, its words, when it offers, once)
  * custom.breeding_pools[]   the pools random breeders roll their mate from
"""

from editor2.core import breeders as BR
from editor2.core import textenc as T

TEXT_KEYS = ('intro', 'not_yet', 'after')
MATE_NOTE = 'a breeding mate (Rooms tab → Service… → Breeder)'
STAT_KEYS = ('hp', 'mp', 'atk', 'def', 'agl', 'int')


def fit_boxes(boxes, speaker=None):
    """S127 r2 (user: a breeder's words "box 1 line 1 is 28 cells (max 16)" stopped
    the build): boxes as typed, each box whose lines do not fit the game's box
    (16 cells after the "*:" label on the first line, 18 after it, 2 lines a box)
    word-wrapped into as many boxes as it needs. Boxes that fit stay as typed.
    A single word longer than a line raises textenc.TextError."""
    out = []
    for box in boxes or []:
        box = [str(ln).strip() for ln in box if str(ln).strip()]
        if not box:
            continue
        n = len(out)
        if len(box) <= T.BOX_LINES and all(
                T.cells(ln) <= T.line_limit(n, li, speaker) for li, ln in enumerate(box)):
            out.append(box)
            continue
        out += T.flow_boxes(' '.join(box), first_box=(n == 0), speaker=speaker)
    return out


class BreedersMixin:
    # ------------------------------------------------------------ migration
    def _migrate_service_words(self, notes):
        """S127 r2 (user: "box 1 line 1 is 28 cells (max 16)" stopped the build): a
        breeder's words and a service NPC's first-visit words saved by the S127 editor
        as typed are wrapped into the game's boxes on open (fit_boxes)."""
        ids = []
        for s in self.custom.get('scripts', []):
            sv = s.get('service')
            if not isinstance(sv, dict):
                continue
            ids += [sv[k] for k in TEXT_KEYS if isinstance(sv.get(k), str)]
            ft = sv.get('first_time')
            if isinstance(ft, dict) and isinstance(ft.get('text'), str):
                ids.append(ft['text'])
        for s in self.custom.get('scripts', []):            # S127 r3: a shopkeeper's greeting
            sh = s.get('shop')
            if isinstance(sh, dict) and isinstance(sh.get('text'), str):
                ids.append(sh['text'])
        for d in self.custom.get('dialogue', []):
            if d.get('id') not in ids or not isinstance(d.get('boxes'), list):
                continue
            try:
                new = fit_boxes(d['boxes'], d.get('speaker'))
            except T.TextError:
                continue                       # the build names it (a word too long)
            if new and new != d['boxes']:
                d['boxes'] = new
                notes.append(f"text {d['id']}: wrapped into {len(new)} box"
                             f"{'es' if len(new) != 1 else ''} (S127 r2: a line was longer "
                             "than the game's box)")

    # ------------------------------------------------------------ reading
    def breeding_pools_doc(self):
        """[{id, name, measures, milestones, bands [{name, level, arena, seen,
        story, mates [{enemy, weight}]}], users [script ids]}]."""
        users = {}
        for s in self.custom.get('scripts', []):
            sv = s.get('service')
            if isinstance(sv, dict) and sv.get('kind') == 'breeder' and sv.get('pool'):
                users.setdefault(sv['pool'], []).append(s['id'])
        out = []
        for p in self.custom.get('breeding_pools') or []:
            out.append({'id': p['id'], 'name': p.get('name') or p['id'],
                        'measures': list(p.get('measures') or []),
                        'milestones': list(p.get('milestones') or []),
                        'bands': [dict(b, mates=[dict(m) for m in b.get('mates') or []])
                                  for b in p.get('bands') or []],
                        'users': users.get(p['id'], [])})
        return out

    def _pool(self, pid):
        for p in self.custom.get('breeding_pools') or []:
            if p.get('id') == pid:
                return p
        raise ValueError(f'no breeding pool {pid!r}')

    def mate_rows(self):
        """[(eid, label)] — every enemy row a breeder may offer: the project's
        enemies, then the game's rows 1-486 (species and level)."""
        from editor2.core import conversation as CV
        names = CV.species_names(self.data)
        out = []
        for e in self.project_enemies():
            eid = self.project_eid(e)
            out.append((eid, f"{e.get('id')} — {names.get(int(e.get('species', 0)), '?')} "
                             f"Lv {e.get('level', '?')} (row {eid})"))
        for r in CV.vanilla_enemies():
            if 0 < r['eid'] <= 486:
                out.append((r['eid'], f"{names.get(r['species'], '?')} Lv {r.get('level', '?')} "
                                      f"(row {r['eid']})"))
        return out

    # ------------------------------------------------ S127 r2: a monster at a level
    def mate_species(self):
        """[(species id, name)] a breeder may offer: the monsters 0-214 and the
        project's new species (215-220 are not monsters — Iron Rule 8)."""
        return [(s['id'], s['name']) for s in self.species_catalog() if s['kind'] != 'combat']

    def mate_stats(self, species, level):
        """The enemy-row fields of `species` at `level` (user S127 r2: "can I not make a
        monster with a specific level"): the species' original row nearest that level
        (a new species: the gentlest Slime row, EID 2, as Monsters → new enemy does),
        its stats moved by the species' own growth curves between the two levels
        (bank $13 — what raising it would add; HP / ATK's extra level-up scaling is
        not modelled), the row's skills and AI kept."""
        from editor2.core import conversation as CV
        from editor2.core.monsters import decode_enemy
        species, level = int(species), int(level)
        if not 1 <= level <= 99:
            raise ValueError(f'level {level}: 1-99')
        if 215 <= species <= 220:
            raise ValueError(f'species {species} is not a monster (215-220)')
        g, new = self.monsters_model()
        boss = {r['eid'] for r in CV.vanilla_enemies() if r.get('boss')}
        rows = [(eid, decode_enemy(r)) for eid, r in enumerate(g.enemy)
                if 0 < eid and r[0] == species]
        if rows:
            # a boss FIGHT row (Pizzaro: 6000 HP) is not the monster — its join row is
            _eid, base = min(rows, key=lambda t: (t[0] in boss, abs(t[1]['level'] - level),
                                                  t[0]))
        else:
            base = decode_enemy(g.enemy[2])
            base['level'] = 1
        info = self.species_row(species, (g, new))
        f = dict(base, species=species, level=level)
        b_lv = max(1, int(base['level']))
        for k, st in enumerate(STAT_KEYS):
            curve = g.growth[info[9 + k]] if info[9 + k] < len(g.growth) else [0] * 99
            grown = lambda lv: sum(curve[x - 1] for x in range(2, lv + 1))   # noqa: E731
            if level >= b_lv:            # raised: the level-ups' own increments
                v = int(base[st]) + grown(level) - grown(b_lv)
            else:                        # younger: in proportion to the growth so far
                v = round(int(base[st]) * (10 + grown(level)) / (10 + grown(b_lv)))
            f[st] = max(0 if st == 'mp' else 1, min(999, v))
        return f

    def mate_for(self, species, level):
        """The project enemy a breeder offers as `species` at `level` — one made for a
        breeder before (marked MATE_NOTE) is re-used, else a new one. Returns its id."""
        species, level = int(species), int(level)
        for e in self.project_enemies():
            if e.get('comment') == MATE_NOTE and int(e.get('species', -1)) == species \
                    and int(e.get('level', -1)) == level:
                return e['id']
        f = self.mate_stats(species, level)
        f.pop('name', None)
        return self.add_enemy(comment=MATE_NOTE, **{k: v for k, v in f.items()
                                                    if k in self.ENEMY_FIELDS})

    def mate_info(self, ref):
        """(species, level) when `ref` is a mate made by mate_for, else None."""
        e = self.project_enemy(ref) if isinstance(ref, str) else None
        if e is not None and e.get('comment') == MATE_NOTE:
            return int(e['species']), int(e['level'])
        return None

    def mate_label(self, ref):
        eid = self._medal_eid(ref)
        for e, lab in self.mate_rows():
            if e == eid:
                return lab
        return f'row {ref}'

    def pool_preview(self, pid, level=0, arena=0, seen=0, story=0):
        """What a random breeder of pool `pid` offers a player with these
        values: (band index, band name, [(eid, label, percent)]) — the
        engine's choice (breeders.band_choice) on the pool as it stands."""
        p = self._pool(pid)
        pool = BR.pool_model(p)
        bi = BR.band_choice(pool, level, arena, seen, story)
        b = pool['bands'][bi]
        rows = [(eid, self.mate_label(ref), pct)
                for (eid, pct), ref in zip(BR.mate_chances(b),
                                           [m.get('enemy') for m in p['bands'][bi]['mates']])]
        return bi, b['name'], rows

    def breeder_options(self, sid):
        """The breeder's options with its words as boxes:
        {mate, pool, intro, not_yet, after (boxes or None), when, once, flag}."""
        s = self.service_script(sid)
        if s is None or s['service'].get('kind') != 'breeder':
            return None
        sv = s['service']
        out = {k: sv.get(k) for k in ('mate', 'pool', 'once', 'flag')}
        out['when'] = [dict(t) for t in sv.get('when') or []]
        for k in TEXT_KEYS:
            out[k] = None
            for d in self.custom.get('dialogue', []):
                if d.get('id') == sv.get(k):
                    out[k] = [list(b) for b in d.get('boxes') or []]
        return out

    # ------------------------------------------------------------ editing
    def set_breeder_options(self, sid, mate=None, pool=None, intro=None, when=None,
                            not_yet=None, once=False, flag=None, after=None):
        """A breeder's mate (an enemy row / project enemy id, or {"species", "level"}
        — S127 r2: a project enemy is made for it, mate_for) OR pool; its words
        (boxes [[line, line], …] or None — boxes too long for the game's box are
        word-wrapped, fit_boxes): intro (before the question), not_yet (while `when`
        does not hold), after (a done breeding with `once`, or this appearance's for
        a random breeder); when [{flag, is}]; once + flag."""
        s = self.service_script(sid)
        if s is None or s['service'].get('kind') != 'breeder':
            raise ValueError(f'{sid!r} is not a breeder')
        if (mate is None) == (pool is None):
            raise ValueError('a breeder offers ONE monster (a mate) or one from a pool')
        intro, not_yet, after = (fit_boxes(b) or None for b in (intro, not_yet, after))
        if isinstance(mate, dict):
            mate = self.mate_for(mate['species'], mate['level'])
        if pool is not None:
            self._pool(pool)
        if once and not flag:
            raise ValueError("'once' needs a flag (it remembers the breeding)")
        sv = s['service']
        for k in ('mate', 'pool', 'when', 'once', 'flag'):
            sv.pop(k, None)
        if mate is not None:
            sv['mate'] = mate
        else:
            sv['pool'] = pool
        if when:
            sv['when'] = [{'flag': t['flag'], 'is': t.get('is', 'set')} for t in when]
            for t in when:
                if not any(f.get('name') == t['flag'] for f in self.flags()) and \
                        not str(t['flag']).startswith(('0x', '$', 'gate:', 'hook:')):
                    self.add_flag(t['flag'], 'a breeder waits for it')
        if flag:
            sv['flag'] = flag
            if not any(f.get('name') == flag for f in self.flags()):
                self.add_flag(flag, 'a breeding with this NPC is done')
        if once:
            sv['once'] = True
        for k, boxes in (('intro', intro), ('not_yet', not_yet), ('after', after)):
            old = sv.pop(k, None)
            if old:
                self.custom['dialogue'] = [d for d in self.custom.get('dialogue', [])
                                           if d.get('id') != old]
            if boxes:
                sv[k] = self._talk_entry(f'{sid}_{k}', boxes)
        self.touch()

    def add_breeding_pool(self, name='Breeding pool'):
        """A new pool: one band (level 10) offering CatFly (row 306). Returns its id."""
        lst = self.custom.setdefault('breeding_pools', [])
        pid = self._unique_id(self._slug(name) or 'pool', {p.get('id') for p in lst})
        lst.append({'id': pid, 'name': str(name).strip() or pid, 'measures': ['level'],
                    'bands': [{'name': 'band 1', 'level': 10,
                               'mates': [{'enemy': 306, 'weight': 1}]}]})
        self.touch()
        return pid

    def set_breeding_pool(self, pid, name=None, measures=None, milestones=None, bands=None):
        """Change a pool (only the given fields). Checked by the compiler's own
        rules (breeders.pools) before it is kept."""
        p = self._pool(pid)
        new = dict(p)
        if name is not None:
            new['name'] = str(name).strip() or pid
        if measures is not None:
            new['measures'] = [m for m in BR.MEASURES if m in measures]
        if milestones is not None:
            if milestones:
                new['milestones'] = list(milestones)
            else:
                new.pop('milestones', None)
        if bands is not None:
            new['bands'] = [dict(b) for b in bands]
        BR.check_pool(self, new)               # raises BreedError with the reason
        for f in new.get('milestones') or []:
            if not any(x.get('name') == f for x in self.flags()) and \
                    not str(f).startswith(('0x', '$', 'gate:', 'hook:')):
                self.add_flag(f, 'a story milestone of a breeding pool')
        p.clear()
        p.update(new)
        self.touch()

    def delete_breeding_pool(self, pid):
        p = self._pool(pid)
        users = [s['id'] for s in self.custom.get('scripts', [])
                 if isinstance(s.get('service'), dict) and s['service'].get('pool') == pid]
        if users:
            raise ValueError(f'the pool is in use by {", ".join(users)}')
        self.custom['breeding_pools'].remove(p)
        if not self.custom['breeding_pools']:
            self.custom.pop('breeding_pools')
        self.touch()
