"""S127 (ROADMAP P3.14e2) — breeding in the project's rooms (PROJECT_COMPILER §2.40).

Breeding in DWM1 is three parts (BANK04_SCRIPT_ENGINE "Breeding", measured S127):
the MENUS are room-independent screen effects of bank $0A (op $04: 6 = Grandpa's
BREED / HATCH, 5 = a master offering their own monster, 11 = "Take … with you
now?", 15 = naming); the CEREMONY is always the vanilla room $08 (its script 0
is a stage machine on $D951); and the follow-up after the ceremony runs from the
ROOM's entry script: the game comes back to the spot op $4E / $42 saved, with
$D951 = $F0 (Grandpa: "Inside it is a baby …! Costs …G to hatch it."), $F1
(Grandpa: name it, "Take … with you now?") or $F2 (a master: "I hope a strong
monster will be born!"). So in a project:

  {"id": "hall_grandpa", "service": {"kind": "grandpa",
       "lines": "<line set>", "first_time": {"text", "flag"}}}
  {"id": "hall_cat", "service": {"kind": "breeder",
       "mate": 306 | "<progression.enemies id>",      # a fixed mate (an enemy row)
       "pool": "<custom.breeding_pools id>",          # … or one rolled per appearance
       "lines": "<line set>", "intro": "<dialogue id>",
       "when": [{"flag": …, "is": "set"}], "not_yet": "<dialogue id>",
       "flag": "<flag>",         # turned ON when a breeding with this NPC is done
       "once": true,             # with the flag ON: says `after` instead of offering
       "after": "<dialogue id>"}}

lowered (lower_talk, once the rooms resolve — the scripts need the NPC's slot)
into the vanilla NPCs' shapes, and every room holding one gets a RETURN script
in front of its entry script (lower_entries, after the cutscenes): on $F0 / $F1 /
$F2 the NPC the player talked to (wBreedLast) turns to the player (the vanilla
$50 / $44 turn a FIXED slot) and the game's follow-up runs; anything else goes
on into the room's own entry script.

BREEDING POOLS (custom.breeding_pools): a random breeder's mate is rolled when
the room appears (bank $77 BreedRoll, the first time the menu loads the mate):

  {"id": "wild", "name": "Wild mates",
   "measures": ["level", "arena", "seen", "story"],   # the scales the bands use
   "milestones": ["<flag>", …],                       # the story scale's steps
   "bands": [{"name": "early", "level": 10, "arena": 0, "seen": 20, "story": 0,
              "mates": [{"enemy": 306, "weight": 3}, …]}, …]}

The band = the one NEAREST the player's progress: the smallest sum over the
checked scales of |player − band|, each scale on ~0-100 points (average party
level; arena classes won × 12; monsters seen / 2; story milestones ON × 100 /
their number); a tie goes to the earlier band. Then a mate by weight.

Engine (S127): bank $77 entries 7 BreedClose / 8 BreedSlotEID / 9 PartyAvgLevel /
10 ScriptCommand (op $24 $FF00: the mate's name; bank $60 CustomDrawTiles routes $FFxx),
bank $14 LoadEnemyStatsExt ($0F00 + slot), bank $73 entry 0 (the map-change
commit clears the slots), bank $0A's three close tails, wBreedLast /
wBreedSlots / wBreedVals (patches/wram.asm).
"""
from . import formats as F
from . import services as SV

MEASURES = ('level', 'arena', 'seen', 'story')
MEASURE_BIT = {'level': 1, 'arena': 2, 'seen': 4, 'story': 8}
MEASURE_NAME = {'level': "the party's average level", 'arena': 'arena classes won',
                'seen': 'monsters seen (Library)', 'story': 'story milestones reached'}
MEASURE_RANGE = {'level': (0, 99), 'arena': (0, 8), 'seen': (0, 240), 'story': None}
SLOT_EID = 0x0F00            # + slot: a random breeder's pseudo enemy row
BREED_SLOTS = 4              # wBreedSlots (patches/wram.asm)
MAX_POOLS = 100
MAX_BANDS = 16
MAX_MATES = 16
MAX_MILESTONES = 16
W_LAST = 'wBreedLast'
W_SLOTS = 'wBreedSlots'
D951 = 0xD951                # the breeding stage / return code (map $08's counter)
C901 = 0xC901                # the player's facing saved by op $4E / $42
C83C = 0xC83C                # YES / NO (0 YES)
D9E6 = 0xD9E6                # the "rare breed" mark the shrine tests
GATE_ANY = 0xFE              # a gate_inserts record for every gate (bank $71)
SCRIPT_CMD_MATE_NAME = 0xFF00   # op $24 $FF00: the mate's name -> insert slot 0 (bank $77 entry 10)


