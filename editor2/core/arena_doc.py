"""arena_doc.py — the Arena tab's document model (ROADMAP P3.10b, S109;
EDITOR_DESIGN §5.2b; compiler side: editor2/core/arena.py, PROJECT_COMPILER
§2.25).

Reads and writes `gamedata.arena` (class fees, the master of each match, team
sizes) and, for the team members, the existing `gamedata.enemies` rows (the
arena teams ARE enemy-stats rows: EID = $E0 + 9*group + 3*match + slot; the
King $01E1-$01E3) through MonstersMixin.set_enemy_fields. The project stores
only differences from the original game: a value set back to the original
removes its key (and any object it leaves empty). Every setter validates with
the compiler's own models before it is kept.
"""

import copy

from editor2.core import arena as AR
from editor2.core import monsters as M

# What winning each class does — Arena Lobby script 0, the per-class victory
# cascade (decoded S67; SIDEQUEST_MAP "Per-class VICTORY cascade"). Read-only
# here: event flags are the Progression & Flags tab's (ROADMAP P3.14).
VICTORY = {
    0: ['flag $0030 (G class won)', 'arena progress $CAB4 := 1',
        'world steps $D92B=0 $D92F=2 $D931=1 $D93C=3 $D941=1'],
    1: ['flag $0031 (F class won)', 'arena progress $CAB4 := 2',
        'world steps $D92F=3 $D931=2 $D933=1 $D93C=4 $D952-$D954=1'],
    2: ['flag $0032 (E class won) + catch-up $0031, $0049', 'arena progress $CAB4 := 3',
        'world steps $D93B=1 $D942=1'],
    3: ['flags $0031 $0032 $0033 (D class won; + $0119 if E was never seen)',
        'arena progress $CAB4 := 4',
        'world steps $D92B=0 $D92F=3 $D931=2 $D933=1 $D93B=2 $D93C=4 $D942=1 $D952-$D954=1'],
    4: ['flag $0034 (C class won)', 'arena progress $CAB4 := 5', 'world steps $D93B=3'],
    5: ['flag $0035 (B class won) + catch-up $0034', 'arena progress $CAB4 := 6',
        'world steps $D939=1 $D93D=1 $D945=1 $D946=1 $D947=2 $D963=1 $D964=1'],
    6: ['flag $0036 (A class won) + catch-ups $0035 $0034', 'arena progress $CAB4 := 7',
        'world steps $D93D=2'],
    7: ['flags $0034-$0037 (S class won; + $011C if A was never seen)',
        'arena progress $CAB4 := 8',
        'world steps $D92B=0 $D936-$D938=2 $D939=2 $D93B=3 $D93D=3 $D945/6=1 $D947=2 $D963/4=1'],
    8: ['Starry Night: the phase counter $D999 runs 1 -> 2 -> 3 over the three matches; '
        'flag $00F1 (Starry Night won) is set later at the Castle (Castle script 0)'],
    9: ['flag $0110 when the match starts, $0111 when the King is beaten '
        '(the Arena Battle room script)'],
}
# $CAB4 also scales the chest Mimics (opcode $36: EIDs 317-324 by tier).


