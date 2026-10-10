"""encounters.py — which wild-monster LIST a battle draws from (S114, ROADMAP P3.13a).

Headless (no Qt). Owning docs: PROJECT_COMPILER §2.30 (schema + emitter),
DATA_STRUCTURES "Encounter pool entry" + "Encounter list choice (S114)" (engine).

A LIST is the game's 26-byte encounter pool (rate code, 1/2/3-monster chances,
five slots of enemy row + chance + max count, maze size). Numbers:
  * 0-127   the ROM's lists (bank $01 EncounterPoolData; edited through
            gamedata.encounters, PROJECT_COMPILER §2.20);
  * 128-255 the project's OWN lists, custom.encounter_lists[] in order
            (bank $76 ProjectEncLists).

Who uses which list (bank $76 EncResolve, called by the patched bank $01
LoadNextDungeonFloor at every step of an encounter room, at floor setup and
when a battle fires):
  1. a CUSTOM room (not a gate maze floor) with its own list:
        custom.rooms[].encounters = {"enabled": true, "list": <ref>,
            "variants": [{"when": [flag terms], "list": <ref>}, ...],
            "rate": 0-7}
     the first variant whose flag terms hold, else `list`. Such a room never
     pins wGateID (RoomEncTable gate byte $FF), so it keeps working inside a
     dive (a room served on a gate floor) and outside one.
  2. otherwise the GATE rule for (wGateID, floor): the vanilla breakpoints,
     unless custom.gates[] gives the gate its own plan:
        custom.gates[] = {"gate": n, ..., "encounters": {
            "floors": [{"floors": [first, last] | n | "all", "list": <ref>}],
            "variants": [{"when": [flag terms], "floors": [...]}]}}
     floors use the game's numbering (the first floor is 1); a floor no run
     covers keeps the vanilla list (a variant's uncovered floors fall back to
     the gate's own plan). The floor's VALUE (wEncounterPoolIndex, read by the
     depth-tier-3 floor gold) stays the vanilla number.
  `rate` (a room's own battle rate code 0-7, EncounterRateModifierTable) also
  works on a room that keeps the gate's list. <ref> = a list number 0-255 or a
  custom.encounter_lists id. Flag terms = the gate-insert form
  ({"flag": name | number, "is": "set" | "clear"}).
"""

import json
import os

from . import formats as F
from . import gamedata as GD

PROJECT_BASE = 0x80          # first project list number
MAX_PROJECT_LISTS = 128      # numbers 128-255
MAX_TERMS = 8
VANILLA_GATES = 32
LIST_DEFAULTS = {'rate': 3, 'unk1': 3, 'size_chance': [7, 0, 0],
                 'slot_chance': [7, 0, 0, 0, 0], 'eids': [0, 0, 0, 0, 0],
                 'max_count': [1, 1, 1, 1, 1], 'maze_size': 15}
LIST_ENTRY_KEYS = set(GD.LIST_KEYS) | {'id', 'name', 'comment'}
ROOM_ENC_KEYS = {'enabled', 'gate_id', 'floor', 'follow_gate', 'list', 'variants',
                 'rate', 'comment'}
GATE_ENC_KEYS = {'floors', 'variants', 'comment'}
CUSTOM_ROOM_START = 0x6B
NON_GATE_BASE = 100          # bank $16 entry 8: bc = $0064 outside gates ($50 on maps $54-$56)


class EncounterError(ValueError):
    pass


# ---------------------------------------------------------------------------
# vanilla tables (extracted/gamedata_vanilla.json, tools/extract_gamedata.py)
# ---------------------------------------------------------------------------

def _tables(repo):
    return GD.vanilla(repo)['tables']


def _rows(repo, name):
    return [bytes.fromhex(r) for r in _tables(repo)[name]['rows']]