class BreedError(ValueError):
    pass


# ------------------------------------------------------------------ pools
def scaled(measure, value, step=0):
    """The player's raw value on a scale -> the engine's points (BreedRoll)."""
    v = int(value)
    if measure == 'level':
        return max(0, min(255, v))
    if measure == 'arena':
        return (max(0, min(8, v)) * 12) & 0xFF
    if measure == 'seen':
        return max(0, min(240, v)) >> 1
    if measure == 'story':
        return (max(0, v) * step) & 0xFF
    raise BreedError(f'unknown measure {measure!r}')


def story_step(n_milestones):
    return 100 // n_milestones if n_milestones else 0


def pool_model(p, n=0, flag_fn=None, eid_fn=None, check_row=None):
    """One custom.breeding_pools entry checked and resolved: {id, name, n,
    measures, mask, step, milestones, bands [{name, targets, points, mates
    [(eid, w)], total}]}. flag_fn / eid_fn resolve a milestone flag / a mate's
    enemy reference (the compiler's; the editor's preview keeps names / takes
    numbers); check_row(eid, ctx) refuses a row that does not exist."""
    flag_fn = flag_fn or (lambda f, _c: f)
    eid_fn = eid_fn or (lambda r, _c: int(F.val(r)) if not isinstance(r, str) or
                        r.lstrip('$0x').isalnum() and r[:1] in '0123456789$' else r)
    ctx = f'custom.breeding_pools[{n}]'
    if not isinstance(p, dict) or not p.get('id'):
        raise BreedError(f'{ctx}: {{"id", "measures", "bands": [...]}}')
    pid = p['id']
    ctx = f'breeding pool {pid!r}'
    unknown = set(p) - {'id', 'name', 'measures', 'milestones', 'bands', 'comment'}
    if unknown:
        raise BreedError(f'{ctx}: unknown keys {sorted(unknown)}')
    ms = list(p.get('measures') or [])
    for m in ms:
        if m not in MEASURES:
            raise BreedError(f'{ctx}: measure {m!r} (one of {", ".join(MEASURES)})')
    mask = 0
    for m in ms:
        mask |= MEASURE_BIT[m]
    mils = [flag_fn(f, ctx + ' milestones') for f in p.get('milestones') or []]
    if len(mils) > MAX_MILESTONES:
        raise BreedError(f'{ctx}: {len(mils)} milestones (max {MAX_MILESTONES})')
    if 'story' in ms and not mils:
        raise BreedError(f'{ctx}: the story scale needs milestones (the flags that '
                         'mark the story steps, in order)')
    step = story_step(len(mils))
    bands = []
    bl = p.get('bands') or []
    if not 1 <= len(bl) <= MAX_BANDS:
        raise BreedError(f'{ctx}: 1-{MAX_BANDS} bands')
    for j, b in enumerate(bl):
        bctx = f'{ctx} band {j + 1}'
        unknown = set(b) - {'name', 'mates', 'comment'} - set(MEASURES)
        if unknown:
            raise BreedError(f'{bctx}: unknown keys {sorted(unknown)}')
        targets = {}
        for m in MEASURES:
            try:
                v = int(F.val(b.get(m, 0)))
            except (TypeError, ValueError):
                raise BreedError(f'{bctx}: {m} must be a number')
            hi = len(mils) if m == 'story' else MEASURE_RANGE[m][1]
            if not 0 <= v <= hi:
                raise BreedError(f'{bctx}: {m} {v} (0-{hi})')
            targets[m] = v
        mates, total = [], 0
        ml = b.get('mates') or []
        if not 1 <= len(ml) <= MAX_MATES:
            raise BreedError(f'{bctx}: 1-{MAX_MATES} mates')
        for k, mt in enumerate(ml):
            mctx = f'{bctx} mate {k + 1}'
            if not isinstance(mt, dict):
                raise BreedError(f'{mctx}: {{"enemy": row, "weight": n}}')
            try:
                eid = eid_fn(mt.get('enemy'), mctx)
            except BreedError:
                raise
            except Exception as ex:                              # noqa: BLE001
                raise BreedError(f'{mctx}: {ex}')
            if check_row is not None:
                check_row(eid, mctx)
            try:
                w = int(F.val(mt.get('weight', 1)))
            except (TypeError, ValueError):
                raise BreedError(f'{mctx}: weight must be a number')
            if not 1 <= w <= 255:
                raise BreedError(f'{mctx}: weight {w} (1-255)')
            mates.append((eid, w))
            total += w
        if total > 255:
            raise BreedError(f'{bctx}: the weights add up to {total} (max 255)')
        bands.append({'name': b.get('name') or f'band {j + 1}', 'targets': targets,
                      'points': [scaled(m, targets[m], step) for m in MEASURES],
                      'mates': mates, 'total': total})
    return {'id': pid, 'name': p.get('name') or pid, 'n': n, 'measures': ms,
            'mask': mask, 'step': step, 'milestones': mils, 'bands': bands}


