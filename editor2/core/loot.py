"""loot.py — what the RANDOM GATES hand out, without the one-only items (S157, ROADMAP E9;
PROJECT_COMPILER §2.65, GATE_GENERATION §5 "S157").

Headless (no Qt).

The user (S157): "If I set an item to permanent (doesnt break) user should not be allowed
to have more than 1 AND that item should NOT appear as a pickup in random gates." A
ONE-ONLY item = used-up chance 0 (items.one_only). Every item a random gate floor gives
comes from three tables (ROM-traced S157, GATE_GENERATION §5):

  * FloorLayoutData ($16:$7436, 16 rows x 48 B, one row per gate CONTENTS row =
    wFloorType3): the item lying on a maze floor (bank $16 MazePlaceItem, kind 0 ->
    SelectFloorType over the row; the pickup, bank $01 jr_001_5aab, puts the row's index
    = the ITEM ID into the bag) and the 8 chests of the treasure room (SetBrd_6db0, the
    same row -> $D9CF-$D9D6, opened by op $37). A row is CUMULATIVE: SelectFloorType rolls
    c = (wRNG2:wRNG1) mod 100 and takes the first non-zero byte >= c (or = 100), so an
    item's share = its byte - the previous non-zero byte (+1 for the first). Vanilla:
    WarpWing 2-5 % in every row; BeastTail / ShinyHarp (the game's permanent items) never.
  * RareChestItems ($16:$6E04, 16 B): the one-rare-chest room's item, 1/16 a row.
  * ColiseumPrizesLow / High ($04:$6F44 / $6F54, 16 B each): the gate Coliseum's prize.

Here (compiler regions gd_floor_loot / gd_rare_chest / gd_coliseum_prizes): a row that
holds a one-only item loses it and its share goes to the row's other items IN PROPORTION
(largest remainder, every kept item keeps at least 1 %); a 16-entry list gets the
dropped entries replaced by the list's other items in turn. A row without a one-only item
is the original bytes (no edits == the original ROM).
"""

from . import items as IT

FLOOR_BANK, FLOOR_ADDR, FLOOR_ROWS, FLOOR_W = 0x16, 0x7436, 16, 48
RARE_BANK, RARE_ADDR = 0x16, 0x6E04
PRIZE_BANK, PRIZE_ADDR = 0x04, 0x6F44
FALLBACK = 1                    # Herb — a row whose every item is one-only


class LootError(ValueError):
    pass


def _rom(repo_root):
    import os
    repo = repo_root or IT._repo(None)
    return open(os.path.join(repo, 'data', 'DWM-original.gbc'), 'rb').read()


def _b(rom, bank, addr, n):
    o = bank * 0x4000 + addr - 0x4000
    return bytes(rom[o:o + n])


def shares(row):
    """{index: percent} of a cumulative row (SelectFloorType: c in 0-99, the first
    non-zero byte >= c, or the byte 100)."""
    out = {}
    for c in range(100):
        for i, v in enumerate(row):
            if v == 0:
                continue
            if v == 100 or v >= c:
                out[i] = out.get(i, 0) + 1
                break
    return out


def rebuild(row, drop):
    """(new 48 bytes, dropped {index: %}) — `row` without the indices in `drop`."""
    sh = shares(row)
    gone = {i: p for i, p in sh.items() if i in drop}
    if not gone:
        return bytes(row), {}
    kept = {i: p for i, p in sh.items() if i not in drop}
    if not kept:
        kept = {FALLBACK: 1}
    tot = sum(kept.values())
    # largest remainder to 100, each kept item at least 1
    raw = {i: p * 100 / tot for i, p in kept.items()}
    q = {i: max(1, int(v)) for i, v in raw.items()}
    rest = 100 - sum(q.values())
    order = sorted(kept, key=lambda i: (-(raw[i] - int(raw[i])), i))
    k = 0
    while rest > 0:
        q[order[k % len(order)]] += 1
        rest -= 1
        k += 1
    while rest < 0:                       # the 1 % floors went over: take from the biggest
        big = max(q, key=lambda i: (q[i], -i))
        q[big] -= 1
        rest += 1
    new = [0] * len(row)
    cum = -1
    for i in sorted(q):
        cum += q[i]
        new[i] = cum
    assert cum == 99, (row, drop, q)
    assert shares(new) == q, (shares(new), q)
    return bytes(new), gone


