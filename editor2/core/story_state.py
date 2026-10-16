"""story_state.py — the game's saved state at a story point (S132; no Qt).

User S132: Play here with flags + monsters "generated according to thresholds
(ie have a vanilla slide scale you can put yourself on, and ideally make a
separate slide scale for romhack)"; the romhack scale "follow gates naturally.
Just like balance tab". A story point = a step of the Balance timeline
(`balance.VANILLA_STEPS`: 31 gates, the arena classes G-S, Starry Night,
Monster Grandpa — the game's order, FULL_FAQ). "At step N" = the player is
about to do step N: steps 0..N-1 are done.

The state is not transcribed from a walkthrough: it is what the GAME'S OWN
SCRIPTS write, run by a small interpreter over the decoded scripts
(`cutscenes.decode_words` — flag ops `$00-$03`, RAM writes `$12` / `$13`,
`$14` goto, `$15` RAM test, `$0E` screen test; every other op is stepped over;
a text / battle / walk changes no saved state):

  a gate done   = its boss win tail(s) (`extracted/gate_names.json`
                  `win_tails`: bank / start — the step counters of the boss room
                  and the gate's "Room of", paired-gate branches) with the
                  gate's cleared flag(s) set first, then the King's speech the
                  boss room asked for (`$D9E3` := the code the boss script writes
                  right before its tail, `$D92B` := 7, Castle script 0 on screen
                  1 — e.g. speech $30 sets $0009 "go to the arena" and opens
                  the Gate Hub doors);
  a class won   = Arena Lobby script 0 on screen 1 with `wColiseumBattle`
                  ($D9CD) = $FE and `wArenaGroup` ($D9CE) = the class — the
                  victory cascade (rank flag + catch-ups, `$CAB4`, the world
                  step counters; SIDEQUEST_MAP "Per-class VICTORY cascade");
  Starry Night  = the ending flag $00EE, then the Castle's cascade sets the
                  post-game ($00F1, `$D92B` 5 …).

Measured against PyBoy (tools/census_story_state.py): the RAM and flags the
real scripts leave equal the interpreter's for the sampled steps.

`state_at(step, repo)` -> {'flags_on': sorted ints, 'ram': {addr: byte},
'log': [what ran]}. A project adds `project_flags(prj, step)`: the cleared
flags of its own / re-bossed gates (`$17A0 + gate`, GATE_GENERATION §7.9)
done by then — a NEW gate counts as done right after the vanilla gate it was
copied from (`copy_of`), the way the Balance tab places it.
"""

import json
import os

from . import cutscenes as CS
from . import script_ops as SO

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

COLISEUM, ARENA_GROUP = 0xD9CD, 0xD9CE
CASTLE_EVENT, KING_CODE = 0xD92B, 0xD9E3
ARENA_TIER = 0xCAB4
ARENA_LOBBY, CASTLE = 0x06, 0x00
ENDING_SEEN = 0x00EE
GATE_OWN_FLAG = 0x17A0                   # + gate: a project gate's cleared flag
STATE_RAM = (0xD92A, 0xD99A)             # the step counters (saved)
KEEP_RAM = {ARENA_TIER, KING_CODE}       # other saved bytes the scripts write


def _vn(mid):
    """S143 (ARC CAP4b): a game room in words (place_names)."""
    from editor2.core import place_names as PN
    return PN.with_id(PN.vanilla_name(mid), mid, True)