def check_pool(doc, p):
    """The editor's check of one pool before it is kept (the compiler's rules;
    mates may be project enemy ids, flags names)."""
    def eid(r, ctx):
        if isinstance(r, str) and not r[:1].isdigit() and not r.startswith('$'):
            if not any(e.get('id') == r for e in doc.project_enemies()):
                raise BreedError(f'{ctx}: no project enemy {r!r}')
            return r
        return int(F.val(r))
    pool_model(p, 0, eid_fn=eid)


def pools(prj):
    """custom.breeding_pools resolved, in list order (the pool number = the
    index) — pool_model with the project's flags and enemy rows. Cached."""
    c = getattr(prj, '_breed_pools', None)
    if c is not None:
        return c
    lst = prj.custom.get('breeding_pools') or []
    if len(lst) > MAX_POOLS:
        raise BreedError(f'custom.breeding_pools: {len(lst)} pools (max {MAX_POOLS})')
    ids = [p.get('id') for p in lst if isinstance(p, dict)]
    dup = {x for x in ids if ids.count(x) > 1}
    if dup:
        raise BreedError(f'breeding pool {sorted(dup)[0]!r}: duplicate id')

    def eid(r, ctx):
        try:
            return prj.enemy_ref(r, ctx)
        except Exception as ex:                                  # noqa: BLE001
            raise BreedError(str(ex))
    out = [pool_model(p, i, flag_fn=lambda f, c: prj.resolve_flag_ref(f, c), eid_fn=eid,
                      check_row=lambda e, c: _check_mate_row(prj, e, c))
           for i, p in enumerate(lst)]
    prj._breed_pools = out
    return out


def pool_by_id(prj, pid):
    for p in pools(prj):
        if p['id'] == pid:
            return p
    return None


def _check_mate_row(prj, eid, ctx):
    if eid >= 519:
        if not any(e.get('_eid') == eid for e in prj.quest_enemy_rows()):
            raise BreedError(f'{ctx}: enemy row {eid} is not one of this project\'s enemies')
    elif not 0 < eid <= 486:
        raise BreedError(f'{ctx}: enemy row {eid} (vanilla rows are 1-486)')


def band_choice(pool, level=0, arena=0, seen=0, story=0):
    """The engine's BreedRoll band choice (bank $77): index of the nearest band
    for the player's RAW values (story = milestones ON)."""
    pts = [scaled('level', level), scaled('arena', arena), scaled('seen', seen),
           scaled('story', story, pool['step'])]
    best, bi = None, 0
    for i, b in enumerate(pool['bands']):
        d = 0
        for k, m in enumerate(MEASURES):
            if pool['mask'] & MEASURE_BIT[m]:
                d += abs(pts[k] - b['points'][k])
        if best is None or d < best:
            best, bi = d, i
    return bi


def mate_chances(band):
    """[(eid, percent)] of a band."""
    return [(e, 100.0 * w / band['total']) for e, w in band['mates']]


# --------------------------------------------------------------- gates
def chance_table(lo_level, lo_pct, hi_level, hi_pct):
    """A gate room's chance by the party's average level (bank $71
    ScaledChanceTable row): 100 bytes, level 0-99, linear between the two
    points, flat outside them."""
    row = []
    for lv in range(100):
        if lv <= lo_level:
            v = lo_pct
        elif lv >= hi_level:
            v = hi_pct
        else:
            v = lo_pct + (hi_pct - lo_pct) * (lv - lo_level) / (hi_level - lo_level)
        row.append(max(0, min(100, int(round(v)))))
    return row


def parse_chance_by_level(ru, ctx):
    """gate_inserts[].chance_by_level = {"from": [level, %], "to": [level, %]}."""
    cb = ru.get('chance_by_level')
    if cb is None:
        return None
    try:
        (l1, p1), (l2, p2) = cb['from'], cb['to']
        l1, p1, l2, p2 = int(l1), int(p1), int(l2), int(p2)
    except Exception:                                            # noqa: BLE001
        raise BreedError(f'{ctx}: chance_by_level = {{"from": [level, %], "to": [level, %]}}')
    if not (1 <= l1 < l2 <= 99):
        raise BreedError(f'{ctx}: chance_by_level levels {l1} -> {l2} (1-99, rising)')
    if not (0 <= p1 <= 100 and 0 <= p2 <= 100):
        raise BreedError(f'{ctx}: chance_by_level chances {p1} % / {p2} % (0-100)')
    return (l1, p1, l2, p2)


