"""capacity.py — every ceiling a project can reach, in words (S145, ROADMAP ARC CAP4d).

EDITOR_DESIGN §5.C ("no invisible ceilings") + §6.4 D/E. The Capacity page and the
two status-bar meters read ONE report from `measure(data, project_dir, repo_root)`:

  * ROM space: the bytes a project's rooms, texts, screens, tilesets and animated tiles
    can fill — banks $60 / $64 / $67 / $6C and the 4 MB ROM's 128 new banks $80-$FF
    (every one of them fills first fit and spills into the next; ARCHITECTURE "ROM banks
    $80-$FF", PROJECT_COMPILER §2.44-§2.48). When the new banks are all taken the build
    stops ("the ROM is full", `Project._take_ext_bank`).
  * Rooms: the place count against what binds FIRST — measured S145 on a fresh project
    of 10-200 rooms: bank $71 grows PLACE_BYTES_71 (15) B a place (8 record + 3
    encounters + 1 animation + 1 flags + 2 songs, PROJECT_COMPILER §2.49), bank $76
    PLACE_BYTES_76 (3); bank $71 does not spill, so its free bytes / 15 is the room
    ceiling (≈950 for a project with few other bank-$71 rows), before the regions' id
    space (63 × 128) and the ROM space.
  * "About N more rooms like your average one": the content bytes the project's rooms
    use over a blank project's, per room, against the free content space — and against
    bank $71 — whichever is fewer.
  * Every secondary ceiling of the compiler (EDITOR_DESIGN §6.4 E), counted the way the
    build counts it: the constants are the modules' own (`story.STORY_CHECK_MAX`, …), the
    counts come from the same Project after the same emitters ran.
  * Per room / per screen ceilings show the fullest one by name (the largest room's
    screens of 16, the fullest screen's people of 8, the longest door list of 17, the
    biggest room's scripts + lists of one place bank, its animated tiles of one bank).
  * Screens per region (S145 finding): a region's step counters share the 640-byte area
    (`wram.region_size`, PROJECT_COMPILER §2.6 / §2.49). S146 (ROADMAP ARC CAP5): only a
    screen with states (or whose counter a script names) has a byte of its own — the
    one-state screens share `wCustomStepZero` (`Project.step_counter_use`).

Never shows a map id or a region unless `place_names.SHOW_IDS` (CAP4b): a region is "a
group of up to 128 rooms" named by its first room.

Headless (no Qt): the report is plain data; `editor2/app/capacity_tab.py` draws it,
`app/space_meter.py` shows two of its numbers.
"""

import time

from . import formats as F

BANK_SIZE = 0x4000
EXT_FIRST, EXT_LAST = 0x80, 0xFF
EXT_COUNT = EXT_LAST - EXT_FIRST + 1                 # 128 new banks (S134)
SPILL_HOME = (0x60, 0x64, 0x67, 0x6C)                # banks that fill first, then spill
CONTENT_CAP = (len(SPILL_HOME) + EXT_COUNT) * BANK_SIZE   # 2,162,688 B
PLACE_BYTES_71 = 15      # bank $71 per place (S140 tables; measured S145: 15.0 B/place)
PLACE_BYTES_76 = 3       # bank $76 per place (EncRoomTable row; measured S145: 3.0 B/place)
REGION_PLACES = 0xEA - 0x6B + 1                      # 128 places a region
TYPICAL_ROOM_BYTES = 3500    # S133: ≈3-4 KB per new place (used while a project has no room)
NEAR = 0.80                  # amber from here
FIXED_BANK_KIND = {0x6F: 'new battle animations', 0x70: 'new battle animation tiles',
                   0x71: 'per-room tables (records, songs, battles)',
                   0x76: 'encounter lists + gates',
                   0x6B: 'enemy rows (then battle banks $80+, S149)', 0x77: 'shops, services, story checks'}
SPILL_KIND = {0x60: 'rooms (scripts, people, doors, colours) + texts',
              0x64: 'screen layouts + colour grids', 0x67: 'tilesets',
              0x6C: 'animated tiles'}

_BASELINE = {}               # repo -> content bytes of a blank project (per process)


