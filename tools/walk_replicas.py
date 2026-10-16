#!/usr/bin/env python3
"""walk_replicas.py — S148 (ROADMAP ARC CAP4 "$3E" box): copies of game rooms play like
the game (PyBoy on the user's .sav).

Make editable (tools/extract_room.py) stopped a script at op $16 until S148 ("refresh
sprites" only yields — BANK04_SCRIPT_ENGINE "$16"); the copy then fell into the next
block. The demo (examples/s148_replica_demo/build_demo.py) puts a Castle copy (every
state, following the game) and a Priest-floor copy (the default kept state) behind THE
REPLICA HALL. Every script word the game runs is logged at MarkScriptActive ($04:$5613,
BC = the word; PYBOY_DEBUGGING S148).

  guide   CONTINUE; the REPLICA GUIDE in Cities_FOUNT (YES) -> the hall;
  castle  the party's HP poked to 1, a free bag slot; the CASTLE GUIDE (YES): the
          REPLICA CASTLE's arrival as home from a gate ($D92B 6, $D9E3 0) — the copy's
          script 0 runs the priest's blessing, the heal ($27), refresh sprites ($16), the
          King-code tests and the HERB (give_item 1): the bag holds one more Herb, the
          party is healed, and the A/B: the same arrival in the ORIGINAL Castle (map
          $00) of the same ROM runs the same sequence of script words, arrival to end;
  spar    the SPARRING SLIME (YES): a battle, won; back in the hall;
  priest  the hall's STAIRS (a real door) down to the REPLICA PRIEST FLOOR; HP poked to 1;
          the priest (across the altar, script 2): "Let there be light! HEAL!!!", the
          heal, $16, restore_bgm ($4B) and the END — his other line (text $09F6) never
          runs, the room's song is back, the party is healed; the hole = back up.

  python3 tools/walk_replicas.py --build DEMO/build/build --project DEMO/project.json \
      --sav USER.sav --keep KEEP [--negative]

--negative: the same walk on a build of the same demo whose copies were made by the
S92-S147 copy tool (`build_demo.py … --legacy-copies`): the Herb / the A/B / the priest's
checks must FAIL (S148: 7 FAIL).
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, GAME_MODE, PARTY_LIST            # noqa: E402
from tools.walk_regions import Walk, s_continue, BAG                  # noqa: E402

SCRIPT_TYPE, SCRIPT_ID, SCRIPT_CTR = 0xD8D3, 0xD8D4, 0xD8D5
CASTLE_EVENT, KING_CODE = 0xD92B, 0xD9E3
WBGM = 0xC8B5                        # wCurrPlayingBGM (set_bgm saves it in $C8B6)
HERB = 1
HEAL_WORD, REFRESH_WORD = 0xFF27, 0xFF16
PARTY_REFRESH_WORD = 0xFF35          # refresh_party2: the priest's heal
GIVE_ITEM_WORD, RESTORE_BGM_WORD = 0xFF2A, 0xFF4B
PRIEST_OTHER_TEXT = 0x09F6           # "Every journey has its dangers…" (the healthy line)


class Trace:
    """Every script word dispatched: (map type, script id, counter, word)."""

    def __init__(self, w):
        self.w, self.rows = w, []
        b, a = w.sym.get('MarkScriptActive', (0x04, 0x5613))
        w.p.hook_register(b, a, self._cb, None)

    def _cb(self, _ctx):
        m, rf = self.w.m, self.w.p.register_file
        ctr = m[SCRIPT_CTR] | m[SCRIPT_CTR + 1] << 8
        self.rows.append((m[SCRIPT_TYPE], m[SCRIPT_ID], ctr, (rf.B << 8) | rf.C))

    def words(self, mtype, sid=None):
        return [r[3] for r in self.rows if r[0] == mtype and (sid is None or r[1] == sid)]


def party(w):
    m = w.m
    out = []
    for k in range(3):
        s = m[PARTY_LIST + k]
        if s != 0xFF:
            b = 0xCAC1 + 149 * s
            out.append((m[b + 0x50] | m[b + 0x51] << 8, m[b + 0x52] | m[b + 0x53] << 8))
    return out


def herbs(w):
    return sum(1 for i in range(20) if w.m[BAG + i] == HERB)


def free_slot(w):
    if all(w.m[BAG + i] != 0xFF for i in range(20)):
        w.m[BAG + 19] = 0xFF


def stand(w, mid, x, y, face):
    w.goto(mid, 0, x, y)
    w.face(face)
    adv(w.p, 20)


def arrive_as_from_gate(w, mid, tr):
    """$D92B 6 / $D9E3 0, warp onto (14, 5) = screen 1 cell (4, 5) — the throne room
    cell every vanilla boss tail uses; the room's script 0 then plays; returns its words."""
    m = w.m
    party_low(w)
    free_slot(w)
    m[CASTLE_EVENT] = 6
    m[KING_CODE] = 0
    n0 = len(tr.rows)
    w.goto(mid, 0, 14, 5)
    w.follow(3000, until=lambda: not (m[0xD8D7] & 1) and m[GAME_MODE] == 1)
    w.idle()
    return [r for r in tr.rows[n0:] if r[0] == (mid & 0xFF) and r[1] == 0]