# -------------------------------------------------------- the placements
def _breeding_scripts(prj):
    return [s for s in prj.custom.get('scripts', [])
            if isinstance(s.get('service'), dict)
            and SV.KINDS.get(s['service'].get('kind'), {}).get('breeding')]


def placements(prj):
    """{script id: [(room, screen, slot)]} — where each breeding NPC stands
    (slot = the 1-based NPC slot, the same in every state of the screen)."""
    want = {s['id'] for s in _breeding_scripts(prj)}
    out = {}
    for r in prj.rooms:
        if r.get('placeholder'):
            continue
        by_idx = {int(k): v for k, v in (r.get('scripts') or {}).items()}
        for k, scr in prj.room_screens(r).items():
            per_state = []
            for st in prj.screen_states(scr):
                slots, n = {}, 0
                for e in st.get('npcs', []) or []:
                    if e.get('kind') == 'npc' or (e.get('kind') == 'raw' and
                                                  F.val(e['bytes'][0]) < 0x80):
                        n += 1
                        sid = e.get('script')
                        if isinstance(sid, int):
                            sid = by_idx.get(sid)
                        if sid in want:
                            slots.setdefault(sid, []).append(n)
                per_state.append(slots)
            for sid in want:
                used = [tuple(ps.get(sid, ())) for ps in per_state if ps.get(sid)]
                if not used:
                    continue
                if len(set(used)) > 1:
                    raise BreedError(
                        f"script {sid}: its NPC sits in different NPC slots in the states "
                        f"of room {r.get('id')} screen {k} — keep it in the same list "
                        "position in every state (the return after the ceremony turns "
                        "that slot to the player)")
                for slot in used[0]:
                    out.setdefault(sid, []).append((r, int(k), slot))
    return out


# --------------------------------------------------------------- lowering
def _face_ops(p, actor):
    """The player faces as saved ($C901: 0 down, 1 left, 2 up, 3 right — the
    $FF8E encoding) and NPC `actor` faces the player (the opposite)."""
    face = {0: '0x48', 1: '0x49', 2: '0x47', 3: '0x4A'}
    ops = []
    for d in (0, 1, 2):
        ops.append(['op', 'check_and_branch', f'0x{C901:04X}', d, f'@{p}_f{d}'])
    for d in (3, 0, 1, 2):
        if d != 3:
            ops.append(f'label:{p}_f{d}')
        ops += [['op', face[d], 0], ['op', face[(d + 2) & 3], actor],
                ['op', 'goto', f'@{p}_fx']]
    ops.append(f'label:{p}_fx')
    return ops


def _lines_on(n):
    return [['op', 'write_ram', SV.WSERVICE_LINES, n]] if n else []


def _lines_off(n):
    return [['op', 'write_ram', SV.WSERVICE_LINES, 0]] if n else []


def _terms(prj, terms, ctx):
    out = []
    for t in terms or []:
        is_ = t.get('is', 'set')
        if is_ not in ('set', 'clear'):
            raise BreedError(f"{ctx}: a term's 'is' must be set / clear")
        out.append((prj.resolve_flag_ref(t.get('flag'), ctx), is_ == 'clear'))
    if len(out) > 8:
        raise BreedError(f'{ctx}: {len(out)} flag terms (max 8)')
    return out