class Row(dict):
    """One line of the page. Keys: key, group, what (plain words), used, limit
    (None = no fixed number), shown (the text for used/limit), level ('ok' | 'near'
    | 'full' | 'unknown'), at_limit (what happens there), tab (the tab that edits
    it), where (the room / screen that is fullest, or ''), tech (technical detail —
    shown with View → Show technical ids)."""


def _level(used, limit):
    if used is None or not limit:
        return 'unknown'
    if used >= limit:
        return 'full'
    return 'near' if used >= NEAR * limit else 'ok'


def _row(key, group, what, used, limit, at_limit, tab, where='', tech='', shown=None,
         level=None, room=None, screen=None):
    r = Row(key=key, group=group, what=what, used=used, limit=limit, at_limit=at_limit,
            tab=tab, where=where, tech=tech, room=room, screen=screen)
    r['level'] = level or _level(used, limit)
    if shown is None:
        shown = (f'{used:,} of {limit:,}' if limit else f'{used:,}') if used is not None \
            else '?'
    r['shown'] = shown
    return r


def kb(n):
    return f'{n / 1024:,.1f} KB' if n < 1024 * 1024 else f'{n / 1048576:,.2f} MB'


# ------------------------------------------------------------------ bank space
def content_space(usage):
    """(used, free, ext_in_use) of the content banks: $60 / $64 / $67 / $6C + every
    new bank $80-$FF (an untouched new bank = 16,384 B free)."""
    used = sum(usage.get(b, (0, BANK_SIZE))[0] for b in SPILL_HOME)
    ext = {b: u for b, (u, _c) in usage.items() if EXT_FIRST <= b <= EXT_LAST}
    used += sum(ext.values())
    return used, CONTENT_CAP - used, len(ext)


def baseline_content(repo_root):
    """Content bytes of a BLANK project (editor2/templates/blank-project) — the
    template heads, the skill scripts, the region tables: what no room pays for.
    Measured once per process."""
    if repo_root in _BASELINE:
        return _BASELINE[repo_root]
    import json
    import os
    from .compiler import measure_banks
    tpl = os.path.join(repo_root, 'editor2', 'templates', 'blank-project')
    data = json.load(open(os.path.join(tpl, 'project.json')))
    usage, errors = measure_banks(data, tpl, repo_root)
    _BASELINE[repo_root] = content_space(usage)[0] if not errors else None
    return _BASELINE[repo_root]