class Machine:
    """Saved state the scripts change: flags (a set) and RAM bytes."""

    def __init__(self, flags=(), ram=None):
        self.flags = set(flags)
        self.ram = dict(ram or {})
        self.log = []

    def test(self, lit, screen):
        kind = lit[0]
        if kind == 'flag':
            return (lit[1] in self.flags) == lit[2]
        if kind == 'screen':
            return (screen == lit[1]) == lit[2]
        if kind == 'ram':
            return (self.ram.get(lit[1], 0) == lit[2]) == lit[3]
        return not lit[2]                    # anything else: the fall-through

    def run(self, script, pos=0, screen=0, limit=4000, what=''):
        """Run `script` from pos: apply its state ops, follow its branches.
        A script that ends by changing room (`$0F` / `$3B`) leaves
        self.warp = (map, screen) — the game runs that room's entry script
        next (follow it with `follow()`)."""
        n = 0
        self.warp = None
        while pos is not None and pos in script.steps and n < limit:
            n += 1
            st = script.steps[pos]
            c, p = st.code, st.params
            if c in (0x0F, 0x3B):
                mp, x, y = p[0] & 0xFF, p[1], p[2]
                if not (p[0] >> 8):                  # a gate flag = a gate, not a room
                    self.warp = (mp, (y // 128) * 4 + (x // 160))
            if c == 0x02:
                self.flags.discard(p[0])
            elif c == 0x03:
                self.flags.add(p[0])
            elif c == 0x12:
                self.ram[p[0]] = p[1] & 0xFF
            elif c == 0x13:
                self.ram[p[0]] = p[1] & 0xFF
                self.ram[p[0] + 1] = (p[1] >> 8) & 0xFF
            succ = script.successors(st)
            if not succ:
                break
            nxt = None
            for q, lit in succ:
                if lit is None or self.test(lit, screen):
                    nxt = q
                    break
            pos = nxt
        if what:
            self.log.append(what)
        return self

    def saved(self):
        """The part a player's game keeps: flags < $1800 and the RAM above."""
        lo, hi = STATE_RAM
        ram = {a: v for a, v in self.ram.items()
               if lo <= a <= hi or a in KEEP_RAM}
        return {'flags_on': sorted(f for f in self.flags if f < 0x1800), 'ram': ram}


# ---------------------------------------------------------------- the game
_ROM = {}


def _rom(repo):
    if repo not in _ROM:
        _ROM[repo] = open(os.path.join(repo, 'data', 'DWM-original.gbc'), 'rb').read()
    return _ROM[repo]


def _gates(repo):
    return json.load(open(os.path.join(repo, 'extracted', 'gate_names.json')))['gates']


def _script_at(rom, bank, start):
    def read(a):
        if not 0x4000 <= a <= 0x7FFE:
            return None
        o = bank * 0x4000 + a - 0x4000
        return rom[o] | rom[o + 1] << 8
    return CS.Script(('tail', bank, start), CS.decode_words(read, start), bank, start)


def king_code(rom, bank, start, back=0x60):
    """The `$12 $D9E3 code` write right before a win tail (the boss script
    asks the Castle for its speech): the last one in the `back` bytes before."""
    base = bank * 0x4000 - 0x4000
    lo = max(0x4000, start - back)
    seg = rom[base + lo: base + start]
    k = seg.rfind(bytes([0x12, 0xFF, 0xE3, 0xD9]))
    if k < 0:
        return None
    return seg[k + 4]


def follow(mach, rom, hops=3):
    """After a script that changed room: the destination's entry script
    (script 0 of that map type) on the arrival screen — e.g. the Castle's
    story cascade after a class win, the King's speech after a boss."""
    for _ in range(hops):
        if mach.warp is None:
            return
        mp, scr = mach.warp
        try:
            sc = CS.decode_vanilla(rom, mp, 0)
        except Exception:                                        # noqa: BLE001
            return
        mach.run(sc, 0, screen=scr, what=f'  then {_vn(mp)} screen {scr}: its entry script')


def run_gate(mach, rom, gate):
    """A vanilla gate's boss beaten: cleared flag(s), the win tail(s) and
    where it sends the player (the Castle: the King's speech)."""
    for wt in gate.get('win_tails') or []:
        bank, start = int(wt['bank'], 16), int(wt['start'], 16)
        mach.flags.add(int(wt['flag'], 16))
        code = king_code(rom, bank, start)
        if code is not None:                 # written by the boss script before the tail
            mach.ram[KING_CODE] = code
            mach.ram[CASTLE_EVENT] = 7
        mach.run(_script_at(rom, bank, start), 0, what=f"{gate['name']}: win tail "
                 f"${bank:02X}:{start:04X} (flag ${int(wt['flag'], 16):04X})")
        follow(mach, rom)
    for f in gate.get('cleared_flags') or []:
        mach.flags.add(int(f, 16))


def run_class(mach, rom, lobby_scr0, cls):
    mach.ram[COLISEUM] = 0xFE
    mach.ram[ARENA_GROUP] = cls
    mach.run(lobby_scr0, 0, screen=1, what=f"arena class {'GFEDCBAS'[cls]} won")
    follow(mach, rom)
    mach.ram[COLISEUM] = 0


ENDING_FARM_FLAG = 0x00E5               # the Farm's script 0, after its op $3E (S144 traced; S148 decoded)
BREED_STAGE = 0xD951                    # the ceremony room's counter (BANK04 "Breeding")


def run_ending(mach, rom, castle_scr0=None):
    """Starry Night won → the post-game — the game's own ending, MEASURED S144 (PyBoy on
    the original ROM from this model's "about to do Starry Night", every step played:
    PYBOY_DEBUGGING S144; before S144 this set $00EE and ran the King's cascade only,
    which left 8 flags and 11 rooms' states out — the Bazaar's right half, the Gate Hub,
    the Farm, the Stable, Arena Rooms, MedalMan, the Queen, the bedroom, the ceremony
    room, the white room — KEY_LESSONS S144):

      the final's win tail (Arena Battle script 0, wArenaGroup 8, the 3rd match won:
      $00E4, the night Farm's states, game mode 3) → the night Farm's entry scene
      sets $00E5 after its op $3E (S148: decoded — the script resumes after the
      mode change) → the Farm NPC's talk (script 19, YES) → the Starry Shrine → the
      ceremony room ($08: $D951 := 7 by op $5E; its sky sequence, bank $02 entry 3
      via bank $01 CheckPaletteAnimActive, ends with $D951 := 8 + a reload — bank $02
      CeremonySkyDone) → the white room ($5E: $D99A) → the bedroom's screen
      4 ($00E9) → the dresser (bedroom script 10: $00EA) → the bedroom's question, YES
      ($00EB) → its step-on trigger (script 13: $00ED, the credits = game mode 4) →
      the bedroom again ($00EE + the post-game states of 18 rooms) → "TO BE CONTINUED"
      → the game SAVES there (bank $5F mode 4, a button + YES: SaveGameState — the
      only save of the ending) → CONTINUE: the bedroom ($00EF), its screen 5 ($00F0),
      the dresser → the ceremony room → GreatTree → the Castle: the King's cascade
      ($00F1, the Castle / GreatTree post-game states)."""
    from . import cutscenes as _CS
    sc = lambda m, i: _CS.decode_vanilla(rom, m, i)
    mach.ram[ARENA_GROUP] = 8
    mach.ram[COLISEUM] = 3
    mach.run(sc(0x5D, 0), 0, screen=0, what="Starry Night won: the final's win tail")
    mach.ram[COLISEUM] = 0
    # S148: the night Farm's entry scene (script 0 on screen 1: $00E4 on, $00E5 /
    # $00EE off) runs on through its op $3E (the night sky — the script RESUMES when
    # the mode returns) and sets $00E5 — decoded now (was added by hand S144-S147,
    # when the decoder ended scripts at $3E)
    mach.run(sc(0x04, 0), 0, screen=1, what='  the night Farm: its entry scene ($00E5)')
    assert ENDING_FARM_FLAG in mach.flags, 'the night Farm\'s scene no longer sets $00E5'
    mach.run(sc(0x04, 19), 0, screen=2, what='  the night Farm: the talk, YES')
    follow(mach, rom, hops=4)
    if mach.ram.get(BREED_STAGE) == 7:
        # the ceremony room's first scene ends (END at word $1B1 of its script 0); its
        # sky sequence (bank $02 entry 3, CeremonySkyDone) then sets $D951 := 8 and
        # reloads the room: script 0 again — $D99A := 3, the fade to the white room
        mach.ram[BREED_STAGE] = 8
        mach.run(sc(0x08, 0), 0, screen=0, what='  the ceremony room, its second scene')
        follow(mach, rom, hops=2)
    bed = sc(0x2F, 0)
    mach.run(bed, 0, screen=4, what='  the bedroom')
    mach.run(sc(0x2F, 10), 0, screen=5, what='  the dresser')
    mach.ram[0xC83C] = 0
    mach.run(bed, 0, screen=4, what='  the bedroom: the question, YES')
    mach.run(sc(0x2F, 13), 0, screen=4, what='  the step-on trigger: the credits')
    mach.run(bed, 0, screen=4, what='  the bedroom: the ending\'s states; TO BE CONTINUED (saved)')
    mach.run(bed, 0, screen=4, what='  CONTINUE: the bedroom')
    mach.run(bed, 0, screen=5, what='  the bedroom\'s other screen')
    mach.run(sc(0x2F, 10), 0, screen=5, what='  the dresser')
    follow(mach, rom, hops=6)
    if not ({0x00F1} & mach.flags) and castle_scr0 is not None:
        mach.ram[CASTLE_EVENT] = 0
        mach.run(castle_scr0, 0, screen=1, what='  the King opens the post-game')


def state_at(step, repo=REPO, steps=None):
    """The saved state of a game about to do VANILLA_STEPS[step]."""
    from .balance import VANILLA_STEPS
    steps = steps or VANILLA_STEPS
    rom = _rom(repo)
    gates = {g['id']: g for g in _gates(repo)}
    castle = CS.decode_vanilla(rom, CASTLE, 0)
    lobby = CS.decode_vanilla(rom, ARENA_LOBBY, 0)
    mach = Machine(flags={0x0002})           # the starter has been given
    for kind, n in steps[:step]:
        if kind == 'gate':
            run_gate(mach, rom, gates[n])
        elif kind == 'class':
            run_class(mach, rom, lobby, n)
        elif kind == 'starry':
            run_ending(mach, rom, castle)
        # Monster Grandpa's match is the last step: nothing after it
    out = mach.saved()
    out['log'] = mach.log
    out['arena_tier'] = mach.ram.get(ARENA_TIER, 0)
    return out


def project_flags(prj_data, tl, step):
    """Cleared flags of the project's gates done before `step` (the Balance
    timeline `tl`): re-bossed vanilla gates and NEW gates (32+; done right
    after the gate they copy). Returns sorted ints."""
    gates = ((prj_data.get('custom') or {}).get('gates') or [])
    done_vanilla = {s['id'] for s in tl.steps[:step] if s['kind'] == 'gate'}
    out = set()
    for g in gates:
        gid = g.get('gate', g.get('id'))
        if gid is None:
            continue
        gid = int(gid)
        if gid < 32:
            if gid in done_vanilla and (g.get('boss') or g.get('boss_room')):
                out.add(GATE_OWN_FLAG + gid)
        else:
            src = g.get('copy_of')
            if src is not None and int(src) in done_vanilla:
                out.add(GATE_OWN_FLAG + gid)
    return sorted(out)


def story_points(tl):
    """[(index, label)] for a slider: 'about to do <step>'."""
    return [(s['index'], s['label'] + ('  (post-game)' if s['postgame'] else ''))
            for s in tl.steps]


__all__ = ['Machine', 'state_at', 'project_flags', 'story_points', 'king_code', 'SO']