def lower_talk(prj):
    """Lower every grandpa / breeder script (after the rooms resolve, before
    the cutscenes wrap talk scripts). Sets prj._breeding = {sid: info}."""
    info = {}
    prj._breeding = info
    scripts = _breeding_scripts(prj)
    if not scripts:
        return
    sv_r = SV.resolve(prj)
    places = placements(prj)
    pls = pools(prj)
    # breeder numbers (wBreedLast): 1.. in the scripts' order
    num = 0
    room_rand = {}                         # room id -> [sid] (random breeders)
    for s in scripts:
        sid = s['id']
        sv = s['service']
        ctx = f'scripts[{sid}].service'
        kind = sv['kind']
        keys = {'kind', 'lines', 'comment'}
        keys |= {'first_time'} if kind == 'grandpa' else \
            {'mate', 'pool', 'intro', 'when', 'not_yet', 'flag', 'once', 'after',
             'first_time'}                      # S127 r4: a breeder's first visit too
        unknown = set(sv) - keys
        if unknown:
            raise BreedError(f'{ctx}: unknown keys {sorted(unknown)}')
        if 'ops' in s or 'talk' in s or 'shop' in s:
            if not s.get('_service_lowered'):
                raise BreedError(f"{ctx}: a service script has no 'ops' / 'talk' / 'shop'")
        lset = sv.get('lines')
        if lset is not None:
            if lset not in sv_r['sets']:
                raise BreedError(f'{ctx}: line set {lset!r} is not in custom.service_lines')
            if sv_r['sets'][lset]['kind'] != kind:
                raise BreedError(f"{ctx}: line set {lset!r} is for "
                                 f"{sv_r['sets'][lset]['kind']!r}, not {kind!r}")
        pl = places.get(sid, [])
        if len(pl) > 1:
            where = ', '.join(f"{r.get('id')} screen {k}" for r, k, _ in pl)
            raise BreedError(f'{ctx}: one breeding NPC per script — it stands in {where} '
                             '(make a copy of the script for the other NPC)')
        num += 1
        if num > 255:
            raise BreedError('more than 255 breeding NPCs (wBreedLast is a byte)')
        it = {'sid': sid, 'kind': kind, 'num': num, 'lines': lset,
              'set_n': sv_r['numbers'].get(lset) if lset else None,
              'room': pl[0][0] if pl else None, 'screen': pl[0][1] if pl else None,
              'actor': pl[0][2] if pl else 1, 'placed': bool(pl), 'sv': sv}
        if kind == 'breeder':
            if ('mate' in sv) == ('pool' in sv):
                raise BreedError(f"{ctx}: give the breeder a 'mate' (an enemy row) OR a "
                                 "'pool' (a breeding pool)")
            if 'mate' in sv:
                try:
                    it['eid'] = prj.enemy_ref(sv['mate'], ctx + '.mate')
                except Exception as ex:                          # noqa: BLE001
                    raise BreedError(str(ex))
                _check_mate_row(prj, it['eid'], ctx + '.mate')
            else:
                p = next((x for x in pls if x['id'] == sv['pool']), None)
                if p is None:
                    raise BreedError(f"{ctx}: pool {sv['pool']!r} is not in "
                                     "custom.breeding_pools")
                it['pool'] = p['n']
                if pl:
                    room_rand.setdefault(pl[0][0].get('id'), []).append(sid)
            it['terms'] = _terms(prj, sv.get('when'), ctx + '.when')
            it['flag'] = prj.resolve_flag_ref(sv['flag'], ctx + '.flag') \
                if sv.get('flag') else None
            if sv.get('once') and it['flag'] is None:
                raise BreedError(f"{ctx}: 'once' needs a 'flag' (turned ON when the "
                                 "breeding is done; then the NPC says 'after')")
        info[sid] = it
    for rid, sids in room_rand.items():
        if len(sids) > BREED_SLOTS:
            raise BreedError(f'room {rid}: {len(sids)} random breeders (max {BREED_SLOTS} '
                             'in one room — wBreedSlots)')
        for k, sid in enumerate(sids):
            info[sid]['slot'] = k
    for s in scripts:
        it = info[s['id']]
        s['ops'] = grandpa_ops(prj, it) if it['kind'] == 'grandpa' else breeder_ops(prj, it)
        s['_service_lowered'] = True


def _t(prj, it, off):
    return SV._text_ref(prj, it['lines'], it['kind'], off)


def _bottom(ops):
    """S127 r3 (user: "If you say no to breeding npc in $6b, 1) text box jumps around,
    and 2) text box BIFURCATES"): every text box of a breeding script opens at the
    BOTTOM — op $3C before each text and each init_dialog. The menus (types 5 / 6 /
    11) draw their windows for a bottom box; a box opened by the default rule (the
    top when the player stands in the lower half of the screen) jumped to the bottom
    for the question and, after NO, the farewell's scroll continued at the top while
    its first lines stood at the bottom (PyBoy, the user's $6B). bank $77 BreedClose
    re-seats the box at the bottom too (ShopBoxBottom, as after a shop)."""
    out = []
    for op in ops:
        is_text = isinstance(op, list) and op and op[0] == 'text'
        is_init = isinstance(op, list) and op[:2] == ['op', 'init_dialog']
        if (is_text or is_init) and not (out and out[-1] == ['op', '0x3C']):
            out.append(['op', '0x3C'])
        out.append(op)
    return out


