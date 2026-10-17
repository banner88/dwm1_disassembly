#!/usr/bin/env python3
"""walk_text.py — S150 (ROADMAP P3.6 / Phase F T-author): the game's own texts,
edited, on the real screens (PyBoy on the user's .sav).

The demo (examples/s150_text_demo/build_demo.py) = the user's project + 8 edited
texts + THE SCRIBE'S HALL / THE SCRIBE'S FIELD. Every check reads what the TEXT
ENGINE was handed — a hook on ROM0 CallTextEngine's tail ($05E3: [$C824] = the bank
every byte is read from, [$C82D] = the text) and on RunTextHandler's copy loop end
— plus screenshots of the boxes:

  castle   CONTINUE (the throne room): the LADY by the throne (text $0489) says the
           EDITED speech — read from a text bank $80+, the bytes == the edit, every box;
           a SOLDIER (text $048C, unedited) says the original from bank $48;
  bag      the field menu's ITEM page: "FairyDew" (item 6) and "BayLeaf" (item 10)
           are read from the text bank (bank $41 mode 8 rows 6 / 10), their pages'
           descriptions too (mode 9);
  use      FairyDew used on the lead monster: the field's use line (bank $41 mode 13
           row 3, edited: "… pours 1 … on …") + the item NAME the game COPIES into slot
           $20 ($C180 + $20 — RunTextHandler: copied by the text bank) = "FairyDew";
  hall     the SCRIBE GUIDE (Cities_FOUNT, YES) -> THE SCRIBE'S HALL; the SCRIBE's own
           project text (bank $60 entry 5, unchanged); the QUOTER (a project script
           showing the game's text id $0489) -> the edited speech;
  field    the STAIRS -> THE SCRIBE'S FIELD: a wild battle opens with battle message
           0 / 1 (edited, from the text bank); the battle won; the field comes back.

  python3 tools/walk_text.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative]

--negative: the S150 lookup in the ROM copy (ROM0 TextLevel1Hook's `rst $10` -> `nop`:
no edited text is found): the edited-text checks must FAIL, the unedited pass.
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, PARTY_LIST, MAP_ID  # noqa: E402
from tools.walk_regions import Walk, s_continue                                             # noqa: E402
from editor2.core import gametext as GT, textmark as TM                                      # noqa: E402

SLOT20 = 0xC180 + 0x20


def text_at(rom, bank, addr):
    if 0x4000 <= addr < 0x8000:
        t = TM.scan(rom, bank * 0x4000 + addr - 0x4000)
        return None if t is None else t + b'\xf0'
    return None


class TextWalk(Walk):
    def __init__(self, build, sav, keep, project):
        super().__init__(build, sav, keep)
        from editor2.core.project import Project
        prj = Project.load(project)
        prj.repo_root = REPO
        self.edits = {(x.source, x.key): raw for x, raw in GT.resolve(prj, REPO)}
        self.ix = GT.index(REPO)
        self.romb = open(self.rom, 'rb').read()
        self.shown = []           # (bank, addr, bytes) handed to the text engine
        self.ids = []

    def start(self, state=None):
        super().start(state)
        self.shown, self.ids = [], []
        self.p.hook_register(0, 0x05E3, self._show, None)     # CallTextEngine's tail
        self.p.hook_register(0, 0x0AD9, self._id, None)       # TextBankDispatch (HL = id)
        self.romb = open(self.rom, 'rb').read()

    def _show(self, _ctx):
        m = self.m
        b, a = m[0xC824], m[0xC82D] | m[0xC82E] << 8
        self.shown.append((b, a, text_at(self.romb, b, a)))

    def _id(self, _ctx):
        self.ids.append(self.p.register_file.HL)

    def want(self, source, key):
        e = self.edits.get((source, key))
        if e is not None:
            return e, True
        x = self.ix.get(source, key)
        return x.raw + b'\xf0', False

    def check_text(self, what, source, key, since=0):
        want, edited = self.want(source, key)
        hits = [(b, a, t) for b, a, t in self.shown[since:] if t == want]
        where = ', '.join(f'${b:02X}:${a:04X}' for b, a, _t in self.shown[since:][-4:])
        ok = bool(hits) and all((b >= 0x80) == edited for b, _a, _t in hits)
        self.check(f'{what}: {"the EDIT" if edited else "the original"} of {source} {key} '
                   f'({"a text bank" if edited else "its own bank"})', ok, where)
        return ok

    def talk_snaps(self, name, n=3):
        """A on the NPC faced; a screenshot when each of the first n boxes waits."""
        m, p = self.m, self.p
        tap(p, 'a', hold=3, wait=6)
        k, last, still, f = 0, None, 0, 0
        while f < 6000 and k < n:
            adv(p, 2)
            f += 2
            ptr = m[0xC82D] | m[0xC82E] << 8
            if m[TEXTBOX] & 1 and ptr == last:
                still += 2
                if still >= 30:
                    self.snap(f'{name}_{k}')
                    k += 1
                    tap(p, 'a', hold=2, wait=4)
                    still = 0
            else:
                still = 0
            last = ptr
        self.idle()


def s_castle(w):
    print('castle: the throne room — the lady (edited $0489), a soldier ($048C, original)')
    s_continue(w)
    w.save('continue')
    w.goto(0x00, 0, 13, 6)
    w.face('up')
    n0 = len(w.shown)
    w.talk_snaps('lady', 4)
    w.check('the lady says text $0489', 0x0489 in w.ids, ' '.join(f'${i:04X}' for i in w.ids[-3:]))
    w.check_text('the lady', 'dialogue', '$0489', n0)
    w.start('continue')
    w.goto(0x00, 0, 12, 3)
    w.face('up')
    n0 = len(w.shown)
    w.talk()
    w.idle()
    w.check('the soldier says text $048C', 0x048C in w.ids, ' '.join(f'${i:04X}' for i in w.ids[-3:]))
    w.check_text('the soldier', 'dialogue', '$048C', n0)


def bag_slot(w, item):
    return next((i for i in range(20) if w.m[0xCA51 + i] == item), None)


def s_bag(w):
    print('bag: the ITEM page (FairyDew / BayLeaf) and FairyDew used on the lead monster')
    w.start('continue')
    m, p = w.m, w.p
    for it in (6, 10):
        if bag_slot(w, it) is None:
            k = bag_slot(w, 0xFF)
            m[0xCA51 + k] = it
    n0 = len(w.shown)
    tap(p, 'a', hold=3, wait=90)                  # the field menu
    tap(p, 'right', hold=8, wait=40)
    tap(p, 'a', hold=3, wait=60)                  # ITEM
    w.snap('bag_page')
    w.check_text('the bag lists item 6', 'item_name', '6', n0)
    w.check_text('the bag lists item 10', 'item_name', '10', n0)
    # FairyDew's page: move the cursor onto it
    slot = bag_slot(w, 6)
    for _ in range(slot // 5):
        tap(p, 'right', hold=8, wait=30)
    for _ in range(slot % 5):
        tap(p, 'down', hold=8, wait=20)
    adv(p, 30)
    w.snap('bag_fairydew')
    w.check_text("FairyDew's description", 'item_description', '6', n0)
    n1 = len(w.shown)
    tap(p, 'a', hold=3, wait=60)                  # USE / DEL
    tap(p, 'a', hold=3, wait=60)                  # USE -> whom
    tap(p, 'a', hold=3, wait=40)                  # the lead monster
    for k in range(6):
        adv(p, 40)
        w.snap(f'use_{k}')
        if any(t == w.want('item_use_message', '3')[0] for _b, _a, t in w.shown[n1:]):
            break
    name = bytes(m[SLOT20 + i] for i in range(9))
    want_name = w.want('item_name', '6')[0]
    w.check('the name copied into slot $20 (RunTextHandler) = the edited "FairyDew"',
            name[:len(want_name)] == want_name, name.hex())
    w.check_text('the use line', 'item_use_message', '3', n1)
    for _ in range(8):
        tap(p, 'a', hold=3, wait=30)
    for _ in range(6):
        tap(p, 'b', hold=3, wait=30)
    w.idle()


def s_hall(w):
    print("hall: the SCRIBE GUIDE -> THE SCRIBE'S HALL; the SCRIBE; the QUOTER ($0489)")
    w.start('continue')
    cities = w.rooms['cities_fount']
    w.goto(cities, 0, 3, 5)
    w.face('up')
    r = w.talk([True])
    w.idle()
    w.check("the SCRIBE GUIDE (YES) -> THE SCRIBE'S HALL", w.where()[0] == w.rooms['hall'],
            f"at ${w.where()[0]:02X} ({r})")
    w.save('hall')
    w.goto(w.rooms['hall'], 0, 4, 4)
    w.face('up')
    w.said.clear()
    w.talk()
    w.idle()
    w.check_said("the SCRIBE (the project's own text, bank $60 entry 5)", 'scribe')
    w.goto(w.rooms['hall'], 0, 2, 6)
    w.face('up')
    n0 = len(w.shown)
    w.talk_snaps('quoter', 2)
    w.check_text('the QUOTER (a project script, text id $0489)', 'dialogue', '$0489', n0)


def s_field(w):
    print("field: THE SCRIBE'S FIELD — a wild battle opens with an edited message")
    w.start('hall')
    w.goto(w.rooms['field'], 0, 4, 4)
    m, p = w.m, w.p
    n0 = len(w.shown)
    fought = False
    for i in range(400):
        if m[GAME_MODE] == 2:
            fought = True
            break
        m[0xCA39], m[0xCA3A] = 0, 0                 # the next step battles
        w.step(['left', 'right'][i % 2])
    w.check('a wild battle started', fought)
    edited = (w.want('battle_message', '0')[0], w.want('battle_message', '1')[0])
    for _ in range(150):
        adv(p, 4)
        if any(t in edited for _b, _a, t in w.shown[n0:]):
            adv(p, 60)
            w.snap('battle_open')
            break
    ok0 = any(t in (w.want('battle_message', '0')[0], w.want('battle_message', '1')[0])
              for _b, _a, t in w.shown[n0:])
    banks = [b for b, _a, t in w.shown[n0:]]
    w.check('the battle opened with battle message 0 / 1 = the EDIT (a text bank)',
            ok0 and any(b >= 0x80 for b in banks), ' '.join(f'${b:02X}' for b in banks[:6]))
    w.check('the battle won, the field back', w.battle_won())
    w.idle()
    w.check("back on THE SCRIBE'S FIELD", w.where()[0] == w.rooms['field'],
            f"${w.where()[0]:02X}")


def negative_rom(w):
    b, a = w.sym['TextLevel1Hook']
    rom = bytearray(open(w.rom, 'rb').read())
    o = a
    assert rom[o + 6] == 0xD7, rom[o:o + 8].hex()
    rom[o + 6] = 0x00                                 # rst $10 -> nop: no lookup
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print('NEGATIVE CONTROL: ROM0 TextLevel1Hook without its far call (no edited text found)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = TextWalk(a.build, a.sav, a.keep, a.project)
    man = json.load(open(os.path.join(a.build, 'manifest.json')))
    d = json.load(open(a.project))
    ids = {r['id']: int(r['mapID'], 16) for r in d['custom']['rooms']}
    w.rooms = {'cities_fount': ids['cities_fount'],
               'hall': next(v for k, v in ids.items() if 'scribe' in k and 'hall' in k),
               'field': next(v for k, v in ids.items() if 'scribe' in k and 'field' in k)}
    if a.negative:
        negative_rom(w)
    for step in (s_castle, s_bag, s_hall, s_field):
        try:
            step(w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            w.check(f'{step.__name__} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