def party_low(w):
    w.party_hp_1()


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true',
                    help='(the build given is the legacy-copy build: the checks must FAIL)')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    d = json.load(open(a.project))
    rooms = {r['name']: int(str(r['mapID']), 16) for r in d['custom']['rooms']}
    hall, castle, priest = rooms['REPLICA HALL'], rooms['REPLICA CASTLE'], \
        rooms['REPLICA PRIEST FLOOR']
    cities = next(int(str(r['mapID']), 16) for r in d['custom']['rooms']
                  if r['id'] == 'cities_fount')
    w = Walk(a.build, a.sav, a.keep)
    if a.negative:
        print('NEGATIVE CONTROL: the copies were made by the S92-S147 copy tool')
    s_continue(w)
    tr = Trace(w)

    print('guide: the REPLICA GUIDE in Cities_FOUNT')
    stand(w, cities, 3, 5, 'up')
    res = w.talk(answers=[True])
    w.idle()
    w.check('the REPLICA GUIDE (YES) -> THE REPLICA HALL', w.where()[0] == hall,
            f'{res}, at ${w.where()[0]:02X}')
    w.snap('hall')

    print('castle: the CASTLE GUIDE -> the REPLICA CASTLE, home from a gate')
    stand(w, hall, 2, 4, 'up')
    party_low(w)
    free_slot(w)
    h0 = herbs(w)
    n0 = len(tr.rows)
    res = w.talk(answers=[True])
    m = w.m
    w.follow(3000, until=lambda: not (m[0xD8D7] & 1) and m[GAME_MODE] == 1
             and w.where()[0] == castle)
    w.idle()
    w.check('the CASTLE GUIDE (YES) -> the REPLICA CASTLE', w.where()[0] == castle,
            f'{res}, at ${w.where()[0]:02X}')
    rows = [r for r in tr.rows[n0:] if r[0] == castle and r[1] == 0]
    ws = [r[3] for r in rows]
    w.check('the copy ran the blessing\'s heal ($27) and refresh sprites ($16)',
            HEAL_WORD in ws and REFRESH_WORD in ws, f'{len(ws)} words')
    k16 = ws.index(REFRESH_WORD) if REFRESH_WORD in ws else len(ws)
    w.check('after $16 the copy gave the Herb (give_item 1)',
            GIVE_ITEM_WORD in ws[k16:], ' '.join(f'{x:04X}' for x in ws[k16:k16 + 12]))
    w.check('the bag holds one more Herb', herbs(w) == h0 + 1, f'{h0} -> {herbs(w)}')
    hp = party(w)
    w.check('the party is healed', all(c == mx for c, mx in hp), str(hp))
    copy_seq = ws
    w.snap('castle_copy')

    print('castle A/B: the same arrival in the ORIGINAL Castle (map $00) of the same ROM')
    orig = arrive_as_from_gate(w, 0x00, tr)
    orig_seq = [r[3] for r in orig]
    w.check('the original Castle ran the same script words, arrival to end',
            copy_seq == orig_seq and len(orig_seq) > 5,
            f'copy {len(copy_seq)} words, original {len(orig_seq)}; first difference at '
            f'{next((i for i, (x, y) in enumerate(zip(copy_seq, orig_seq)) if x != y), "-")}')

    print('sparring: the SPARRING SLIME (YES) — a fight, back in the hall')
    stand(w, hall, 5, 5, 'up')
    hp0 = party(w)
    res = w.talk(answers=[True])
    won = res == 'battle' and w.battle_won()
    w.idle()
    w.check('the SPARRING SLIME fought and the hall came back', won and w.where()[0] == hall,
            f'{res}, at ${w.where()[0]:02X}; HP {hp0} -> {party(w)}')

    print('priest: the hall STAIRS -> the REPLICA PRIEST FLOOR')
    stand(w, hall, 8, 2, 'up')
    w.step('up')
    w.idle()
    w.check('the STAIRS (a real door) -> the REPLICA PRIEST FLOOR', w.where()[0] == priest,
            f'at ${w.where()[0]:02X}')
    stand(w, priest, 4, 4, 'up')     # across the altar: the examine spot (4, 3) = script 2
    party_low(w)
    song = m[WBGM]
    n0 = len(tr.rows)
    res = w.talk()
    w.idle()
    rows = [r for r in tr.rows[n0:] if r[0] == priest]
    ws = [r[3] for r in rows]
    w.check('the priest healed ($35 refresh_party2) and refreshed the sprites ($16)',
            PARTY_REFRESH_WORD in ws and REFRESH_WORD in ws,
            ' '.join(f'{x:04X}' for x in ws[-6:]))
    k16 = ws.index(REFRESH_WORD) if REFRESH_WORD in ws else len(ws)
    w.check('after $16: restore_bgm ($4B), then the end', ws[k16 + 1:k16 + 2] ==
            [RESTORE_BGM_WORD] and len(ws) == k16 + 2,
            ' '.join(f'{x:04X}' for x in ws[k16:k16 + 6]))
    w.check('his other line (text $09F6) never ran', PRIEST_OTHER_TEXT not in ws)
    w.check('the room\'s song is back (the heal tune $41 replaced by it again)',
            m[WBGM] == song and 0xFF41 in ws, f'${song:02X} -> ${m[WBGM]:02X}')
    hp = party(w)
    w.check('the party is healed', all(c == mx for c, mx in hp), str(hp))
    w.snap('priest_copy')
    stand(w, priest, 8, 3, 'up')
    w.step('up')
    w.idle()
    w.check('the hole (a real door) -> back up to THE REPLICA HALL', w.where()[0] == hall,
            f'at ${w.where()[0]:02X}')
    print(f'WALK: {"PASS" if not w.fails else "FAIL %d" % w.fails} ({w.checks} checks)')
    if a.negative:
        print('(negative control: FAILs expected)')
    return 1 if w.fails and not a.negative else 0


if __name__ == '__main__':
    sys.exit(main())