def grandpa_ops(prj, it):
    """Grandpa's talk (the vanilla map $09 scripts 5 / 7): the greeting, op $4E
    (the spot the ceremony comes back to), the menu, the farewell."""
    sv = it['sv']
    base = SV.base_id('grandpa', getattr(prj, 'repo_root', None))
    ops = []
    ft = sv.get('first_time')
    if ft is not None:
        if not isinstance(ft, dict) or not ft.get('text') or not ft.get('flag'):
            raise BreedError(f"scripts[{it['sid']}].service.first_time: "
                             '{"text": <dialogue id>, "flag": <flag>}')
        fl = prj._flag_index(ft['flag'], 'first_time')
        ops += [['op', 'if_flag_set', fl, '@known'], ['text', ft['text']],
                ['op', 'set_flag', fl], ['op', 'goto', '@open'], 'label:known',
                ['text', _t(prj, it, 0)], 'label:open']
    else:
        ops.append(['text', _t(prj, it, 0)])
    n = it['set_n']
    ops += [['op', 'write_ram', W_LAST, it['num']], ['op', '0x4E']]
    ops += _lines_on(n) + [['op', '0x04', 6, base]] + _lines_off(n)
    ops += [['text', _t(prj, it, 2)], ['end']]
    return _bottom(ops)


def breeder_ops(prj, it):
    """A master offering their own monster (the vanilla Restaurant / Arena Lobby
    shape): conditions, op $42 <the mate's row> <the NPC's slot> (the spot the
    ceremony comes back to), the menu (it says +1..+8 with the mate's name),
    the farewell +0."""
    sv = it['sv']
    base = SV.base_id('breeder', getattr(prj, 'repo_root', None))
    n = it['set_n']
    ops = []
    for f, clr in it['terms']:
        ops.append(['op', 'if_flag_set' if clr else 'if_flag_clear', f, '@notyet'])
    if sv.get('once'):
        ops.append(['op', 'if_flag_set', it['flag'], '@after'])
    if 'slot' in it:
        k = it['slot']
        ops += [['op', 'write_ram', f'{W_SLOTS}+{4 * k + 1}', it['pool']],
                ['op', 'check_and_branch', f'{W_SLOTS}+{4 * k}', 2, '@after']]
        mate = SLOT_EID + k
    elif 'pool' in it:
        mate = SLOT_EID              # not placed: never runs
    else:
        mate = it['eid']
    # op $42: the mate's row + the spot the ceremony comes back to; op $24 $FF00:
    # the mate's name into insert slot 0 (bank $77 ScriptCommand 0 — a random
    # breeder's slot rolls here). Op $24 yields the tick, which ends the talk's
    # dialog (PyBoy S127: a text after it waited forever — field mode does not
    # service the queue), so init_dialog opens it again before any text
    ops += [['op', 'write_ram', W_LAST, it['num']],
            ['op', '0x42', mate, it['actor']], ['op', '0x24', SCRIPT_CMD_MATE_NAME],
            ['op', 'init_dialog'], ['op', '0x3C']]
    ft = sv.get('first_time')
    if ft is not None:
        # S127 r4 (user: "Why is first visit greyed out?"): the first visit's words
        # instead of the first words, once (the flag remembers it), as the other services
        if not isinstance(ft, dict) or not ft.get('text') or not ft.get('flag'):
            raise BreedError(f"scripts[{it['sid']}].service.first_time: "
                             '{"text": <dialogue id>, "flag": <flag>}')
        fl = prj._flag_index(ft['flag'], 'first_time')
        ops += [['op', 'if_flag_set', fl, '@known'], ['text', ft['text']],
                ['op', 'set_flag', fl], ['op', 'goto', '@asked'], 'label:known']
        if sv.get('intro'):
            ops.append(['text', sv['intro']])
        ops.append('label:asked')
    elif sv.get('intro'):
        ops.append(['text', sv['intro']])
    # the question (block +1, "Why not breed with my [INS 00]?" — the menu
    # itself opens on its YES / NO, as after the vanilla breeders' words)
    ops += [['text', _t(prj, it, 0x01)]]
    ops += _lines_on(n) + [['op', '0x04', 5, base]] + _lines_off(n)
    ops += [['op', '0x3C'], ['text', _t(prj, it, 0)], ['end']]
    ops += ['label:notyet', ['op', '0x3C'],
            ['text', sv.get('not_yet') or _t(prj, it, 0)], ['end']]
    ops += ['label:after', ['op', '0x3C'],
            ['text', sv.get('after') or _t(prj, it, 0)], ['end']]
    return _bottom(ops)