def vanilla_gate_rule(repo):
    """(base[32], bp_ptrs[32] as bank $01 addresses, breakpoint bytes from
    $6A82) — the bank $01 LoadNextDungeonFloor rule."""
    base = [r[0] for r in _rows(repo, 'gate_base_pool')]
    ptrs = [r[0] | r[1] << 8 for r in _rows(repo, 'gate_bp_ptrs')]
    bps = bytes(r[0] for r in _rows(repo, 'floor_breakpoints'))
    return base, ptrs, bps


BP_ADDR = 0x6A82             # FloorBreakpointData


def vanilla_number(repo, gate, floor):
    """The vanilla list of gate `gate` (0-31) on floor `floor` (the game's
    numbering, 1 = the first floor): LoadNextDungeonFloor's walk —
    sub-index = how many breakpoints are <= floor. Other gates: 0."""
    if not 0 <= gate < VANILLA_GATES:
        return 0
    base, ptrs, bps = vanilla_gate_rule(repo)
    i = ptrs[gate] - BP_ADDR
    c = -1
    while True:
        c += 1
        b = bps[i]
        i += 1
        if not floor >= b:
            break
    return (base[gate] + c) & 0xFF


def rate_modifiers(repo):
    return [r[0] for r in _rows(repo, 'encounter_rate_mod')]


def counter_seeds(repo):
    """[(threshold, counter)] — bank $16 RandomEncounterCounterTable: the
    counter after a battle is the first row whose threshold >= RNG mod 101."""
    return [(r[0], r[2] | r[3] << 8) for r in _rows(repo, 'encounter_counter_seeds')]


def mean_counter(repo):
    prev, tot = -1, 0.0
    for thr, val in counter_seeds(repo):
        hi = min(thr, 100)
        n = max(0, hi - prev)
        tot += n * val
        prev = hi
        if hi >= 100:
            break
    return tot / 101.0


