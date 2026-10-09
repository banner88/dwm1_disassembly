"""hub_doc.py — editing the project's hub (S125, ROADMAP P3.14d; PROJECT_COMPILER §2.38).

Headless Document mixin (no Qt). The hub is where the game sends the player home:
after a lost battle, when the party falls on damage floors, with the WarpWing item
or the Anchor skill's gate exit, after a lost Starry Night final, and when a
conversation / cutscene moves the player to "the hub". `custom.hub.rules[]` are
tried in list order; the first whose flags all hold is the hub; none (or no
rules) = the original game's Castle. A rule's room is a custom room ("castle" =
the Castle, with its own priest / King arrival). The hub room's ARRIVAL scenes
(an entry cutscene with `trigger.arrival`) play for the reasons they list; a
reason no scene takes heals the party (the Castle's priest does too).
"""

import copy

from editor2.core import cutscene_build as CB
from editor2.core import cutscene_doc as CD
from editor2.core.formats import val

CASTLE = 'castle'
# default arrival scenes (Add the arrival scenes): (name, reasons, boxes, heal)
DEFAULT_ARRIVALS = (
    ('Back after a loss', ['lost', 'wiped', 'final_lost'],
     [['You lost...', 'Rest here.'], ['Your monsters', 'are healed.']], True),
    ('Back by WarpWing', ['warpwing'],
     [['The WarpWing has', 'flown you home.']], True),
    ('Sent home', ['home'], [['Welcome home!']], False),
    # S138 (ARC CAP2e): CONTINUE of a save made in a room this build no longer has
    ('Back from an old save', ['continue'],
     [['Your saved place', 'is gone now.'], ['You are home.', 'Rest a while.']], True),
)