def return_ops(prj, room, its):
    """The room's return script (in front of its entry script): the follow-up
    after the breeding ceremony for the NPC wBreedLast names."""
    gps = [it for it in its if it['kind'] == 'grandpa']
    brs = [it for it in its if it['kind'] == 'breeder']
    base = SV.base_id('grandpa', getattr(prj, 'repo_root', None))
    ops = []
    if gps:
        ops += [['op', 'check_and_branch', f'0x{D951:04X}', 0xF0, '@br_f0'],
                ['op', 'check_and_branch', f'0x{D951:04X}', 0xF1, '@br_f1']]
    if brs:
        ops.append(['op', 'check_and_branch', f'0x{D951:04X}', 0xF2, '@br_f2'])
    ops.append(['op', 'goto', '@br_orig'])
    for code, lst in (('f0', gps), ('f1', gps), ('f2', brs)):
        if not lst:
            continue
        ops.append(f'label:br_{code}')
        ops += [['op', 'write_ram', SV.WSERVICE_LINES, 0]]
        for it in lst[1:]:
            ops.append(['op', 'check_and_branch', W_LAST, it['num'], f"@br_{code}_{it['num']}"])
        ops.append(['op', 'goto', f"@br_{code}_{lst[0]['num']}"])
    for it in gps:
        g = f"g{it['num']}"
        n = it['set_n']
        t = lambda off: _t(prj, it, off)                         # noqa: E731
        ops.append(f"label:br_f0_{it['num']}")
        ops += _face_ops(f'{g}a', it['actor'])
        ops += [['op', '0x0D', 0, '0xFF90', 0], ['op', '0x08'], ['op', 'init_dialog'],
                ['op', 'check_and_branch', f'0x{D9E6:04X}', 0, f'@{g}_nr'],
                ['text', t(0x0E)], f'label:{g}_nr', ['text', t(0x0F)],
                ['op', 'check_and_branch', f'0x{C83C:04X}', 0, f'@{g}_yes'],
                ['text', t(0x11)],
                f'label:{g}_more', ['text', t(0x01)],
                ['op', 'write_ram', W_LAST, it['num']], ['op', '0x4E']]
        ops += _lines_on(n) + [['op', '0x04', 6, base]] + _lines_off(n)
        ops += [['text', t(0x02)], ['op', 'close_text'],
                ['op', 'write_ram', f'0x{D951:04X}', 0], ['op', '0x16'], ['end'],
                f'label:{g}_yes', ['op', '0x60', f'@{g}_short'], ['text', t(0x15)],
                ['op', '0x3A'],
                f'label:{g}_short', ['text', t(0x1E)],
                ['op', 'write_ram', f'0x{D951:04X}', 0], ['end']]
        ops.append(f"label:br_f1_{it['num']}")
        ops += _face_ops(f'{g}b', it['actor'])
        ops += [['op', '0x04', 15, 0], ['op', '0x0D', 0, '0xFF90', 0], ['op', '0x08'],
                ['op', 'init_dialog'], ['text', t(0x18)]]
        ops += _lines_on(n) + [['op', '0x04', 11, base]] + _lines_off(n)
        ops += [['op', 'check_and_branch', f'0x{C83C:04X}', 1, f'@{g}_send'],
                ['op', 'goto', f'@{g}_more'],
                f'label:{g}_send', ['text', t(0x17)], ['op', 'goto', f'@{g}_more']]
    for it in brs:
        b = f"b{it['num']}"
        ops.append(f"label:br_f2_{it['num']}")
        ops += [['op', 'write_ram', f'0x{D951:04X}', 0], ['op', '0x0D', 0, '0xFF90', 0]]
        ops += _face_ops(b, it['actor'])
        if it.get('flag') is not None:
            ops.append(['op', 'set_flag', it['flag']])
        if 'slot' in it:
            ops.append(['op', 'write_ram', f"{W_SLOTS}+{4 * it['slot']}", 2])
        ops += [['op', 'init_dialog'], ['text', _t(prj, it, 0x09)], ['end']]
    return _bottom(ops)


def lower_entries(prj):
    """Every room with a breeding NPC: its entry script (scripts '0') becomes
    the return script + 'label:br_orig' + the room's own entry ops."""
    from . import cutscene_build as CB
    info = getattr(prj, '_breeding', None) or {}
    by_room = {}
    for it in info.values():
        if it['placed']:
            by_room.setdefault(it['room'].get('id'), []).append(it)
    if not by_room:
        return
    scripts = prj.custom.setdefault('scripts', [])
    by_id = {s.get('id'): s for s in scripts}
    for r in prj.rooms:
        its = by_room.get(r.get('id'))
        if not its:
            continue
        its.sort(key=lambda x: x['num'])
        table = r.setdefault('scripts', {})
        orig = by_id.get(table.get('0'))
        if orig is not None and 'ops' not in orig:
            raise BreedError(f"room {r.get('id')}: its entry script {table.get('0')!r} is "
                             'not lowered yet')
        ops = return_ops(prj, r, its) + ['label:br_orig']
        ops += CB._prefix_ops(orig['ops'], 'o_') if orig is not None else [['end']]
        gid = f"breed:{r.get('id')}:entry"
        new = {'id': gid, 'ops': ops,
               'comment': 'S127: the breeding return script + the room\'s entry script'}
        scripts.append(new)
        by_id[gid] = new
        table['0'] = gid