# ------------------------------------------------------------------ the report
def measure(data, project_dir, repo_root, names=None):
    """The whole report for the in-memory project `data` (the editor's unsaved
    document; copied here). Returns a dict:
      rows      [Row] in page order
      usage     {bank: (used, cap)} (every generated bank)
      content   {'used', 'free', 'cap', 'ext', 'baseline'}
      rooms     {'count', 'ceiling', 'by'}  — the room ceiling and what sets it
      left      {'rooms', 'by', 'avg'}      — "about N more rooms like your average one"
      errors    [str] — validation errors (bank rows are then unknown)
      seconds   float
    `names` = a place_names.Places for room names (else the rooms' own names)."""
    from .document import fast_copy
    from .project import Project
    from . import validators as V
    from .compiler import _emit_all
    t0 = time.perf_counter()
    prj = Project(fast_copy(data), project_dir)
    prj.repo_root = repo_root
    rep = {'rows': [], 'usage': {}, 'errors': [], 'content': {}, 'rooms': {}, 'left': {}}
    try:
        errors, _w = V.validate(prj)
    except Exception as e:                       # noqa: BLE001 — never break the page
        errors = [str(e)]
    rep['errors'] = list(errors)
    usage = {}
    if not errors:
        try:
            gen, _w = _emit_all(prj)
            usage = V.bank_usage(gen)
        except Exception as e:                   # noqa: BLE001
            rep['errors'].append(str(e))
    rep['usage'] = usage
    rooms = [r for r in (prj.custom.get('rooms') or []) if not r.get('placeholder')]

    def rname(r):
        if names is not None:
            try:
                return names.label(('room', r.get('id')))
            except Exception:                    # noqa: BLE001
                pass
        return r.get('name') or r.get('id') or '?'

    rows = rep['rows']
    n_rooms = len(rooms)
    # ---- ROM space + rooms ------------------------------------------------
    if usage:
        cu, cf, n_ext = content_space(usage)
        base = baseline_content(repo_root)
        rep['content'] = {'used': cu, 'free': cf, 'cap': CONTENT_CAP, 'ext': n_ext,
                          'baseline': base}
        rows.append(_row('rom_space', 'Space', 'ROM space for your rooms, texts, screens, '
                         'tilesets and animated tiles', cu, CONTENT_CAP,
                         'the build stops: "the ROM is full" (every one of the 4 MB ROM\'s '
                         '128 new banks is taken)', 'Rooms',
                         shown=f'{kb(cu)} of {kb(CONTENT_CAP)}',
                         tech=f'banks $60 / $64 / $67 / $6C fill first, then the new banks '
                              f'$80-$FF first fit: {n_ext} of {EXT_COUNT} new banks in use'))
        free71 = BANK_SIZE - usage.get(0x71, (BANK_SIZE, 0))[0]
        free76 = BANK_SIZE - usage.get(0x76, (BANK_SIZE, 0))[0]
        cands = [(n_rooms + free71 // PLACE_BYTES_71, 'bank $71 (15 B a room)'),
                 (n_rooms + free76 // PLACE_BYTES_76, 'bank $76 (3 B a room)'),
                 (63 * REGION_PLACES, 'the room numbers (63 groups of 128)')]
        ceiling, by = min(cands)
        rep['rooms'] = {'count': n_rooms, 'ceiling': ceiling, 'by': by}
        rows.append(_row('rooms', 'Rooms', 'Rooms', n_rooms, ceiling,
                         'the build stops: the table of every room\'s record, songs and '
                         'battles is full', 'Rooms', shown=f'{n_rooms:,} of about {ceiling:,}',
                         tech=f'set by {by}; bank $71 {free71:,} B free, bank $76 '
                              f'{free76:,} B free'))
        avg = None
        if base is not None and n_rooms:
            avg = max(1, (cu - base) // n_rooms)
        typical = avg or TYPICAL_ROOM_BYTES
        by_space = cf // typical
        by_71 = free71 // PLACE_BYTES_71
        left = min(by_space, by_71, max(0, ceiling - n_rooms))
        rep['left'] = {'rooms': left, 'avg': avg, 'typical': typical,
                       'by': 'ROM space' if left == by_space else 'the room table'}
    else:
        rows.append(_row('rom_space', 'Space', 'ROM space for your rooms, texts, screens, '
                         'tilesets and animated tiles', None, CONTENT_CAP,
                         'the build stops: "the ROM is full"', 'Rooms',
                         shown='? (the project does not build yet)'))
        rows.append(_row('rooms', 'Rooms', 'Rooms', n_rooms, None, '', 'Rooms',
                         shown=f'{n_rooms:,}', level='unknown'))
    _room_rows(prj, rooms, rows, rname, usage)
    _project_rows(prj, data, rows)
    rep['seconds'] = time.perf_counter() - t0
    return rep


# ------------------------------------------------------------- per room / screen
def _room_rows(prj, rooms, rows, rname, usage):
    from .project import ProjectError
    # screens per room (engine: 4 × 4 = 16, validators "index outside the 4x4 grid")
    best = max(rooms, key=lambda r: len(r.get('screens') or {}), default=None)
    n = len((best or {}).get('screens') or {})
    rows.append(_row('screens_room', 'Rooms', 'Screens in one room (the largest)', n, 16,
                     'no more screens: a room is at most 4 × 4 screens', 'Rooms',
                     where=rname(best) if best else '', room=(best or {}).get('id')))
    # people per screen-state (engine: 8 NPC slots, capacities.json)
    worst, wn = None, 0
    for r in rooms:
        for k, scr in (r.get('screens') or {}).items():
            for i, st in enumerate(scr.get('states') or [scr]):
                # the people the 8 slots hold (Document.state_capacity's rule:
                # examine spots / step-on triggers ($80+) are not people)
                c = sum(1 for e in (st.get('npcs') or [])
                        if e.get('kind') == 'npc'
                        or (e.get('kind') == 'raw' and F.val(e['bytes'][0]) < 0x80))
                if c > wn:
                    wn, worst = c, (r, k, i, bool(scr.get('states')))
    rows.append(_row('npcs_screen', 'Rooms', 'People on one screen (the fullest)', wn, 8, 'the game has 8 slots a screen: the editor '
                     'refuses a 9th', 'Rooms',
                     where=(f'{rname(worst[0])}, screen {int(worst[1])}'
                            + (f', state {worst[2]}' if worst[3] else '')) if worst else '',
                     room=worst[0].get('id') if worst else None,
                     screen=int(worst[1]) if worst else None))
    # door rows per list (wCustomExitBuffer: 17 rows + the end, validators)
    worst, wn = None, 0
    for r in rooms:
        for k, scr in (r.get('screens') or {}).items():
            for i, st in enumerate(scr.get('states') or [scr]):
                c = len(st.get('exits') or [])
                if c > wn:
                    wn, worst = c, (r, k)
    rows.append(_row('exits_screen', 'Rooms', 'Doors and exits on one screen (the fullest)',
                     wn, 17, 'the build stops: the game copies at most 17 into its buffer',
                     'Rooms', where=f'{rname(worst[0])}, screen {int(worst[1])}'
                     if worst else '', room=worst[0].get('id') if worst else None,
                     screen=int(worst[1]) if worst else None))
    # screens per group: one step-counter byte for each screen with states (S145
    # finding; S146, ROADMAP ARC CAP5: one-state screens share one zero byte —
    # Project.step_counter_use counts what the allocator gives a byte of its own)
    try:
        from .project import STEP_COUNTER_BASE, STEP_GROUP_FULL
        size = prj.wram_region_size
        groups = prj.step_counter_use()
        reg, used = max(groups.items(), key=lambda kv: kv[1], default=(0, 0))
        first = next((r for r in rooms if F.mid_region(F.val(r['mapID'])) == reg), None)
        multi = prj.multi_region()
        tech = (f'step counters ${STEP_COUNTER_BASE:04X}+{size} (wram.region_size); '
                f'region {reg} fullest; one-state screens share wCustomStepZero')
        try:
            prj.step_counter_allocation()
        except ProjectError as e:
            tech = str(e)
        rows.append(_row('screens_group', 'Rooms',
                         'Screens with states in one group of up to 128 rooms (each one '
                         'remembers its state in one byte; one-state screens share one)'
                         if multi else
                         'Screens with states (each one remembers its state in one byte; '
                         'one-state screens share one; every 128 rooms start a new group)',
                         used, size,
                         'the build stops: that group\'s rooms have too many screens with '
                         'states — fewer states, or a new group (new rooms go to the next '
                         f'group once one is {int(STEP_GROUP_FULL * 100)} % full)', 'Rooms',
                         where=(f'the group with {rname(first)}' if multi and first else ''),
                         tech=tech))
    except Exception:                            # noqa: BLE001
        pass
    if not usage:
        return
    # the biggest room's scripts + lists + colours: one place bank (places.plan)
    try:
        from . import places as PL
        from . import validators as V
        plan = PL.plan(prj)
        cap = BANK_SIZE - V.PLACE_TEMPLATE_SIZE
        big, bn = None, 0
        for b, ent in plan['banks'].items():
            for r, lines, _row_ in ent['rooms']:
                s = PL._payload(lines) + PL.ROOM_ROW_BYTES
                if s > bn:
                    bn, big = s, r
        rows.append(_row('room_block', 'Rooms', "One room's talk, people, doors and colours "
                         '(the biggest)', bn, cap, 'the build stops: one room must fit one '
                         'bank — split it into two rooms', 'Rooms',
                         where=rname(big) if big else '', shown=f'{kb(bn)} of {kb(cap)}',
                         room=(big or {}).get('id'),
                         tech='places.room_block + ROOM_ROW_BYTES vs a place bank '
                              '(16,384 − PLACE_TEMPLATE_SIZE)'))
    except Exception:                            # noqa: BLE001
        pass
    try:
        from . import tileanim as TA
        p = TA.plan(prj)
        rb = p.get('room_bytes') or {}
        if rb:
            mid, bn = max(rb.items(), key=lambda kv: kv[1])
            r = prj.room_by_mid(mid) if hasattr(prj, 'room_by_mid') else None
            cap = p.get('room_cap') or BANK_SIZE
            rows.append(_row('anim_room', 'Rooms', "One room's animated tiles (the biggest)",
                             bn, cap, 'the build stops: one room\'s animations must fit one '
                             'bank', 'Rooms', where=rname(r) if r else '',
                             shown=f'{kb(bn)} of {kb(cap)}', room=(r or {}).get('id')))
        groups = 0
        gr = None
        for r in rooms:
            g = len(r.get('tile_anims') or [])
            if g > groups:
                groups, gr = g, r
        if groups:
            rows.append(_row('anim_groups', 'Rooms', 'Animations in one room (the most)',
                             groups, TA.MAX_GROUPS, 'the editor refuses another',
                             'Rooms', where=rname(gr), room=gr.get('id')))
    except Exception:                            # noqa: BLE001
        pass


# ------------------------------------------------------------- project-wide counts
def _project_rows(prj, data, rows):
    custom = data.get('custom') or {}
    prog = data.get('progression') or {}

    def add(key, group, what, fn, limit, at, tab, tech='', shown=None):
        try:
            used = fn()
        except Exception as e:                   # noqa: BLE001
            rows.append(_row(key, group, what, None, limit, at, tab,
                             shown='?', tech=f'not counted: {e}'))
            return
        rows.append(_row(key, group, what, used, limit, at, tab, tech=tech,
                         shown=shown(used) if shown else None))

    # texts: ids $0A00-$FFFF in 246 groups of 256 (places.TEXT_SECTION_BUDGET splits)
    def texts():
        return len(getattr(prj, '_text_by_id', {}) or {})
    add('texts', 'Text and story', 'Texts (lines people say, signs, questions)', texts,
        246 * 256, 'no more text numbers', 'Rooms',
        tech='custom text ids $0A00-$FFFF = 246 sections of 256 (TextSectionBanks)')
    # S150 (ROADMAP P3.6): the game's own texts the project rewrote (gamedata.text);
    # their bytes live in text banks $80+ = part of the ROM space row above
    from . import gametext as GTX

    def game_texts():
        return len(GTX.edits(data))
    add('game_texts', 'Text and story', "The game's own texts you rewrote (dialogue, battle, "
        'items, menus, credits)', game_texts,
        sum(1 for k in GTX.index(getattr(prj, 'repo_root', None)).order
            if not GTX.index(getattr(prj, 'repo_root', None)).entries[k].owner),
        'every one can be rewritten', 'Text',
        tech='gamedata.text: text banks $80+ (any length; ROM0 TextLevel1Hook -> bank $60 '
             'entry 14 -> the text home bank)')
    from . import project as P
    pool = sum(hi - lo + 1 for lo, hi in P.FLAG_AUTO_RANGES)

    def flags():
        n = 0
        for _name, idx in (getattr(prj, '_flags', {}) or {}).items():
            if P.flag_in_pool(idx):
                n += 1
        return n
    add('flags', 'Text and story', 'Flags (yes / no facts the game remembers)', flags, pool,
        'no new flag can be made', 'Progression && Flags',
        tech='$0159-$0167 + $1000-$179D (wExtFlags, saved; EVENT_FLAGS "Extended flags")')
    from . import story as ST
    add('checks', 'Text and story', 'Story checks (questions the game answers: an item, '
        'gold, a monster …)', lambda: len(getattr(prj, '_check_records', []) or []),
        ST.STORY_CHECK_MAX, 'the build stops (the editor\'s own use some: milestones, '
        'quest rewards)', 'Progression && Flags', tech='virtual flags $1800-$18FF')
    add('commands', 'Text and story', 'Different story steps (take / give items, gold)',
        lambda: len(getattr(prj, '_story_cmds', []) or []), ST.STORY_CMD_MAX,
        'the build stops', 'Progression && Flags', tech='op $24 $FF01-$FFFF')
    # S153 (ROADMAP E5): the title screen, the credits, the original story's points
    from . import ending as END

    def title_tiles():
        return len(END.title_layout(custom)[0]) if END.title(custom) else 0
    add('title_tiles', 'Text and story', 'Letters on the title screen (different letters)',
        title_tiles, END.TITLE_MAX_TILES, 'the editor refuses another', 'Cutscenes',
        tech='tiles $80-$FF at $8800 (VRAM bank 1), the title\'s own art keeps bank 0 '
             '(bank $79 entry 3 TitleText)')
    add('credit_pages', 'Text and story', 'Credits pages (the game\'s 27 + yours)',
        lambda: len(END.pages(custom)), END.MAX_PAGES, 'the editor refuses another',
        'Cutscenes', tech='page numbers in $C0D9 (bank $5F regions credits_last_a / _b); '
                          'their words = credits_role / credits_name rows')
    add('story_points', 'Text and story', 'Different points of the original story used '
        '(the "Story point" step)', lambda: len(getattr(prj, '_story_points', []) or []),
        END.MAX_POINTS, 'the build stops', 'Cutscenes',
        tech='bank $79 entry 5 StoryPointApply, StoryPointPtrs')
    # S154: the memorial — statues a room, monsters remembered
    from . import memorial as MM
    add('statues_room', 'Rooms', 'Memorial statues in one room (the most)',
        lambda: max([len(MM.room_statues(r)) for r in custom.get('rooms') or []] or [0]),
        MM.STATUES_MAX, 'the editor refuses another', 'Rooms',
        tech='bank $79 MEM_STATUES (wMemPicks), MemRoomTable')
    add('memorial_cap', 'Text and story', 'Monsters the memorial remembers (its setting)',
        lambda: MM.settings(custom)['cap'] if MM.active(custom) else 0, MM.CAP_MAX,
        'the oldest is forgotten', 'Rooms',
        tech='SRAM bank 3 $A110+, 8 B an entry, a ring of MEM_CAP + 9; wMemCount / wMemHead '
             'saved at $A005 / $A006 (bank $73 MemorialCommit)')
    # S158: the breeding hints — monuments a room, hint numbers, the hint data in bank $79
    from . import hints as HT

    def _hint_pool():
        if not HT.active(custom):
            return None
        try:
            return HT.pool(prj)
        except Exception:                                  # noqa: BLE001 — reported at build
            return None

    add('monuments_room', 'Rooms', 'Hint monuments in one room (the most)',
        lambda: max([len(HT.room_monuments(r)) for r in custom.get('rooms') or []] or [0]),
        HT.MONUMENTS_ROOM_MAX, 'the editor refuses another', 'Rooms',
        tech='bank $79 HINT_SLOTS (wHintLatch: the hint each one showed this visit)')
    add('hint_numbers', 'Text and story', 'Breeding hint numbers (the pool + numbers kept)',
        lambda: (_hint_pool() or ([], 0, {}))[1], HT.POOL_MAX, 'the build stops', 'Breeding',
        tech='SRAM bank 3 $B000 / $B100: two 256-byte bitsets (unlocked, bred)')
    add('hint_bytes', 'Text and story', 'Breeding hint data in bank $79 (bytes)',
        lambda: (HT.data_bytes(prj, *(_hint_pool()[:2]), HT.settings(custom))
                 if _hint_pool() else 0), HT.BANK79_HINT_BUDGET, 'the build stops', 'Breeding',
        tech='HintTable 8 B + a riddle word a number, the archive lists, the riddles')
    from . import services as SV
    add('line_sets', 'Text and story', 'Line sets of shop and service people',
        lambda: len(SV.resolve(prj)['numbers']), SV.MAX_SETS, 'the build stops',
        'Services', tech='the sets a script uses (an "everywhere" set needs no number); '
                         'wServiceLines is one byte')
    add('shops', 'Text and story', 'Shops (the game\'s 5 + yours)',
        lambda: 5 + len(custom.get('shops') or []), 250, 'the build stops', 'Shops',
        tech='wShopID is one byte (shops.py)')
    from . import gates as G
    add('gates', 'Gates, battles and monsters', 'New gates and worlds',
        lambda: len(G.new_gate_entries(custom)),
        G.NEW_GATE_LAST - G.NEW_GATE_FIRST + 1, 'the Gates tab offers no more numbers',
        'Gates', tech='gate numbers 32-95')
    from . import encounters as EN
    add('enc_lists', 'Gates, battles and monsters', 'Battle lists of your own',
        lambda: len(custom.get('encounter_lists') or []), EN.MAX_PROJECT_LISTS,
        'the editor refuses another', 'Encounters',
        tech='list numbers 128-4095; the first 256 in bank $76, then battle banks $80+ '
             '(S149)')
    add('enemies', 'Gates, battles and monsters', 'Enemy rows (bosses, NPC fights, breeding '
        'mates)', lambda: len(prog.get('enemies') or []), P.PROJECT_EID_CAP,
        'the build stops', 'Monsters',
        tech='EIDs 519-3839: bank $6B, then battle banks $80+ (S149; $0F00+ = the '
             'random breeders)')
    add('joins', 'Gates, battles and monsters', 'Bosses that join as another row',
        lambda: len(prj.enemy_redirects()), P.REDIRECT_ROWS_MAX, 'the build stops',
        'Monsters', tech='bank $14 redirect rows')
    from . import breeders as BR
    add('pools', 'Gates, battles and monsters', 'Breeding pools',
        lambda: len(custom.get('breeding_pools') or []), BR.MAX_POOLS, 'the build stops',
        'Services')
    add('species', 'Gates, battles and monsters', 'New monsters',
        lambda: len(custom.get('species') or []), 19,
        'no more: ids 221-239 are the game\'s ceiling', 'Monsters',
        tech='MONSTER_DATA "Species ID geography"')
    from . import custom_skills as CS

    def new_skills():
        sk = ((data.get('gamedata') or {}).get('skills') or {})
        return sum(1 for k in sk if str(k).isdigit() and int(k) in CS.NEW)
    add('skills', 'Gates, battles and monsters', 'New skills', new_skills, len(CS.NEW),
        'the Skills tab offers no more numbers', 'Skills', tech='skill ids 239-254')
    from . import battle_anims as BA
    add('anims', 'Gates, battles and monsters', 'New battle animations',
        lambda: len(BA.custom_list(data)), BA.MAX_CUSTOM, 'the editor refuses another',
        'Animations', tech='$2D-$4C, banks $6F / $70')
    from . import art as AR

    def art():
        return AR.usage(prj)[0]
    add('art', 'Gates, battles and monsters', 'New art for the game\'s monsters (≈58 '
        'monsters with battle and walking art)', art, AR.capacity(), 'the build stops',
        'Monsters', shown=lambda u: f'{kb(u)} of {kb(AR.capacity())}',
        tech='art banks $7F / $7C / $7A')
    from . import music as M

    # S147 (ROADMAP ARC CAP5): one id per song (S116: one per channel — 95 ids were
    # ~31 songs); song data past the two song banks lives in the 4 MB ROM's banks
    # $80+ and is part of the ROM space row above
    def song_ids():
        return len(prj.music_plan().songs)
    add('song_ids', 'Music', 'Songs of your own', song_ids, M.SONG_IDS,
        'the build stops: every song takes one of the 95 song numbers', 'Music',
        tech='ids $9E-$FC, one a song (bank $74 SongDirectory)')

    def song_bytes():
        return prj.music_plan().song_bytes()

    def song_shown(u):
        P = prj.music_plan()
        shared = sum(n for b, n in P.stream_bytes.items() if b not in M.SONG_BANKS)
        return kb(u) + (f' ({kb(shared)} of it in the ROM space)' if shared else '')
    rows_before = len(rows)
    add('song_bytes', 'Music', 'Song data (two song banks of about 31 KB, then the ROM '
        'space your rooms share)', song_bytes, None, 'the ROM space row: "the ROM is full"',
        'Music', shown=song_shown, tech='banks $74 / $75, then banks $80+ (first fit, '
        'one bank a song)')
    if len(rows) > rows_before and rows[-1]['used'] is not None:
        rows[-1]['level'] = 'ok'


def bank_rows(usage):
    """[(bank, used, cap, kind, spills)] for the technical section."""
    out = []
    for b, (u, c) in sorted(usage.items()):
        if b in SPILL_KIND:
            out.append((b, u, c, SPILL_KIND[b], True))
        elif EXT_FIRST <= b <= EXT_LAST:
            out.append((b, u, c, 'a new bank of the 4 MB ROM', True))
        else:
            out.append((b, u, c, FIXED_BANK_KIND.get(b, ''), False))
    return out


EACH = ('screens_room', 'npcs_screen', 'exits_screen', 'room_block', 'anim_room',
        'anim_groups')       # the fullest ONE item: at its limit is a choice, not a warning


def worst(rep):
    """The project-wide rows at or near their limit, fullest first (a room or a screen
    that uses all of its own allowance — 8 people on a screen — is not counted)."""
    rk = {'full': 0, 'near': 1}
    return sorted((r for r in rep['rows'] if r['level'] in rk and r['key'] not in EACH),
                  key=lambda r: (rk[r['level']], -(r['used'] or 0) / (r['limit'] or 1)))
