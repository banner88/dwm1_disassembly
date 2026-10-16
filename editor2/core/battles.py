"""battles.py — enemy rows and battle lists at campaign scale (S149, ROADMAP ARC CAP5).

Headless (no Qt). Owning docs: PROJECT_COMPILER §2.57 (the plan + emitters),
MONSTER_DATA "Project enemy rows" (the engine), DATA_STRUCTURES "Encounter list
choice" (the lists).

Before S149 a project had at most 640 enemy rows (bank $6B, one full bank) and
128 battle lists of its own (bank $76, numbers 128-255) — about one original
game's worth of battles (the game itself uses 128 lists and 487 rows). Now:

  * ENEMY ROWS (progression.enemies, EIDs 519 + n, dense): up to ROW_CAP =
    3,321 (EIDs 519-3839; $0F00+ are the random breeders' slots, bank $14
    LoadEnemyStatsExt). Bank $6B keeps its pinned head, RowBankTable, a gender
    code per row (ProjectEnemyGender) and the first `rows_here` rows; the rest
    go to BATTLE BANKS $80+ (templates/battle_bank.asm) in row order.
  * BATTLE LISTS (custom.encounter_lists, numbers 128 + n): up to LIST_CAP =
    3,968 (numbers 128-4095, 16-bit in bank $76's tables). Bank $76 keeps the
    first LISTS_HOME; the rest go to battle banks after the rows.
  * GENDER (progression.enemies[].gender = 'rolled' | 'male' | 'female';
    absent = 'rolled'): the creation gender of a monster made from the row
    (a join, a gift) — the vanilla EnemyGroupTable meaning ($FF rolled by the
    species' ratio / $00 / $01). Bank $14 EnemyGenderCode reads it through
    bank $6B entry 1 (patches/bank_014.asm); the vanilla table only covers
    EIDs 0-511 and its unbounded read had given every project row a fixed or
    junk gender (measured S149). A project row never takes a rival tamer's
    master name / nickname / the egg flag (bank $14 ForeignNamesGate).

The battle banks are taken from Project._take_ext_bank('battles') after the
stream / place / animation / song banks. A project that fits banks $6B / $76
uses no battle bank.
"""

from . import formats as F

BANK_SIZE = 0x4000
ROW_BYTES = 25
LIST_BYTES = 26
PROJECT_EID_BASE = 519
BREEDER_SLOT_EIDS = 0x0F00            # $0F00+k = a random breeder's mate (S127)
ROW_CAP = BREEDER_SLOT_EIDS - PROJECT_EID_BASE          # 3,321 rows
LIST_BASE = 0x80
LIST_CAP = 0x1000 - LIST_BASE                            # 3,968 lists (128-4095)
LISTS_HOME = 256                      # project lists kept in bank $76
GENDERS = {'rolled': 0xFF, 'male': 0x00, 'female': 0x01}
GENDER_NAMES = {v: k for k, v in GENDERS.items()}
# a battle bank's fixed part: self-ID + 2 entry words + the copier block
# (templates/battle_bank.asm) = addr(the first generated label) - $4000,
# measured from the S149 test build's game.sym
BATTLE_TEMPLATE_SIZE = 76
MARKER_6B = 'BATTLE DATA (generated'
MARKER_EXT = 'BATTLE BANK DATA (generated'


class BattleError(ValueError):
    pass


def gender_code(e, ctx=''):
    g = e.get('gender', 'rolled')
    if g not in GENDERS:
        raise BattleError(f"{ctx}: gender {g!r} — 'rolled', 'male' or 'female'")
    return GENDERS[g]


def suffix(bank):
    return f"_B{bank:02X}"


def battle_bank_file(bank):
    return f"bank_{bank:03x}.asm"


def _counts(prj):
    rows = prj.quest_enemy_rows()
    lists = prj.custom.get('encounter_lists') or []
    return rows, (lists if isinstance(lists, list) else [])