# --------------------------------------------------------------- emitters
def emit_pool_lines(prj):
    """Bank $77 data: BREED_POOL_COUNT, BreedPoolPtrs, the pools (BreedRoll)."""
    pls = pools(prj)
    out = ["; S127 (P3.14e2): breeding pools (custom.breeding_pools; editor2/core/breeders.py).",
           "; Pool: [measure mask (1 level, 2 arena, 4 seen, 8 story), story step,",
           ";  milestones n, dw flag x n, bands n] + per band [level, arena x12,",
           ";  seen / 2, story x step (the band's points), mates n, total weight]",
           ";  + per mate [dw enemy row, db weight]. Read by entry 8 / BreedRoll.",
           f"BREED_POOL_COUNT EQU {len(pls)}",
           "BreedPoolPtrs:"]
    for p in pls:
        out.append(f"    dw BreedPool_{p['n']}   ; {p['n']}: {p['id']}")
    for p in pls:
        out.append(f"BreedPool_{p['n']}:  ; {p['name']} — {', '.join(p['measures']) or 'no scale'}")
        out.append(f"    db ${p['mask']:02x}, {p['step']}, {len(p['milestones'])}")
        for f in p['milestones']:
            out.append(f"    dw ${f:04X}   ; milestone flag")
        out.append(f"    db {len(p['bands'])}")
        for b in p['bands']:
            pts = b['points']
            out.append(f"    db {pts[0]}, {pts[1]}, {pts[2]}, {pts[3]}, {len(b['mates'])}, "
                       f"{b['total']}   ; {b['name']}")
            for e, w in b['mates']:
                out.append(f"    dw {e}")
                out.append(f"    db {w}")
    return out


def scaled_chance_rows(prj):
    """[(lo_level, lo_pct, hi_level, hi_pct)] — the gate rules' chance-by-level
    rows (bank $71 ScaledChanceTable), deduplicated, in first-use order."""
    out = []
    for ru in prj.custom.get('gate_inserts') or []:
        try:
            k = parse_chance_by_level(ru, 'gate_inserts')
        except BreedError:
            continue
        if k is not None and k not in out:
            out.append(k)
    return out


def emit_chance_lines(prj):
    rows = scaled_chance_rows(prj)
    out = ["; S127 (P3.14e2): GATE_ANY = a gate_inserts record for every gate; ScaledChanceTable",
           "; = per chance-by-level rule 100 bytes (the chance in % for an average party",
           "; level 0-99), read by ScaledChance (entry 4). (generated)",
           f"GATE_ANY EQU ${GATE_ANY:02X}",
           "ScaledChanceTable:"]
    for n, k in enumerate(rows):
        t = chance_table(*k)
        out.append(f"    ; row {n}: level {k[0]} -> {k[1]} %, level {k[2]} -> {k[3]} %")
        for i in range(0, 100, 20):
            out.append("    db " + ", ".join(str(x) for x in t[i:i + 20]))
    if not rows:
        out.append("    db 0                  ; (no chance-by-level rule)")
    return out


# --------------------------------------------------------------- validation
def validate(prj):
    errors, warnings = [], []
    if getattr(prj, 'breed_error', None):
        return [prj.breed_error], warnings
    try:
        pools(prj)
    except BreedError as ex:
        return [str(ex)], warnings
    info = getattr(prj, '_breeding', None) or {}
    used_pools = set()
    for sid, it in info.items():
        if not it['placed']:
            warnings.append(f"breeding NPC script {sid!r}: no NPC in any room runs it")
        if 'pool' in it:
            used_pools.add(it['pool'])
        room = it['room']
        if room is not None and F.val(room.get('mapID', 0)) < 0x6B:
            errors.append(f"breeding NPC {sid!r}: only in the project's own rooms")
        sv = it['sv']
        if it['kind'] == 'breeder' and sv.get('after') and not sv.get('once') and 'slot' not in it:
            warnings.append(f"breeder {sid!r}: 'after' is said only with 'once' (the flag ON)")
    for p in pools(prj):
        if p['n'] not in used_pools:
            warnings.append(f"breeding pool {p['id']!r}: no random breeder uses it")
        if len(p['bands']) > 1 and not p['mask']:
            warnings.append(f"breeding pool {p['id']!r}: {len(p['bands'])} bands but no scale "
                            "is checked — the first band is always used")
    return errors, warnings