class HubMixin:
    def hub_rules(self):
        """custom.hub.rules (a copy; [] = no hub: the Castle, as in the game)."""
        return copy.deepcopy((self.custom.get('hub') or {}).get('rules') or [])

    def _rule(self, rule):
        """A rule as stored: {when?, room, screen, x, y, comment?}."""
        rule = dict(rule)
        out = {}
        when = [{'flag': t['flag'], **({'is': 'clear'} if t.get('is') == 'clear' else {})}
                for t in rule.get('when') or [] if t.get('flag') not in (None, '')]
        if when:
            out['when'] = when
        room = rule.get('room')
        if room == CASTLE:
            out['room'] = CASTLE
        else:
            r = self.room(room)                       # KeyError when no such room
            k = int(rule.get('screen', 0))
            if str(k) not in (r.get('screens') or {}):
                raise ValueError(f'{self.room_name(r)} has no screen {k}')
            x, y = int(rule['x']), int(rule['y'])
            if not (0 <= x <= 9 and 0 <= y <= 7):
                raise ValueError(f'cell ({x},{y}) is outside the screen')
            out.update(room=r['id'], screen=k, x=x, y=y)
        if rule.get('comment'):
            out['comment'] = str(rule['comment'])
        return out

    def set_hub_rules(self, rules):
        rules = [self._rule(r) for r in rules]
        if rules:
            h = self.custom.setdefault('hub', {})
            h['rules'] = rules
        else:
            self.custom.pop('hub', None)
        self.touch()
        return copy.deepcopy(rules)

    def add_hub_rule(self, rule, index=None):
        """Add a rule (at the end, or before `index`). -> its index."""
        rules = self.hub_rules()
        i = len(rules) if index is None else max(0, min(int(index), len(rules)))
        rules.insert(i, rule)
        self.set_hub_rules(rules)
        return i

    def update_hub_rule(self, i, rule):
        rules = self.hub_rules()
        rules[int(i)] = rule
        self.set_hub_rules(rules)

    def remove_hub_rule(self, i):
        rules = self.hub_rules()
        del rules[int(i)]
        self.set_hub_rules(rules)

    def move_hub_rule(self, i, d):
        """Move rule i up (d=-1) / down (d=+1). -> its new index."""
        rules = self.hub_rules()
        j = int(i) + int(d)
        if not (0 <= int(i) < len(rules) and 0 <= j < len(rules)):
            return int(i)
        rules[i], rules[j] = rules[j], rules[i]
        self.set_hub_rules(rules)
        return j

    def hub_room_ids(self):
        """The custom rooms a rule sends the player to."""
        return {r.get('room') for r in self.hub_rules() if r.get('room') != CASTLE}

    def hub_rules_of_room(self, room_id):
        return [(i, r) for i, r in enumerate(self.hub_rules()) if r.get('room') == room_id]

    def hub_rule_text(self, rule):
        """One readable line: 'while tutorial_done is OFF → HUB HALL, screen 0 (4,5)'."""
        terms = rule.get('when') or []
        cond = (' and '.join(f"{t['flag']} is {'OFF' if t.get('is') == 'clear' else 'ON'}"
                             for t in terms) if terms else 'otherwise (always)')
        if terms:
            cond = 'while ' + cond
        if rule.get('room') == CASTLE:
            where = 'the Castle (the original game: the priest heals)'
        else:
            try:
                r = self.room(rule.get('room'))
                where = (f"{self.room_name(r)} (${val(r['mapID']):02X}), screen "
                         f"{rule.get('screen', 0)} ({rule.get('x')},{rule.get('y')})")
            except KeyError:
                where = f"room {rule.get('room')!r} (deleted)"
        return f'{cond} → {where}'

    def hub_problems(self):
        """Sentences (the World tab shows them before Build stops on them)."""
        out = []
        rules = self.hub_rules()
        for i, ru in enumerate(rules):
            if i and not rules[i - 1].get('when'):
                out.append(f'rule {i + 1} never applies: rule {i} has no conditions '
                           '(move the rule with no conditions to the end)')
            if ru.get('room') == CASTLE:
                continue
            try:
                r = self.room(ru.get('room'))
            except KeyError:
                out.append(f"rule {i + 1}: the room {ru.get('room')!r} was deleted")
                continue
            if str(ru.get('screen', 0)) not in (r.get('screens') or {}):
                out.append(f"rule {i + 1}: {self.room_name(r)} has no screen {ru.get('screen')}")
        for rid in sorted(self.hub_room_ids()):
            try:
                r = self.room(rid)
            except KeyError:
                continue
            for sc in r.get('cutscenes') or []:
                tr = sc.get('trigger') or {}
                if tr.get('arrival') and int(sc.get('screen', 0)) not in {
                        int(ru.get('screen', 0)) for _i, ru in self.hub_rules_of_room(rid)}:
                    out.append(f"{self.room_name(r)}: the arrival scene “{sc.get('name') or sc['id']}” "
                               f"is on screen {sc.get('screen', 0)}, where no hub rule lands "
                               '— it never plays')
        for r in self.rooms:
            if r.get('id') in self.hub_room_ids():
                continue
            for sc in r.get('cutscenes') or []:
                if (sc.get('trigger') or {}).get('arrival'):
                    out.append(f"{self.room_name(r)} is not a hub room: its arrival scene "
                               f"“{sc.get('name') or sc['id']}” never plays")
        return out

    def hub_arrival_scenes(self, room_id):
        """[(scene id, name, reasons)] of a room."""
        r = self.room(room_id)
        return [(sc['id'], sc.get('name') or sc['id'], list((sc.get('trigger') or {})['arrival']))
                for sc in r.get('cutscenes') or [] if (sc.get('trigger') or {}).get('arrival')]

    def add_arrival_scenes(self, room_id):
        """The three default arrival scenes on the room's hub screen (a loss: a line +
        heal; the WarpWing: a line + heal; a script: a line) — the reasons a scene of
        the room already takes are skipped. -> the new scene ids."""
        r = self.room(room_id)
        rules = self.hub_rules_of_room(room_id)
        k = int(rules[0][1].get('screen', 0)) if rules else 0
        x, y = (int(rules[0][1].get('x', 4)), int(rules[0][1].get('y', 4))) if rules else (4, 4)
        taken = {a for _s, _n, rs in self.hub_arrival_scenes(room_id) for a in rs}
        out = []
        for name, reasons, boxes, heal in DEFAULT_ARRIVALS:
            reasons = [a for a in reasons if a not in taken]
            if not reasons:
                continue
            sid = CD.new_cutscene(self, room_id, name, k, 'entry')
            _r, sc = CD.find(self, sid)
            sc['trigger']['arrival'] = reasons
            sc['player_start'] = {'x': x, 'y': y, 'face': 'down'}
            sc['steps'] = [{'say': {'boxes': copy.deepcopy(boxes)}}] + (
                [{'heal': {}}] if heal else [])
            out.append(sid)
        self.touch()
        return out


def arrival_names():
    """[(reason, sentence)] in the editor's order."""
    return [(a, CB.ARRIVAL_NAMES[a]) for a in CB.ARRIVALS]