def plan(prj):
    """Where every project enemy row and battle list lives (cached on the
    Project; Project.stream_plan drops it with the other plans).

    {'rows': n, 'rows_here': k, 'lists': m, 'lists_here': j,
     'banks': [{'bank': b, 'rows': (first, count), 'lists': (first, count)}],
     'bytes_6b': …}"""
    got = getattr(prj, '_battle_plan', None)
    if got is not None:
        return got
    from .validators import TEMPLATE_SIZE
    rows, lists = _counts(prj)
    n, m = len(rows), len(lists)
    if n > ROW_CAP:
        raise BattleError(f"progression.enemies: {n} rows — at most {ROW_CAP:,} "
                          f"(EIDs {PROJECT_EID_BASE}-{BREEDER_SLOT_EIDS - 1}; "
                          f"${BREEDER_SLOT_EIDS:04X}+ are the random breeders' slots)")
    if m > LIST_CAP:
        raise BattleError(f"custom.encounter_lists: {m} lists — at most {LIST_CAP:,} "
                          f"(numbers {LIST_BASE}-{LIST_BASE + LIST_CAP - 1})")
    head = TEMPLATE_SIZE[0x6B]
    lists_here = min(m, LISTS_HOME)
    cap_ext = BANK_SIZE - BATTLE_TEMPLATE_SIZE

    def layout(n_row_banks):
        free = BANK_SIZE - head - 3 * n_row_banks - n
        rows_here = min(n, max(1, free // ROW_BYTES)) if n else 0
        banks, left_rows, first_row = [], n - rows_here, rows_here
        left_lists, first_list = m - lists_here, lists_here
        while left_rows or left_lists:
            room = cap_ext
            take_r = min(left_rows, room // ROW_BYTES)
            room -= take_r * ROW_BYTES
            take_l = min(left_lists, room // LIST_BYTES) if not left_rows - take_r else 0
            banks.append({'rows': (first_row, take_r), 'lists': (first_list, take_l)})
            first_row += take_r
            left_rows -= take_r
            first_list += take_l
            left_lists -= take_l
        return rows_here, banks

    k = 0
    for _ in range(8):                         # RowBankTable size fixed point
        rows_here, banks = layout(k)
        k2 = sum(1 for b in banks if b['rows'][1])
        if k2 == k:
            break
        k = k2
    used_6b = head + 3 * k + n + max(1, rows_here) * ROW_BYTES
    if used_6b > BANK_SIZE:
        raise BattleError(f"bank $6B: {used_6b} > {BANK_SIZE} bytes (rows {rows_here})")
    out = {'rows': n, 'rows_here': rows_here, 'lists': m, 'lists_here': lists_here,
           'banks': banks, 'bytes_6b': used_6b}
    if banks:
        # streams, places, animations, songs number first, whoever asks first
        # (music.song_ext_banks numbers the animation banks only when it needs a bank)
        from . import music as MU, tileanim as TA
        TA.plan(prj)
        MU.song_ext_banks(prj)
        taken0 = list(getattr(prj, '_ext_taken', None) or [])
        try:
            for b in banks:
                b['bank'] = prj._take_ext_bank('battles')
        except Exception:
            prj._ext_taken = taken0
            raise
    prj._battle_plan = out
    return out


def battle_bank_files(prj):
    """{bank $80+: 'bank_0xx.asm'} of the battle banks."""
    return {b['bank']: battle_bank_file(b['bank']) for b in plan(prj)['banks']}


def row_bank_of(prj, eid):
    """The ROM bank of a project row (bank $6B or a battle bank)."""
    P = plan(prj)
    i = eid - PROJECT_EID_BASE
    if i < P['rows_here']:
        return 0x6B
    for b in P['banks']:
        f, c = b['rows']
        if f <= i < f + c:
            return b['bank']
    raise BattleError(f"EID {eid}: not a project row")


def list_bank_of(prj, number):
    P = plan(prj)
    i = number - LIST_BASE
    if i < P['lists_here']:
        return 0x76
    for b in P['banks']:
        f, c = b['lists']
        if f <= i < f + c:
            return b['bank']
    raise BattleError(f"list {number}: not a project list")


def _row_lines(e):
    from .emitters import enemy_row_bytes
    b = enemy_row_bytes(e)
    what = (f"EID {e['_eid']} {e['id']} — species {b[0]} L{b[4]}, "
            f"joinability {b[3]}")
    if e.get('join_as') is not None:
        what += f", joins as {e.get('join_as')}"
    return [f"ProjectEnemy_{e['_eid']}:   ; {what}", F.db_line(b)]


def emit_bank_06b(prj, warnings):
    from .emitters import template
    P = plan(prj)
    rows, _lists = _counts(prj)
    lines = [template('bank_06b_head.asm').rstrip('\n'), "",
             "; " + "=" * 77,
             f"; {MARKER_6B} by editor2/core/battles.py from progression.enemies —",
             "; PROJECT_COMPILER §2.57). Row = EID - 519; an empty project keeps one zero row.",
             "; " + "=" * 77,
             f"PROJECT_EID_BASE EQU {PROJECT_EID_BASE}",
             f"PROJECT_ENEMY_ROWS EQU {max(1, len(rows))}",
             f"ROWS_HERE EQU {max(1, P['rows_here'])}",
             "RowBankTable:  ; [dw end row (exclusive), db battle bank] in row order"]
    for b in P['banks']:
        f, c = b['rows']
        if c:
            lines.append(f"    dw {f + c}\n    db ${b['bank']:02X}   ; rows {f}-{f + c - 1} "
                         f"(EIDs {PROJECT_EID_BASE + f}-{PROJECT_EID_BASE + f + c - 1})")
    lines.append("ProjectEnemyGender:  ; per row: $FF rolled by the species' ratio, "
                 "$00 male, $01 female")
    codes = [gender_code(e, f"progression.enemies[{e.get('id')}]") for e in rows]
    for i in range(0, len(codes), 16):
        lines.append(F.db_line(codes[i:i + 16], comment=f"rows {i}-{min(i + 16, len(codes)) - 1}"))
    lines.append("ProjectEnemyRows:")
    if not rows:
        lines.append(F.db_line([0] * 25, comment="(no project enemies)"))
    for e in rows[:P['rows_here']]:
        lines += _row_lines(e)
    return "\n".join(lines) + "\n"


def list_home_lines(prj):
    """Bank $76's part: LISTS_HERE + ListBankTable (encounters.emit_bank_076)."""
    P = plan(prj)
    out = [f"LISTS_HERE EQU {P['lists_here']}",
           "ListBankTable:  ; [dw end list index (exclusive), db battle bank] (S149)"]
    for b in P['banks']:
        f, c = b['lists']
        if c:
            out.append(f"    dw {f + c}\n    db ${b['bank']:02X}   ; lists "
                       f"{LIST_BASE + f}-{LIST_BASE + f + c - 1}")
    return out


def list_lines(entry):
    r = entry['bytes']
    eids = [r[10 + 2 * k] | r[11 + 2 * k] << 8 for k in range(5)]
    return [f"; list {entry['number']}: {entry['id']}",
            "    db " + ", ".join(f"${b:02X}" for b in r[0:10]),
            "    dw " + ", ".join(str(x) for x in eids),
            "    db " + ", ".join(f"${b:02X}" for b in r[20:26])]


def emit_battle_bank(prj, b):
    from .emitters import template
    from . import encounters as EN
    bank = b['bank']
    B = suffix(bank)
    rows, _l = _counts(prj)
    fr, cr = b['rows']
    fl, cl = b['lists']
    lines = ["; " + "=" * 77,
             f"; BANK ${bank:02X} — a battle bank (S149, ROADMAP ARC CAP5; GENERATED by",
             "; editor2/core/battles.py — do not hand-edit): enemy rows past bank $6B,",
             "; battle lists past bank $76.",
             "; " + "=" * 77, "",
             f'SECTION "ROM Bank ${bank:03X}", ROMX[$4000], BANK[${bank:02X}]', "",
             f"    db ${bank:02X}                          ; bank self-ID at $4000", ""]
    text = template('battle_bank.asm').replace('{B}', B)
    if '{B}' in text:
        raise RuntimeError("battle_bank.asm: an unreplaced {…} placeholder")
    lines += [text.rstrip('\n'), "",
              f"; {MARKER_EXT} — rows {fr}-{fr + cr - 1 if cr else '-'}, "
              f"lists {LIST_BASE + fl}-{LIST_BASE + fl + cl - 1 if cl else '-'})",
              f"ROW_FIRST{B} EQU {PROJECT_EID_BASE + fr}",
              f"LIST_FIRST{B} EQU {fl}",
              f"BattleRows{B}:"]
    for e in rows[fr:fr + cr]:
        lines += _row_lines(e)
    lines.append(f"BattleLists{B}:")
    if cl:
        m = EN.resolve(prj)
        for entry in m.lists[fl:fl + cl]:
            lines += list_lines(entry)
    return "\n".join(lines) + "\n"


def emit_battle_banks(prj, warnings):
    """multi:battle_banks — one whole file per battle bank $80+ (none when $6B /
    $76 hold everything)."""
    return {f"file:patches/{battle_bank_file(b['bank'])}": emit_battle_bank(prj, b)
            for b in plan(prj)['banks']}


def layout(prj):
    """S149: where every project row / list is (census + tests read the ROM
    through game.sym): {'rows': [(eid, bank)], 'lists': [(number, bank)]}."""
    P = plan(prj)
    rows, lists = _counts(prj)
    return {'rows': [(e['_eid'], row_bank_of(prj, e['_eid'])) for e in rows],
            'lists': [(LIST_BASE + i, list_bank_of(prj, LIST_BASE + i))
                      for i in range(len(lists))],
            'banks': [dict(b) for b in P['banks']]}