def steps_between(repo, rate_code, base=NON_GATE_BASE):
    """Average steps between battles: the battle fires on the step whose
    drain (base * modifier / 64; bank $16 entry 8, measured S70: 100 per step
    at base 100, code 3) borrows, so from a counter c it takes c // drain + 1
    steps — the mean over RandomEncounterCounterTable's seeds (S130: was
    counter / drain, one step short; editor2/core/dive.py, PyBoy-measured).
    Outside gates base = 100; on gate floors base = EncounterRateData (100-250
    by floor type and the tile row the player stands on)."""
    mod = rate_modifiers(repo)[rate_code & 7]
    drain = max(1, base * mod // 64)
    prev, tot = -1, 0.0
    for thr, val in counter_seeds(repo):
        hi = min(thr, 100)
        tot += max(0, hi - prev) * (val // drain + 1)
        prev = hi
        if hi >= 100:
            break
    return tot / 101.0


# ---------------------------------------------------------------------------
# the battle draw (bank $01 EncounterMonsterSelect) — exact, RNG included
# ---------------------------------------------------------------------------

def rng_next(r1, r2):
    """ROM0 GenerateRNG: HL = wRNG1:wRNG2; HL = HL*5 + $1357."""
    hl = ((r1 << 8 | r2) * 5 + 0x1357) & 0xFFFF
    return hl >> 8, hl & 0xFF


def _cumulative(codes, pct):
    out, run = [], 0
    for c in codes:
        run = (run + pct[c]) & 0xFF
        out.append(run)
    return out


def _calc(sums, rng):
    """CalcEncounterPoolIdx: draw = (wRNG2:wRNG1 — the routine loads L from
    wRNG1, H from wRNG2) mod 100 after a GenerateRNG; the first entry whose
    running sum is 100, or >= the draw (leading 0 sums skipped).
    Returns (index, rng)."""
    rng = rng_next(*rng)
    d = (rng[1] << 8 | rng[0]) % 100
    for i, s in enumerate(sums):
        if s == 0:
            continue
        if s == 100 or s >= d:
            return i, rng
    raise ValueError('the list never reaches the draw (walks off its end)')


def simulate_battle(lb, pct, r1, r2):
    """EncounterMonsterSelect on the 26-byte list `lb` from RNG state
    (r1, r2): -> (monsters, [EIDs], (r1, r2) after). Measured == the game
    (tools/census_encounters.py)."""
    rng = (r1, r2)
    size, rng = _calc(_cumulative(lb[2:5], pct), rng)
    slots = _cumulative(lb[5:10], pct)
    maxes = lb[20:25]
    picks = []
    k, rng = _calc(slots, rng)
    picks.append(k)
    if maxes[k] != 1 and size:
        for _n in range(size):
            for _guard in range(100000):
                k, rng = _calc(slots, rng)
                copies = sum(1 for x in picks + [k] if x == k)
                if not (maxes[k] < copies or maxes[k] == 1):
                    break
            else:
                raise ValueError('the second / third draw never ends (freeze)')
            picks.append(k)
    eids = [lb[10 + 2 * k] | lb[11 + 2 * k] << 8 for k in picks]
    return len(picks), eids, rng


def group_odds(lb, pct, samples=20000, seed=114):
    """{(eid, ...) sorted: probability} for one list — simulate_battle over
    a fixed spread of RNG states (the editor's "what a battle looks like")."""
    out = {}
    r = (seed & 0xFF, seed >> 8 & 0xFF)
    for _ in range(samples):
        n, eids, _r = simulate_battle(lb, pct, *r)
        key = tuple(sorted(eids))
        out[key] = out.get(key, 0) + 1
        r = rng_next(*rng_next(*r))
    return {k: v / samples for k, v in out.items()}


def real_chances(codes, pct):
    """Exact chance of each entry for a uniform draw 0-99 (CalcEncounterPoolIdx:
    the first entry whose running sum is >= the draw — so the first entry
    with a chance also takes draw 0 (+1 point) and the entry ending at 100
    loses one): [percent per entry]."""
    sums = _cumulative(codes, pct)
    hits = [0] * len(codes)
    for d in range(100):
        for i, s in enumerate(sums):
            if s == 0:
                continue
            if s == 100 or s >= d:
                hits[i] += 1
                break
    return hits


# ---------------------------------------------------------------------------
# resolving a project
# ---------------------------------------------------------------------------

def _repo(prj):
    from .project import REPO_ROOT
    return getattr(prj, 'repo_root', None) or REPO_ROOT


def _terms(prj, when, ctx):
    out = []
    for k, t in enumerate(when or []):
        if not isinstance(t, dict) or 'flag' not in t:
            raise EncounterError(f"{ctx}.when[{k}]: a flag term is "
                                 "{\"flag\": name | number, \"is\": \"set\" | \"clear\"}")
        is_ = t.get('is', 'set')
        if is_ not in ('set', 'clear'):
            raise EncounterError(f"{ctx}.when[{k}].is must be 'set' or 'clear'")
        try:
            idx = prj.resolve_flag_ref(t['flag'], f"{ctx}.when[{k}]")
        except Exception as e:                     # ProjectError
            raise EncounterError(str(e))
        out.append((idx, is_ == 'clear'))
    if len(out) > MAX_TERMS:
        raise EncounterError(f"{ctx}.when: at most {MAX_TERMS} flag terms")
    return out


class Model:
    """The resolved encounter data of a project (see the module doc)."""

    def __init__(self, prj):
        self.prj = prj
        self.repo = _repo(prj)
        self.warnings = []
        self.gd = prj.gamedata()
        self.pct = self.gd.v['chance_percent']
        self._lists()
        self._rooms()
        self._gates()

    # -- lists ---------------------------------------------------------
    def _lists(self):
        raw = self.prj.custom.get('encounter_lists') or []
        if not isinstance(raw, list):
            raise EncounterError("custom.encounter_lists must be a list")
        if len(raw) > MAX_PROJECT_LISTS:
            raise EncounterError(f"custom.encounter_lists: {len(raw)} lists — at most "
                                 f"{MAX_PROJECT_LISTS} (numbers 128-255)")
        self.lists, self.by_id = [], {}
        for i, o in enumerate(raw):
            ctx = f"custom.encounter_lists[{i}]"
            if not isinstance(o, dict):
                raise EncounterError(f"{ctx}: must be an object")
            bad = sorted(k for k in o if k not in LIST_ENTRY_KEYS and not str(k).startswith('_'))
            if bad:
                raise EncounterError(f"{ctx}: unknown keys {bad}")
            lid = o.get('id')
            if not isinstance(lid, str) or not lid.strip():
                raise EncounterError(f"{ctx}: needs an id (text)")
            if lid in self.by_id:
                raise EncounterError(f"{ctx}: id {lid!r} used twice")
            ctx = f"custom.encounter_lists[{lid}]"
            r = bytearray(26)
            full = dict(LIST_DEFAULTS)
            full.update({k: v for k, v in o.items() if k in GD.LIST_KEYS})
            try:
                GD.apply_list_fields(r, full, ctx, self.gd.list_eid)
                self.warnings += GD.check_list(r, ctx, self.pct)
            except GD.GamedataError as e:
                raise EncounterError(str(e))
            entry = {'id': lid, 'name': o.get('name') or lid, 'number': PROJECT_BASE + i,
                     'bytes': r, 'index': i}
            self.lists.append(entry)
            self.by_id[lid] = entry

    def ref(self, ref, ctx):
        """A list reference -> its number (0-255)."""
        if isinstance(ref, str) and ref in self.by_id:
            return self.by_id[ref]['number']
        try:
            n = F.val(ref)
        except Exception:
            n = None
        if not isinstance(n, int) or isinstance(n, bool):
            raise EncounterError(f"{ctx}: list {ref!r} is neither a list number nor a "
                                 "custom.encounter_lists id")
        if 0 <= n < PROJECT_BASE:
            return n
        if PROJECT_BASE <= n < PROJECT_BASE + len(self.lists):
            return n
        raise EncounterError(f"{ctx}: list {n} does not exist (0-127 = the game's, "
                             f"128-{PROJECT_BASE + len(self.lists) - 1} = this project's)")

    def list_bytes(self, n):
        """The effective 26 bytes of list n (edits included)."""
        if n < PROJECT_BASE:
            return bytes(self.gd.pool[n])
        return bytes(self.lists[n - PROJECT_BASE]['bytes'])

    # -- rooms ---------------------------------------------------------
    def _rooms(self):
        self.rooms = {}            # mapID -> {room_id, default, variants[(terms, n)], rate}
        for r in self.prj.rooms:
            if r.get('placeholder'):
                continue
            enc = r.get('encounters')
            if not enc:
                continue
            ctx = f"room {r.get('id')} encounters"
            if not isinstance(enc, dict):
                raise EncounterError(f"{ctx}: must be an object")
            bad = sorted(k for k in enc if k not in ROOM_ENC_KEYS and not str(k).startswith('_'))
            if bad:
                raise EncounterError(f"{ctx}: unknown keys {bad}")
            has_list = enc.get('list') is not None
            if enc.get('variants') and not has_list:
                raise EncounterError(f"{ctx}: variants need a `list` too (used when no "
                                     "variant's flags hold)")
            rate = enc.get('rate')
            if rate is not None:
                try:
                    rate = GD._range(rate, 0, 7, ctx + '.rate')
                except GD.GamedataError as e:
                    raise EncounterError(str(e))
            if not (has_list or rate is not None):
                continue
            if not enc.get('enabled'):
                self.warnings.append(f"{ctx}: a list / rate is set but encounters are "
                                     "not enabled — no battles in this room")
            if has_list and (enc.get('gate_id') is not None or enc.get('floor') is not None) \
                    and not enc.get('follow_gate'):
                self.warnings.append(f"{ctx}: its own list wins — gate_id / floor are "
                                     "ignored (the room no longer pins a gate)")
            variants = []
            for k, v in enumerate(enc.get('variants') or []):
                vc = f"{ctx}.variants[{k}]"
                if not isinstance(v, dict) or set(v) - {'when', 'list', 'comment'}:
                    raise EncounterError(f"{vc}: {{\"when\": [flag terms], \"list\": ref}}")
                terms = _terms(self.prj, v.get('when'), vc)
                if not terms:
                    raise EncounterError(f"{vc}: a variant needs at least one flag term")
                variants.append((terms, self.ref(v.get('list'), vc + '.list')))
            self.rooms[F.val(r['mapID'])] = {
                'room_id': r.get('id'), 'variants': variants, 'rate': rate,
                'default': self.ref(enc['list'], ctx + '.list') if has_list else None}

    def own_list(self, room):
        """True when the room uses a list of its own (no gate pin)."""
        enc = room.get('encounters') or {}
        return enc.get('list') is not None

    # -- gates ---------------------------------------------------------
    def _gates(self):
        from . import gates as G
        self.gates = {}            # gate -> {floors, default{f: n}, variants[(terms, {f: n})]}
        for i, g in enumerate(self.prj.custom.get('gates') or []):
            enc = g.get('encounters')
            if not enc:
                continue
            gid = int(F.val(g.get('gate', -1)))
            ctx = f"custom.gates[gate {gid}].encounters"
            if not isinstance(enc, dict):
                raise EncounterError(f"{ctx}: must be an object")
            bad = sorted(k for k in enc if k not in GATE_ENC_KEYS and not str(k).startswith('_'))
            if bad:
                raise EncounterError(f"{ctx}: unknown keys {bad}")
            n = G.gate_floor_count(self.prj.custom, gid, self.repo) or 0
            van = {f: self.vanilla(gid, f) for f in range(1, n + 1)}
            default = dict(van)
            default.update(self._runs(enc.get('floors'), n, ctx + '.floors'))
            variants = []
            for k, v in enumerate(enc.get('variants') or []):
                vc = f"{ctx}.variants[{k}]"
                if not isinstance(v, dict) or set(v) - {'when', 'floors', 'comment'}:
                    raise EncounterError(f"{vc}: {{\"when\": [flag terms], \"floors\": [runs]}}")
                terms = _terms(self.prj, v.get('when'), vc)
                if not terms:
                    raise EncounterError(f"{vc}: a variant needs at least one flag term")
                plan = dict(default)
                plan.update(self._runs(v.get('floors'), n, vc + '.floors'))
                variants.append((terms, plan))
            self.gates[gid] = {'floors': n, 'default': default, 'variants': variants,
                               'vanilla': van}

    def _runs(self, runs, n, ctx):
        from . import gates as G
        out = {}
        if runs is None:
            return out
        if not isinstance(runs, list):
            raise EncounterError(f"{ctx}: a list of {{\"floors\": ..., \"list\": ref}}")
        for k, run in enumerate(runs):
            rc = f"{ctx}[{k}]"
            if not isinstance(run, dict) or set(run) - {'floors', 'list', 'comment'}:
                raise EncounterError(f"{rc}: {{\"floors\": [first, last] | n | \"all\", "
                                     "\"list\": ref}")
            try:
                first, last = G.floor_range(run.get('floors', 'all'), n, 1)
            except ValueError as e:
                raise EncounterError(f"{rc}: {e}")
            if first < 1 or last > max(n, 1) or last < first:
                raise EncounterError(f"{rc}: floors {first}-{last} — this gate has floors "
                                     f"1-{n} (floor {n} is its boss floor)")
            num = self.ref(run.get('list'), rc + '.list')
            for f in range(first, last + 1):
                if f in out:
                    raise EncounterError(f"{rc}: floor {f} is in two runs")
                out[f] = num
        return out

    def vanilla(self, gate, floor):
        """The vanilla list number of a gate floor; a NEW gate (S115) takes
        the rule of the gate it copies (bank $76 NewGateSource)."""
        from . import gates as G
        src = G.gate_source(self.prj.custom, gate)
        return vanilla_number(self.repo, src if src is not None else gate, floor)

    # -- views for the editor ------------------------------------------
    def gate_list(self, gate, floor, flags=None):
        """The list gate `gate` uses on `floor` (flags: {flag index: bool} to
        pick a variant; None = the default plan)."""
        g = self.gates.get(gate)
        if g is None:
            return self.vanilla(gate, floor)
        plan = g['default']
        if flags is not None:
            for terms, p in g['variants']:
                if all(bool(flags.get(i)) != clr for i, clr in terms):
                    plan = p
                    break
        return plan.get(floor, self.vanilla(gate, floor))


def resolve(prj):
    """The project's encounter Model (cached on the Project)."""
    m = getattr(prj, '_enc_model', None)
    if m is None:
        m = Model(prj)
        prj._enc_model = m
    return m


def check(prj):
    """Validation entry (validators.validate): raises EncounterError, returns
    warnings."""
    return list(resolve(prj).warnings)


# ---------------------------------------------------------------------------
# bank $76 emitter
# ---------------------------------------------------------------------------

def _term_lines(terms):
    return [f"    dw ${idx | (0x8000 if clr else 0):04X}   ; flag {F.hexw(idx)} must be "
            f"{'clear' if clr else 'set'}" for idx, clr in terms]


def _floor_runs(plan, n):
    """{floor: list} for floors 1..n -> [(last_floor, list)] with $FF last."""
    if n < 1:
        return [(0xFF, 0)]
    runs = []
    for f in range(1, n + 1):
        num = plan[f]
        if runs and runs[-1][1] == num:
            runs[-1] = (f, num)
        else:
            runs.append((f, num))
    runs[-1] = (0xFF, runs[-1][1])
    return runs


def emit_bank_076(prj, warnings, head):
    m = resolve(prj)
    repo = m.repo
    out = [head.rstrip('\n'), ""] + prj.place_number_block('76') + ["",
           "; " + "=" * 77,
           "; ENCOUNTER DATA (generated by editor2 `enc76` from custom.encounter_lists,",
           "; custom.rooms[].encounters, custom.gates[].encounters — PROJECT_COMPILER §2.30)",
           "; " + "=" * 77, ""]
    out += prj.region_table_lines('76') + [""]
    # rooms (S140: place-number order — PlaceNum76)
    rooms = list(prj.rooms)
    out += [f"ENC_ROOM_LEN EQU {len(rooms)}",
            "EncRoomTable:  ; [dw variant list (0 = none), db rate ($FF = the list's)]"]
    vlists = []
    for r in rooms:
        mid = F.val(r['mapID'])
        e = m.rooms.get(mid)
        if e is None:
            out.append(f"    dw 0\n    db $FF  ; {F.hexb(mid)} {r.get('id')}")
            continue
        rate = 0xFF if e['rate'] is None else e['rate']
        if e['default'] is None:
            out.append(f"    dw 0\n    db ${rate:02X}  ; {F.hexb(mid)} {e['room_id']} — "
                       f"the gate's list, rate code {rate}")
            continue
        lab = f"EncRoomVariants_{mid:02X}"
        out.append(f"    dw {lab}\n    db ${rate:02X}  ; {F.hexb(mid)} {e['room_id']}"
                   + ("" if e['rate'] is None else f", rate code {rate}"))
        body = [f"{lab}:"]
        for terms, num in e['variants']:
            body.append(f"    db {len(terms)}")
            body += _term_lines(terms)
            body.append(f"    dw {num}  ; -> list {num}")
        body.append(f"    db 0\n    dw {e['default']}  ; otherwise list {e['default']}")
        vlists += body
    out.append("")
    out += vlists + [""]
    # gates
    plen = (max(m.gates) + 1) if m.gates else 0
    out += [f"GATE_PLAN_LEN EQU {plen}",
            "GatePlanPtrs:  ; dw per gate number (0 = the vanilla rule)"]
    gbody = []
    for gid in range(plen):
        g = m.gates.get(gid)
        if g is None:
            out.append(f"    dw 0  ; gate {gid}: vanilla")
            continue
        lab = f"EncGatePlan_{gid:02X}"
        out.append(f"    dw {lab}  ; gate {gid}: its own plan")
        gbody.append(f"{lab}:")
        runs_body = []
        for k, (terms, plan) in enumerate(g['variants']):
            rl = f"EncGateRuns_{gid:02X}_{k}"
            gbody.append(f"    db {len(terms)}")
            gbody += _term_lines(terms)
            gbody.append(f"    dw {rl}")
            runs_body.append(f"{rl}:")
            runs_body += [f"    db ${last:02X}, {num}  ; floors to {last if last != 0xFF else 'the end'}: list {num}"
                          for last, num in _floor_runs(plan, g['floors'])]
        rl = f"EncGateRuns_{gid:02X}_d"
        gbody += ["    db 0", f"    dw {rl}"]
        runs_body.append(f"{rl}:")
        runs_body += [f"    db ${last:02X}, {num}  ; floors to {last if last != 0xFF else 'the end'}: list {num}"
                      for last, num in _floor_runs(g['default'], g['floors'])]
        gbody += runs_body
    out += [""] + gbody + [""]
    # S115 (ROADMAP NG1): new gates — their 8-byte rows (bank $16 GateRowPtr
    # -> entry 1 NewGateRowCopy -> wGateRowBuf) and the vanilla gate each copies
    cfg = prj.gate_configs()
    new_ids = sorted(g for g in cfg if g >= 32)
    nlen = (max(new_ids) - 31) if new_ids else 0
    out += [f"NEW_GATE_LEN EQU {nlen}",
            "NewGateRows:  ; 8 B per gate 32+ [ft1, ft2, ft3, floors, boss map, boss x, boss y, tier]"]
    srcs = []
    for gid in range(32, 32 + nlen):
        c = cfg.get(gid)
        if c is None:          # a gap: never entered (the validator refuses
            row = list(cfg[0]['row'])          # entrances to it) — gate 0's row
            srcs.append((0, f"gate {gid}: not defined (gate 0's row)"))
            why = f"gate {gid}: not defined"
        else:
            row = c['row']
            srcs.append((c['source'], f"gate {gid} {c['name']}: copy of gate {c['source']}"))
            why = (f"gate {gid} {c['name']} — copy of gate {c['source']}, "
                   f"{c['floors']} floors, boss {F.hexb(c['boss_map'])}")
        out.append("    db " + ", ".join(f"${b:02X}" for b in row) + f"  ; {why}")
    out.append("NewGateSource:  ; db per gate 32+: the vanilla gate it copies")
    for src, why in srcs:
        out.append(f"    db {src}  ; {why}")
    out.append("")
    # S117 (ROADMAP NG2): the flags a boss-floor win sets (entry 2 GateBossWin)
    crow = prj.gate_clear_rows()
    out += [f"GATE_CLEAR_LEN EQU {len(crow)}",
            "GateClearTable:  ; per gate: [dw own cleared flag, dw vanilla flag, dw WinTail] "
            "($FFFF = no flag, $0000 = no tail)"]
    progs = []
    for gid, own, van, (extra, tails) in crow:
        if own is None:
            out.append(f"    dw $FFFF, $FFFF, $0000  ; gate {gid}: its own boss scripts set its flag")
            continue
        tail = '$0000'
        if extra or tails:
            tail = f'WinTail_{gid}'
            progs.append((gid, extra, tails))
        out.append(f"    dw {F.hexw(own)}, {F.hexw(van) if van is not None else '$FFFF'}, {tail}"
                   f"  ; gate {gid}: " + (cfg[gid]['name'] if gid in cfg else '')
                   + (" (new gate)" if gid >= 32 else " (another boss)"))
    out.append("")
    out += win_tail_programs(progs)
    # project lists
    out.append("ProjectEncLists:  ; 26 B each, numbers 128+ (EncounterPoolData format)")
    for e in m.lists:
        r = e['bytes']
        eids = [r[10 + 2 * k] | r[11 + 2 * k] << 8 for k in range(5)]
        out += [f"; list {e['number']}: {e['id']}",
                "    db " + ", ".join(f"${b:02X}" for b in r[0:10]),
                "    dw " + ", ".join(str(x) for x in eids),
                "    db " + ", ".join(f"${b:02X}" for b in r[20:26])]
    out.append("")
    # vanilla rule copies
    base, ptrs, bps = vanilla_gate_rule(repo)
    out += ["; byte copies of bank $01 GateBasePoolIndex / GateFloorBreakpoints /",
            "; FloorBreakpointData (extracted/gamedata_vanilla.json) — the vanilla rule",
            "VanillaGateBase:"]
    for k in range(0, 32, 8):
        out.append("    db " + ", ".join(str(x) for x in base[k:k + 8]))
    out.append("VanillaGateBpPtrs:")
    for k in range(0, 32, 4):
        out.append("    dw " + ", ".join(f"VanillaBreakpoints + {p - BP_ADDR}" for p in ptrs[k:k + 4]))
    out.append("VanillaBreakpoints:")
    for k in range(0, len(bps), 16):
        out.append("    db " + ", ".join(f"${b:02X}" for b in bps[k:k + 16]))
    return "\n".join(out) + "\n"


def win_tail_programs(progs):
    """S122 (NG2 residual a): bank $76 WinTail programs for RunWinTail — per
    re-bossed vanilla gate: set_flag for its further cleared flags, then its
    boss room's win tails (gate_names.json, the game's own script words) in
    order; jump targets become local labels, an op that ends a tail (the
    text close / the warp …) becomes a jump to the next tail; $FFFF ends."""
    out = []
    for gid, extra, tails in progs:
        out.append(f"WinTail_{gid}:  ; gate {gid}: the game's own win bookkeeping "
                   "(tools/map_gate_names.py win_tails)")
        for f in extra:
            out.append(f"    dw $FF03, {F.hexw(f)}  ; set_flag (a further cleared flag)")
        for k, t in enumerate(tails):
            ops = [(int(a, 16), op, [int(x, 16) for x in prm]) for a, op, prm in t['ops']]
            addrs = {a for a, _o, _p in ops}
            nxt = f"WinTail_{gid}_{k + 1}" if k + 1 < len(tails) else f"WinTail_{gid}_end"
            out.append(f"WinTail_{gid}_{k}:  ; tail {k}: bank {t['bank']} {t['start']}"
                       + (f" (after set_flag {t['flag']})" if t.get('flag') else ''))

            def lab(a):
                if a not in addrs:
                    raise ValueError(f"win tail of gate {gid}: target ${a:04X} outside the tail")
                return f".t{k}_{a:04X}"
            for a, op, prm in ops:
                out.append(f"{lab(a)}:")
                if op in (0x00, 0x01):
                    out.append(f"    dw $FF{op:02X}, {F.hexw(prm[0])}, {lab(prm[1])}")
                elif op == 0x14:
                    out.append(f"    dw $FF14, {lab(prm[0])}")
                elif op in (0x02, 0x03, 0x12, 0x13):
                    out.append("    dw " + ", ".join([f"$FF{op:02X}"] + [F.hexw(x) for x in prm]))
                else:
                    out.append(f"    dw $FF14, {nxt}  ; op ${op:02X} ends the game's tail here")
        out.append(f"WinTail_{gid}_end:")
        out.append("    dw $FFFF")
        out.append("")
    return out