def replace_list(lst, drop):
    """A uniform 16-entry list without the items in `drop`: each dropped entry becomes the
    list's next kept item (in list order, round robin); none kept -> FALLBACK."""
    kept = [x for x in lst if x not in drop]
    if not kept:
        kept = [FALLBACK]
    out, k = [], 0
    for x in lst:
        if x in drop:
            out.append(kept[k % len(kept)])
            k += 1
        else:
            out.append(x)
    return bytes(out)


def resolve(prj, repo_root=None):
    """{'floor': [48 B] x 16, 'rare': 16 B, 'prize': 32 B, 'dropped': [(where, item, %)],
    'one_only': {ids}}."""
    repo = repo_root or getattr(prj, 'repo_root', None)
    rom = _rom(repo)
    drop = IT.one_only(prj, repo)
    floor, dropped = [], []
    for r in range(FLOOR_ROWS):
        row = _b(rom, FLOOR_BANK, FLOOR_ADDR + FLOOR_W * r, FLOOR_W)
        new, gone = rebuild(row, drop)
        floor.append(new)
        for i, p in sorted(gone.items()):
            dropped.append((f"gate contents row {r}", i, p))
    rare0 = _b(rom, RARE_BANK, RARE_ADDR, 16)
    rare = replace_list(rare0, drop)
    prize0 = _b(rom, PRIZE_BANK, PRIZE_ADDR, 32)
    prize = replace_list(prize0[:16], drop) + replace_list(prize0[16:], drop)
    for where, a, b in (("the rare chest", rare0, rare),
                        ("the Coliseum prizes (low)", prize0[:16], prize[:16]),
                        ("the Coliseum prizes (high)", prize0[16:], prize[16:])):
        for x in sorted(set(a) - set(b)):
            dropped.append((where, x, round(100 * list(a).count(x) / len(a))))
    return {'floor': floor, 'rare': rare, 'prize': prize, 'dropped': dropped,
            'one_only': drop}


def _names(prj, repo):
    return IT.names(prj, repo)


def _row_line(bs):
    return "    db " + ", ".join(f"${x:02x}" for x in bs)


def emit_floor_loot(prj, warnings):
    """Region gd_floor_loot (bank $16 FloorLayoutData's 48 rows of 16 B)."""
    repo = getattr(prj, 'repo_root', None)
    r = resolve(prj, repo)
    out = []
    addr = FLOOR_ADDR
    for row in r['floor']:
        for k in range(0, FLOOR_W, 16):
            out.append(_row_line(row[k:k + 16]) + f" ; ${addr:04X}")
            addr += 16
    return "\n".join(out) + "\n"


def _list_line(bs, nm):
    return _row_line(bs) + "   ; " + " ".join(nm.get(x, f"${x:02X}") for x in bs)


def emit_rare_chest(prj, warnings):
    repo = getattr(prj, 'repo_root', None)
    r = resolve(prj, repo)
    nm = _names(prj, repo)
    return "RareChestItems:\n" + _list_line(r['rare'], nm) + "\n"


def emit_coliseum_prizes(prj, warnings):
    repo = getattr(prj, 'repo_root', None)
    r = resolve(prj, repo)
    nm = _names(prj, repo)
    return ("ColiseumPrizesLow:\n" + _list_line(r['prize'][:16], nm) + "\n"
            + "ColiseumPrizesHigh:\n" + _list_line(r['prize'][16:], nm) + "\n")


def notes(prj, repo_root=None):
    """Plain words for the Items tab: where the project's one-only items no longer appear."""
    try:
        r = resolve(prj, repo_root)
    except Exception:                                  # noqa: BLE001
        return []
    nm = _names(prj, repo_root)
    by = {}
    for where, i, p in r['dropped']:
        by.setdefault(i, []).append((where, p))
    out = []
    for i in sorted(by):
        rows = [w for w, _p in by[i] if w.startswith('gate contents')]
        other = [w for w, _p in by[i] if not w.startswith('gate contents')]
        parts = []
        if rows:
            ps = [p for w, p in by[i] if w.startswith('gate contents')]
            parts.append(f"the floors and treasure chests of {len(rows)} gate contents "
                         f"row(s) ({min(ps)}-{max(ps)} %, now shared by the other items)")
        parts += other
        out.append(f"{nm.get(i, i)}: no longer found in " + "; ".join(parts) + ".")
    return out


REGIONS = [('gd_floor_loot', 'patches/bank_016.asm', emit_floor_loot, 0x16),
           ('gd_rare_chest', 'patches/bank_016.asm', emit_rare_chest, 0x16),
           ('gd_coliseum_prizes', 'patches/bank_004.asm', emit_coliseum_prizes, 0x04)]
