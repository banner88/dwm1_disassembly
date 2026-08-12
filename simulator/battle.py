"""DWM1 combat-simulator ROUND CORE (S79) — assembles the differentially
validated components into a playable round loop:

  turn_order.round_order   (143/143 exact vs engine, S79)
  damage.*                 (698/698 S78 + the S79 additions: slot-2 x0.8,
                            RainSlash sweep, sacrifice(), link-vs-arena
                            fork corrections)
  status.*                 (sleep wake exact vs $53:$4AEB; byte map
                            measured per-skill)

HONESTY NOTE: the components are engine-exact; the LOOP GLUE (this file)
is assembled from the traced sequencing (phases 5/7/9, bank $53 entry 0's
gate order) but has NOT itself been differentially validated action-by-
action against a full engine battle.  That end-to-end replay is the S80
box, together with AI (this core takes explicit action policies per side,
which is what the randomizer/pacing sweeps need).

Not modelled yet (S80): enemy AI selection + arena tactics, MISS/dodge
timers ($DA33 interplay), the $DB07 timer statuses, meta-actions (flee,
items, shift), MP charging, PsycheUp's damage carry-over, interception
skills' redirect effects (they only affect ordering here).
"""
from dataclasses import dataclass, field
from . import damage as D
from . import turn_order as T
from . import status as S

ATTACK = 0x3A


@dataclass
class Combatant:
    slot: int                 # 0-2 party, 4-6 enemy
    hp: int
    maxhp: int
    atk: int
    dfn: int
    agl: int
    level: int = 1
    mp: int = 0
    res7: bytes = b'\x00' * 7   # packed resistance block ($DD28 layout)
    st2: int = 0                # status block byte +2
    st3: int = 0                # byte +3
    st5: int = 0                # byte +5 (ladder bits / one-shots)

    @property
    def alive(self):
        return self.hp > 0

    @property
    def enemy_side(self):
        return bool(self.slot & 4)


@dataclass
class Battle:
    combatants: dict          # slot -> Combatant
    state: int                # RNG state16
    db73: int = 1             # battle type: 0 wild / 1 boss / 2 arena
    link: bool = False        # $C86C
    log: list = field(default_factory=list)

    def alive_slots(self):
        return {s for s, c in self.combatants.items() if c.alive}

    # ---------------- one round ----------------
    def run_round(self, actions):
        """actions: dict slot -> (action_id, target_slot). Only combatants
        present in `actions` are 'ready' ($DD13==2). Executes phase 5
        (order), per-actor phase 7 (gates + damage + apply), then the
        phase-9 end-of-round DoT. Returns the acted order."""
        ready = [(s, self.combatants[s].agl, actions[s][0])
                 for s in sorted(actions) if self.combatants[s].alive]
        order, entries, self.state = T.round_order(ready, self.state)
        for slot in order:
            c = self.combatants.get(slot)
            if c is None or not c.alive:
                continue                      # bank $53 $4549 skip
            act, tgt = actions[slot]
            act, tgt = self._turn_gates(c, act, tgt)
            if act is None:
                continue
            self._execute(c, act, tgt)
        self._end_of_round_dot()
        return order

    # ------------- bank $53 entry 0's gate order -------------
    def _turn_gates(self, c, act, tgt):
        if c.st2 & S.PARALYZE:
            self.log.append((c.slot, 'paralyzed'))
            return None, None
        if c.st2 & S.ASLEEP:
            c.st2, awake = S.sleep_wake(c.st2, self.state)
            if not awake:
                self.log.append((c.slot, 'asleep'))
                return None, None
            self.log.append((c.slot, 'woke'))
        if c.st5 & 0x3F:                      # one-shot compulsion
            self.log.append((c.slot, 'compelled', c.st5 & 0x3F))
            c.st5 &= 0xC0
            return None, None
        if c.st2 & S.CURSE and S.curse_triggers(self.state):
            hurt = max(c.maxhp >> 3, 1)       # approx: entry-2 magnitude
            c.hp = max(c.hp - hurt, 0)        # NOT yet measured — S80
            self.log.append((c.slot, 'curse', hurt))
            return None, None
        if c.st2 & S.CONFUSION:
            act, t2 = S.confusion_action(self.state, c.slot,
                                         self.alive_slots())
            if t2 is not None:
                tgt = t2
            self.log.append((c.slot, 'confused', act, tgt))
            if act != ATTACK:
                return None, None             # non-attack picks: S80
        return act, tgt

    # ------------- action execution (validated damage models) -------------
    def _execute(self, c, act, tgt):
        t = self.combatants.get(tgt)
        if t is None or not t.alive:
            return
        if D.boss_gate_blocks(act, t.enemy_side, self.db73):
            self.log.append((c.slot, 'boss-blocked', act))
            return
        if act == ATTACK or act == 0x55:      # plain attack / SquallHit
            dmg, self.state = D.calc_skill_defense(
                c.atk, t.dfn, self.state, target_idx=tgt, arena=self.link)
            if act == 0x55:
                dmg = (dmg * 8) // 10
        elif act == 0x14:                     # Sacrifice
            res = D.res_level(t.res7, 14)
            dmg, killed, worked = D.sacrifice(t.hp, self.state, res,
                                              self.db73)
            c.hp = 0                          # caster dies either way
        elif act == 0x3E:                     # Kamikaze
            dmg = D.kamikaze_damage(c.hp, t.hp, link=self.link,
                                    db73=self.db73)
            c.hp = 0
        else:
            raise NotImplementedError(
                f'action {act:#x}: use the specific damage.py model '
                f'(record spells via record_roll + ladders, specials via '
                f'their functions) — wired per-skill in S80')
        t.hp = max(t.hp - dmg, 0)
        self.log.append((c.slot, 'hit', tgt, dmg))

    # ------------- battle phase 9 -------------
    def _end_of_round_dot(self):
        for s in sorted(self.combatants):
            c = self.combatants[s]
            if not c.alive:
                continue
            if c.st2 & S.POISON:
                d = S.poison_tick(c.maxhp, self.state)
                c.hp = max(c.hp - d, 0)
                self.log.append((s, 'poison', d))
            if c.st2 & S.HEAVY_DOT:
                d = S.heavy_dot_tick(c.maxhp, self.state)
                c.hp = max(c.hp - d, 0)
                self.log.append((s, 'heavy-dot', d))

    def side_wiped(self):
        party = any(c.alive for s, c in self.combatants.items() if s < 4)
        enemy = any(c.alive for s, c in self.combatants.items() if s >= 4)
        return (not party), (not enemy)