class ArenaMixin:
    # ------------------------------------------------------------ reading
    def arena_resolved(self):
        return AR.resolve(self.data, getattr(self, 'repo_root', None))

    def arena_groups(self):
        """[{gi, key, label, fee (None for Starry / King), fee_edited, matches}]"""
        r = self.arena_resolved()
        out = []
        for gi, key in enumerate(AR.GROUPS):
            out.append({'gi': gi, 'key': key, 'label': AR.group_label(gi),
                        'fee': r['fees'][gi] if gi < 8 else None,
                        'fee_edited': gi in r['edited']['fees'],
                        'matches': AR.matches(gi)})
        return out

    def arena_match(self, gi, m, model=None):
        """{size, size_edited, master (draw, is_monster), master_edited, slots:
        [{slot, eid, fields, edited, fights}]} for match m of group gi."""
        r = self.arena_resolved()
        g, _new = model or self.monsters_model()
        vrows = M.G._rows(M.G.vanilla(M.REPO), 'enemy_stats')
        i = AR.index(gi, m)
        slots = []
        for s in range(3):
            e = AR.eid(gi, m, s)
            slots.append({'slot': s, 'eid': e, 'fields': M.decode_enemy(g.enemy[e]),
                          'edited': bytes(g.enemy[e]) != bytes(vrows[e]),
                          'fights': s < r['sizes'][i]})
        return {'size': r['sizes'][i], 'size_edited': i in r['edited']['sizes'],
                'master': r['masters'][i], 'master_edited': i in r['edited']['masters'],
                'slots': slots}

    def arena_vanilla_master(self, gi, m):
        return AR.vanilla(getattr(self, 'repo_root', None))['masters'][AR.index(gi, m)]

    def arena_fee_vanilla(self, gi):
        return AR.vanilla(getattr(self, 'repo_root', None))['fees'][gi]

    # ------------------------------------------------------------ writing
    def _arena_write(self, mutate):
        data = copy.deepcopy(self.data)
        gd = data.setdefault('gamedata', {})
        ar = gd.setdefault('arena', {})
        mutate(ar)
        # prune empty objects (sparse: only differences are stored)
        for key in list(ar):
            if str(key).startswith('_'):
                continue
            e = ar[key]
            ms = e.get('matches')
            if isinstance(ms, dict):
                for mk in list(ms):
                    if not ms[mk]:
                        ms.pop(mk)
                if not ms:
                    e.pop('matches')
            if not e:
                ar.pop(key)
        if not ar:
            gd.pop('arena')
        if not gd:
            data.pop('gamedata')
        AR.resolve(data, getattr(self, 'repo_root', None))     # raises ArenaError
        self._commit_data(data)

    def set_arena_fee(self, gi, fee):
        gi = int(gi)
        if gi >= 8:
            raise AR.ArenaError('only the classes G-S have an entry fee')
        fee = int(fee)
        key = AR.GROUPS[gi]
        van = self.arena_fee_vanilla(gi)

        def mut(ar):
            e = ar.setdefault(key, {})
            if fee == van:
                e.pop('fee', None)
            else:
                e['fee'] = fee
        self._arena_write(mut)

    def set_arena_size(self, gi, m, n):
        gi, m, n = int(gi), int(m), int(n)
        key = AR.GROUPS[gi]

        def mut(ar):
            me = ar.setdefault(key, {}).setdefault('matches', {}).setdefault(str(m), {})
            if n == 3:
                me.pop('size', None)
            else:
                me['size'] = n
        self._arena_write(mut)

    def set_arena_master(self, gi, m, spec):
        """spec = {'person': id} | {'monster': species} | None (the original)."""
        gi, m = int(gi), int(m)
        key = AR.GROUPS[gi]
        van = self.arena_vanilla_master(gi, m)

        def mut(ar):
            me = ar.setdefault(key, {}).setdefault('matches', {}).setdefault(str(m), {})
            if spec is None:
                me.pop('master', None)
                return
            pair = AR.master_value(spec, f'arena {key} match {m + 1} master',
                                   AR._new_species(self.data),
                                   getattr(self, 'repo_root', None))
            if pair == van:
                me.pop('master', None)
            else:
                me['master'] = AR.master_spec(pair)
        self._arena_write(mut)

    def reset_arena_match(self, gi, m):
        """Team size and master back to the original; the three enemy rows too."""
        gi, m = int(gi), int(m)
        key = AR.GROUPS[gi]
        data = copy.deepcopy(self.data)
        gd = data.get('gamedata') or {}
        ens = gd.get('enemies') or {}
        for s in range(3):
            ens.pop(str(AR.eid(gi, m, s)), None)
        if 'enemies' in gd and not ens:
            gd.pop('enemies')
        ar = gd.get('arena') or {}
        ms = (ar.get(key) or {}).get('matches') or {}
        ms.pop(str(m), None)
        if key in ar and 'matches' in ar[key] and not ms:
            ar[key].pop('matches')
        if key in ar and not ar[key]:
            ar.pop(key)
        if 'arena' in gd and not ar:
            gd.pop('arena')
        if 'gamedata' in data and not gd:
            data.pop('gamedata')
        self._commit_data(data)
