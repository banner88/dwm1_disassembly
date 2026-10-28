#!/usr/bin/env python3
"""walk_hints.py — S158 (ROADMAP E15): THE BREEDING HINTS walked on the user's save (PyBoy).

The demo (examples/s158_hints_demo/build_demo.py) = the user's project + THE STONE GARDEN
(three pillar monuments: LEFT every family + skip owned, MIDDLE the Slime family as a
riddle, RIGHT the Dragon family "both" with an intro; the BREEDER with a MadCat) + THE
GREAT ARCHIVE (eleven bookcases, one per family) + THE RUNE CRYPT (a pillar monument,
served on gate 2's floor 2). The pool: a whitelist of 8 crosses (3 riddles). Every check
reads RAM / SRAM / the ROM (the hint bitsets in SRAM bank 3, wHintCur / the latches, the
inserts $C180-$C1BF, the text the script said, the text engine's bank and pointer while a
riddle prints); screenshots are kept for the eye:

  empty      the Slime bookcase with nothing learned: YES -> "not found any clues";
             NO -> nothing more; the magic "H1" written at the first use
  pick       the LEFT pillar, visit after visit: each visit unlocks one new hint (at once,
             in SRAM), reading it again in the same visit shows the same one, never a cross
             whose child the player has owned (Healer, Dragon in the library), the inserts
             = the cross's names; when none is left: the worn-away words, nothing unlocked
  riddle     the MIDDLE pillar (Slime, riddles): a hint with a riddle prints the riddle
             (the text engine reads bank $79 at HintRiddle_k); one without: the cross
  both       the RIGHT pillar (Dragon, "both"): intro, riddle, the cross
  archive    the Slime bookcase lists exactly the unlocked Slime crosses in the archive
             order, the inserts per entry, "Keep reading?" between, the end words after
             the last; NO stops at once; a family with one entry: entry + end words
  breed      the BREEDER: Healer x MadCat -> a FangSlime egg = hint "Slimex68+0>10":
             UNLOCKED + BRED; the Slime bookcase then shows it with "(bred)"
  persist    a reset WITHOUT saving: the hints learned are still known (written at once)
  newgame    NEW GAME: both bitsets zeroed, the magic "H1" written (bank $73)
  crypt      gate 2's dive, floor 2 = THE RUNE CRYPT: its pillar unlocks a hint; the
             next dive's crypt picks again (a new visit)

  python3 tools/walk_hints.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--only step,step]

--negative: bank $77 StoryCommand's hint kind and bank $16 HintBreed16's far call undone
in the ROM copy (`xor a / ld [$D8E1], a / ret` / nops): no monument unlocks, no archive lists, no breeding marks —
the walk must FAIL. Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, MAP_ID   # noqa: E402
from tools.pyboy_harness import PARTY_LIST, boot, to_bedroom                       # noqa: E402
from tools.walk_regions import (Walk, s_continue, CHOICE, TEXT_PTR, SERVICE_TYPE,    # noqa: E402
                                GAME_STATE_BIT4)

GARDEN, ARCHIVE, CRYPT = 0x77, 0x78, 0x79
CITY = 0x6E
LEFT, MIDDLE, RIGHT = (2, 2), (5, 2), (8, 2)
SHELVES = [(x, 2) for x in range(1, 7)] + [(x, 5) for x in range(2, 7)]   # Slime … Spirit
UNLOCK, BRED, MAGIC = 0xB000, 0xB100, 0xA007
BREEDER = (7, 5)


class HintWalk(Walk):
    def __init__(self, build, sav, keep, project):
        super().__init__(build, sav, keep)
        from editor2.core.project import Project
        from editor2.core import hints as HT
        from editor2.core import textenc as T
        from editor2.core import gamedata as G
        prj = Project(json.load(open(project)), os.path.dirname(os.path.abspath(project)))
        prj.repo_root = REPO
        self.HT, self.T = HT, T
        self.hints, self.count, _h = HT.pool(prj)
        self.by_num = {c['number']: c for c in self.hints}
        self.by_key = {c['key']: c for c in self.hints}
        self.names = G.monster_names(REPO)
        self.cfg = HT.settings(prj.custom)
        self.romb = open(self.rom, 'rb').read()
        self.project = project
        man = json.load(open(os.path.join(build, 'manifest.json')))
        self.text_ids = {v['id'] for v in man['texts'].values()}
        self.peeks = []                       # (text id, inserts, $C824, text ptr) at a render
        self.peek_on = None

    # -- the save's knowledge
    def snap(self, name):
        if not getattr(self, 'no_snaps', False):
            super().snap(name)

    def bits(self, base):
        """The hints set in a bitset — none while bank 3 has no magic "H1" (what is there
        is then not hint data: HintEnsure zeroes it at the first use)."""
        out = set()
        if self.magic() != b'H1':
            return out
        for k in range(self.count):
            if self.p.memory[3, base + (k >> 3)] & (0x80 >> (k & 7)):
                out.add(k)
        return out

    def magic(self):
        return bytes(self.p.memory[3, MAGIC + i] for i in range(2))

    def w16(self, name):
        a = self.sym[name][1]
        return self.m[a] | self.m[a + 1] << 8

    # -- the model's inserts
    def _enc(self, s):
        return bytes(self.T.encode(s)) + b'\xf0'

    def name_of(self, m):
        if m >= 0xF0:
            return self.cfg['family_words'][m - 0xF0]
        return self.names[m]

    def want_inserts(self, k, bred):
        c = self.by_num[k]
        child = self._enc(self.names[c['child']])
        if c['plus']:
            child = child[:-1] + bytes([0x62, 0xA2]) + (
                bytes([c['plus'] // 10, c['plus'] % 10]) if c['plus'] >= 10
                else bytes([c['plus']])) + b'\xf0'
        return (self._enc(self.name_of(c['p1'])), self._enc(self.name_of(c['p2'])), child,
                self._enc(self.cfg['bred_word'] if bred else self.cfg['unbred_word']))

    def inserts(self):
        m = self.m

        def slot(a):
            b = bytearray()
            for i in range(16):
                b.append(m[a + i])
                if m[a + i] == 0xF0:
                    break
            return bytes(b)
        return tuple(slot(a) for a in (0xC180, 0xC190, 0xC1A0, 0xC1B0))

    def riddle_range(self, k):
        if 'HintRiddle_%d' % k not in self.sym:
            return None
        b, a = self.sym['HintRiddle_%d' % k]
        raw = self.cfg['riddles'][self.by_num[k]['key']]
        n = len(self.T.entry_bytes({'boxes': raw, 'speaker': '', 'voice': 'none'}))
        return b, a, a + n

    # -- talking with a look at each text as it prints
    def _text(self, _ctx):
        super()._text(_ctx)
        self.peek_on = (self.said[-1], 0)

    def converse(self, answers=(), maxf=12000, snap=None):
        """Walk.talk with a look at every project text when its first box WAITS (the
        whole box printed): the inserts, the bank the engine reads ($C824), the print
        pointer ($C82D), $D8E1; snap = a name prefix: every waiting box is photographed."""
        m, p = self.m, self.p
        answers = list(answers)
        self.said, self.peeks = [], []
        self.peek_on = None
        m[CHOICE] = 0
        tap(p, 'a', hold=3, wait=6)
        f = calm = 0
        last = [None, 0]
        shots = 0
        while f < maxf:
            adv(p, 2)
            f += 2
            if m[CHOICE] == 1:
                if snap:
                    adv(p, 20)
                    f += 20
                    self.snap(f'{snap}_{shots:02d}')
                    shots += 1
                want = 0 if (answers.pop(0) if answers else False) else 1
                adv(p, 20)
                f += 20
                for _ in range(6):
                    if m[CHOICE] == want:
                        break
                    tap(p, 'up' if want == 0 else 'down', hold=6, wait=12)
                    f += 18
                tap(p, 'a', hold=3, wait=10)
                m[CHOICE] = 0
                continue
            busy = (m[SCRIPT_FLAGS] & 1 or m[TEXTBOX] & 1 or m[0xC96C] or m[0xC905])
            if busy:
                calm = 0
                ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
                if ptr != last[0]:
                    last[0], last[1] = ptr, f
                elif m[TEXTBOX] & 1 and m[SCRIPT_FLAGS] & 1 and f - last[1] >= 12:
                    if self.peek_on is not None:
                        tid, _n = self.peek_on
                        self.peeks.append((tid, self.inserts(), m[0xC824], ptr, m[0xD8E1]))
                        self.peek_on = None
                    if snap:
                        self.snap(f'{snap}_{shots:02d}')
                        shots += 1
                    tap(p, 'a', hold=2, wait=4)
                    f += 6
                    last[1] = f
            else:
                calm += 1
                if calm > 40:
                    return 'idle'
        return 'timeout'

    def read_at(self, mid, cell, answers=(), snap=None):
        """Stand below the object on `cell` of room `mid`, face up, read it."""
        x, y = cell
        self.goto(mid, 0, x, y + 1)
        self.face('up')
        return self.converse(answers, snap=snap)

    def new_visit(self):
        self.goto(CITY, 0, 4, 5)

    def ids(self, role):
        """The text ids a role is said as (the generated entries)."""
        return {t for t in self.text_ids if t.endswith(role)}


def s_empty(w):
    print('empty: the Slime bookcase before anything is learned')
    w.start('continue')
    w.check('the save has no hint knowledge yet (no magic, or no bit set)',
            w.magic() != b'H1' or not w.bits(UNLOCK))
    w.read_at(ARCHIVE, SHELVES[0], [True], snap='empty')
    said = w.said
    w.check('YES -> the archive\'s question, then "not found any clues"',
            len(said) == 2 and said[0].endswith('_ask') and said[1].endswith('_empty'), str(said))
    w.check('the magic "H1" is in SRAM bank 3 now (HintEnsure)', w.magic() == b'H1',
            w.magic().hex())
    w.check('nothing unlocked', not w.bits(UNLOCK))
    w.read_at(ARCHIVE, SHELVES[0], [False])
    w.check('NO -> only the question', [s[-4:] for s in w.said] == ['_ask'], str(w.said))
    w.read_at(ARCHIVE, SHELVES[10], [True])
    w.check('the Spirit bookcase (no hint of that family) -> "not found any clues"',
            len(w.said) == 2 and w.said[1].endswith('_empty'), str(w.said))


def allowed_left(w):
    owned = {s for s in range(240) if w.m[0xCA94 + (s >> 3)] & (0x80 >> (s & 7))}
    return {c['number'] for c in w.hints if c['child'] not in owned}, owned


def s_pick(w):
    print('pick: the LEFT pillar (every family, skip owned), visit after visit')
    w.start('continue')
    allowed, owned = allowed_left(w)
    skipped = {c['number'] for c in w.hints} - allowed
    w.check('the save owns children of some hints (they must be skipped)', bool(skipped),
            f'owned children {sorted(c["child"] for c in w.hints if c["number"] in skipped)}')
    picks = []
    for visit in range(len(allowed) + 1):
        before = w.bits(UNLOCK)
        w.read_at(GARDEN, LEFT, snap='pick_first' if visit == 0 else None)
        after = w.bits(UNLOCK)
        new = after - before
        cur = w.w16('wHintCur')
        if visit < len(allowed):
            w.check(f'visit {visit + 1}: one new hint unlocked at once (SRAM), the one shown',
                    len(new) == 1 and cur in new and w.m[0xD8E1] == 1,
                    f'new {sorted(new)} cur {cur} $D8E1 {w.m[0xD8E1]}')
            picks.append(cur)
            peek = [p for p in w.peeks if p[0].endswith('_text') or p[0] == 'hints_default_monument']
            got = peek[-1][1] if peek else None
            w.check(f'visit {visit + 1}: the words show the cross {w.by_num[cur]["key"]} '
                    '({parent1} {parent2} {child} = the model)',
                    got is not None and got[:3] == w.want_inserts(cur, False)[:3],
                    f'{got} vs {w.want_inserts(cur, False)}')
            w.read_at(GARDEN, LEFT)
            w.check(f'visit {visit + 1}: read again -> the same hint, nothing new',
                    w.w16('wHintCur') == cur and w.bits(UNLOCK) == after,
                    f'cur {w.w16("wHintCur")}')
        else:
            w.check('when none is left: the worn-away words, $D8E1 = 0, nothing unlocked',
                    not new and w.m[0xD8E1] == 0 and any(s.endswith('exhausted') for s in w.said),
                    f'{w.said} new {sorted(new)}')
            w.snap('pick_worn')
        w.new_visit()
    w.check('the picks: every allowed hint once, never a skipped one',
            sorted(picks) == sorted(allowed) and not set(picks) & skipped,
            f'{picks} allowed {sorted(allowed)} skipped {sorted(skipped)}')
    w.check('the picks came in a random order (not the table order)',
            picks != sorted(picks), str(picks))
    w.save('picked')


def s_riddle(w):
    print('riddle: the MIDDLE pillar (Slime, riddles, no skip)')
    w.start('continue')
    seen_r = seen_x = False
    slime = {c['number'] for c in w.hints if c['fam'] == 0}
    got = set()
    for visit in range(len(slime) + 1):
        w.read_at(GARDEN, MIDDLE, snap=f'riddle_{visit}')
        cur = w.w16('wHintCur')
        if visit == len(slime):
            w.check('all Slime hints known -> the worn-away words',
                    w.m[0xD8E1] == 0 and any(s.endswith('exhausted') for s in w.said), str(w.said))
            break
        got.add(cur)
        rr = w.riddle_range(cur)
        pk = [p for p in w.peeks if 'monument' in p[0] or p[0].endswith('_text')]
        if rr:
            b, lo, hi = rr
            ok = any(p[2] == b and lo <= p[3] <= hi for p in pk)
            w.check(f'hint {cur} ({w.by_num[cur]["key"]}) has a riddle: the engine prints it '
                    f'from bank ${b:02X} {lo:04X}-{hi:04X}', ok,
                    str([(p[0], hex(p[2]), hex(p[3])) for p in pk]))
            if ok and not seen_r:
                w.read_at(GARDEN, MIDDLE)
                seen_r = True
        else:
            ok = any(p[2] != 0x79 and p[1][:3] == w.want_inserts(cur, False)[:3] for p in pk)
            w.check(f'hint {cur} ({w.by_num[cur]["key"]}) has no riddle: the cross is shown',
                    ok, str([(p[0], hex(p[2])) for p in pk]))
            seen_x = seen_x or ok
        w.new_visit()
    w.check('the middle pillar picked only Slime hints, each once', got == slime,
            f'{sorted(got)} vs {sorted(slime)}')
    w.check('both kinds seen (a riddle, a plain cross)', seen_r and seen_x)


def s_both(w):
    print('both: the RIGHT pillar (Dragon, intro + riddle + cross)')
    w.start('continue')
    dragon = {c['number'] for c in w.hints if c['fam'] == 1}
    seen = set()
    for visit in range(len(dragon)):
        w.read_at(GARDEN, RIGHT, snap=f'both_{visit}')
        cur = w.w16('wHintCur')
        seen.add(cur)
        said = w.said
        rr = w.riddle_range(cur)
        pk = [p for p in w.peeks if not p[0].endswith('_intro')]
        if rr:
            b, lo, hi = rr
            w.check(f'hint {cur} (a riddle): intro, the riddle (bank ${b:02X}), then the '
                    'cross from the room\'s text', len(said) == 3 and said[0].endswith('_intro')
                    and len(pk) == 2 and pk[0][2] == b and lo <= pk[0][3] <= hi
                    and pk[1][2] != b and pk[1][1][:3] == w.want_inserts(cur, False)[:3],
                    f'{said} {[(p[0], hex(p[2]), hex(p[3])) for p in pk]}')
        else:
            w.check(f'hint {cur} (no riddle): intro, then the cross ONCE (the riddle\'s turn '
                    'skipped)', len(said) == 2 and said[0].endswith('_intro') and len(pk) == 1
                    and pk[0][1][:3] == w.want_inserts(cur, False)[:3], f'{said}')
        w.new_visit()
    w.check('the right pillar picked the Dragon hints', seen == dragon, str(seen))


def s_archive(w):
    print('archive: the Slime / Dragon / Devil bookcases after the LEFT pillar\'s picks')
    w.start('picked')
    known = w.bits(UNLOCK)
    for fam, cell in ((0, SHELVES[0]), (1, SHELVES[1]), (6, SHELVES[6])):
        order = sorted((c for c in w.hints if c['fam'] == fam and c['number'] in known),
                       key=lambda c: (c['child'], c['row']))
        want = [c['number'] for c in order]
        w.read_at(ARCHIVE, cell, [True] * (len(want) + 2), snap=f'archive_{fam}')
        kinds = [s.rsplit('_', 1)[1] for s in w.said]
        expect = ['ask'] + sum((['entry', 'more'] for _ in want), [])[:-1] + ['end'] \
            if want else ['ask', 'empty']
        w.check(f'family {fam}: the texts said = {expect}', kinds == expect, str(kinds))
        ent = [p for p in w.peeks if p[0].endswith('_entry')]
        got = [p[1] for p in ent]
        exp = [w.want_inserts(k, False) for k in want]
        w.check(f'family {fam}: the entries = the unlocked crosses {want} in the archive '
                'order, not bred', got == exp, f'{got} vs {exp}')
        last = [p[4] for p in ent]
        w.check(f'family {fam}: $D8E1 = 1 (more) for every entry but the last (2)',
                last == [1] * (len(want) - 1) + [2] if want else last == [], str(last))
    w.read_at(ARCHIVE, SHELVES[0], [True, False])
    kinds = [s.rsplit('_', 1)[1] for s in w.said]
    w.check('"Keep reading?" NO -> the archive stops', kinds == ['ask', 'entry', 'more'],
            str(kinds))


def s_breed(w):
    print('breed: the BREEDER (MadCat) with the Healer -> FangSlime = a hint, bred')
    w.start('continue')
    m, p = w.m, w.p
    k = w.by_key['Slimex68+0>10']['number']
    w.check('before: the FangSlime cross is neither unlocked nor bred',
            k not in w.bits(UNLOCK) and k not in w.bits(BRED))
    healer = next((i for i, s in enumerate(m[PARTY_LIST + j] for j in range(3))
                   if s != 0xFF and m[0xCAC1 + 149 * s + 9] == 9), None)
    w.check('the party has the Healer', healer is not None)
    if healer is None:
        return
    # the rig: the Healer is level 5 in the user's save and the game breeds only from
    # level 10 ("You can't breed low level monsters!") — its record's level := 10
    hs = m[PARTY_LIST + healer]
    m[0xCAC1 + 149 * hs + 0x4B] = 10
    x, y = BREEDER
    w.goto(GARDEN, 0, x, y + 1)
    w.face('up')
    rows = []
    b, a = w.sym['HintBreed']
    p.hook_register(b, a, lambda _c: rows.append(w.w16('wHintRow')), None)
    m[CHOICE] = 0
    tap(p, 'a', hold=3, wait=6)
    last, still = None, 0
    for _ in range(3000):                             # his words, up to "Why not breed?"
        adv(p, 2)
        if m[CHOICE] == 1:
            break
        ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
        still = still + 2 if ptr == last else 0
        last = ptr
        if still >= 20 and m[TEXTBOX] & 1:
            tap(p, 'a', hold=2, wait=4)
            still = 0
    adv(p, 30)
    tap(p, 'a', hold=3, wait=10)                      # YES
    m[CHOICE] = 0
    adv(p, 120)                                       # the WHO list (the party)
    for _ in range(healer):
        tap(p, 'down', hold=4, wait=30)
    tap(p, 'a', hold=4, wait=60)                      # the Healer -> INFO / OK
    tap(p, 'down', hold=4, wait=30)
    tap(p, 'a', hold=4, wait=60)                      # OK -> "Are you okay with this monster?"
    w.snap('breed_who_healer')
    adv(p, 60)
    tap(p, 'a', hold=4, wait=30)                      # YES
    m[CHOICE] = 0
    went = []

    def back():
        if m[MAP_ID] == 0x08:
            went.append(1)
        return bool(went) and m[MAP_ID] == GARDEN and field_calm(w)
    ok = drive(w, back)
    p.hook_deregister(b, a)
    w.idle()
    w.check('the ceremony ran and the game came back to the garden', ok and bool(went),
            f'map ${m[MAP_ID]:02X}')
    row = w.by_key['Slimex68+0>10']['row']
    w.check(f'HintBreed ran with wHintRow = {row} (the special row Slime x MadCat)',
            rows == [row], str(rows))
    w.check('the FangSlime cross is UNLOCKED and BRED now',
            k in w.bits(UNLOCK) and k in w.bits(BRED), f'{sorted(w.bits(UNLOCK))} / '
            f'{sorted(w.bits(BRED))}')
    w.check('no other hint changed', w.bits(UNLOCK) == {k} and w.bits(BRED) == {k})
    w.check('the library\'s bit of the egg\'s species (FangSlime, 10) is set by the breeding '
            '($CA94: "ever owned", what "skip owned" reads)',
            m[0xCA94 + (10 >> 3)] & (0x80 >> (10 & 7)) != 0)
    w.save('bred')
    w.read_at(ARCHIVE, SHELVES[0], [True, True], snap='archive_bred')
    ent = [p for p in w.peeks if p[0].endswith('_entry')]
    w.check('the Slime bookcase shows it with the bred mark',
            len(ent) == 1 and ent[0][1] == w.want_inserts(k, True), str([e[1] for e in ent]))


def calm_text(w, n=30, maxf=3000):
    m = w.m
    last, same = None, 0
    for _ in range(0, maxf, 2):
        adv(w.p, 2)
        ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
        if ptr == last:
            same += 2
        else:
            same, last = 0, ptr
        if same >= n:
            return True
    return False


def field_calm(w):
    m = w.m
    return (m[GAME_MODE] == 1 and not m[SCRIPT_FLAGS] & 1 and not m[TEXTBOX] & 1
            and not m[GAME_STATE_BIT4] & 0x10 and not m[0xC96C])


def drive(w, until, maxf=60000):
    """A on boxes, YES on questions, START + A on a naming screen, until `until()`."""
    m, p = w.m, w.p
    for f in range(0, maxf, 10):
        adv(p, 10)
        if until():
            return True
        if m[CHOICE] == 1:
            adv(p, 20)
            for _ in range(4):
                if m[CHOICE] == 0:
                    break
                tap(p, 'up', hold=6, wait=12)
            tap(p, 'a', hold=3, wait=10)
            m[CHOICE] = 0
            continue
        if m[SERVICE_TYPE] == 15 and m[GAME_STATE_BIT4] & 0x10:
            tap(p, 'start', hold=3, wait=10)
            tap(p, 'a', hold=3, wait=10)
            continue
        if f % 40 == 0 and (m[TEXTBOX] & 1 or m[SCRIPT_FLAGS] & 1):
            tap(p, 'a', hold=3, wait=2)
    return False


def s_persist(w):
    print('persist: a reset without saving keeps what was learned')
    w.start('picked')
    known = w.bits(UNLOCK)
    w.p.stop(save=True)
    w.p = None
    path = os.path.join(w.keep, 'after_pick.sav')
    shutil.copy(w.rom + '.ram', path)
    sav0 = w.sav
    w.sav = path
    keep = os.path.join(w.keep, 'continue.state')
    shutil.copy(keep, keep + '.bak')                  # s_continue re-saves 'continue'
    s_continue(w)
    shutil.copy(keep + '.bak', keep)
    w.check('after a reset + CONTINUE (no JOURNAL save) the hints are still known',
            w.bits(UNLOCK) == known and known, f'{sorted(w.bits(UNLOCK))} vs {sorted(known)}')
    w.read_at(GARDEN, LEFT)
    w.check('the LEFT pillar has nothing new to teach (all its hints were learned)',
            w.m[0xD8E1] == 0, str(w.said))
    w.sav = sav0
    w.p.stop(save=False)
    w.p = None
    w.persist_sav = path


def s_newgame(w):
    print('newgame: NEW GAME forgets every hint')
    path = getattr(w, 'persist_sav', None) or os.path.join(w.keep, 'after_pick.sav')
    if not os.path.exists(path):
        w.check('a save with hints known (run persist first)', False)
        return
    shutil.copy(path, w.rom + '.ram')
    from tools.pyboy_harness import boot as _boot
    p = _boot(w.rom)
    w.p, w.m = p, p.memory
    had = bytes(p.memory[3, UNLOCK + i] for i in range(4))
    # boot reads the .ram: bank 3 holds the learned bits until NEW GAME
    # the title with a save: CONTINUE first — DOWN to NEW GAME (to_bedroom's A only
    # would continue), then A through the opening until the intro bedroom ($2F)
    adv(p, 400)
    tap(p, 'start')
    adv(p, 120)
    tap(p, 'a')                                       # the logo -> the title
    adv(p, 120)
    tap(p, 'a')                                       # the title -> the menu
    adv(p, 200)
    tap(p, 'down', hold=4, wait=30)                   # CONTINUE -> NEW GAME
    w.snap('newgame_menu')
    ok = False
    for _ in range(120):
        tap(p, 'a', wait=8)
        if p.memory[MAP_ID] == 0x2F:
            adv(p, 120)
            ok = True
            break
    w.snap('newgame')
    w.check('NEW GAME reached the bedroom', ok, f'map ${p.memory[MAP_ID]:02X}')
    w.check('both bitsets are zero after NEW GAME (bank $73 HintNewGameClear), magic "H1"',
            not w.bits(UNLOCK) and not w.bits(BRED) and w.magic() == b'H1',
            f'before {had.hex()} after {bytes(p.memory[3, UNLOCK + i] for i in range(4)).hex()}')
    p.stop(save=False)
    w.p = None


def s_crypt(w):
    print('crypt: gate 2 floor 2 serves THE RUNE CRYPT; its pillar picks per dive')
    w.start('continue')
    m = w.m
    got = []
    for dive in range(2):
        m[SCRIPT_FLAGS] = 0
        m[0xC96D], m[0xC96E] = 2, 1
        m[0xC96C] = 1
        m[0xC88F] = (m[0xC88F] + 1) & 0xFF
        for _ in range(120):
            w.keep_enc()
            adv(w.p, 10)
        w.idle()
        w.kick(2)
        for _ in range(30):
            w.keep_enc()
            adv(w.p, 10)
        w.check(f'dive {dive + 1}: floor 2 is THE RUNE CRYPT', m[MAP_ID] == CRYPT,
                f'map ${m[MAP_ID]:02X}')
        if m[MAP_ID] != CRYPT:
            return
        before = w.bits(UNLOCK)
        w.goto(CRYPT, 0, 5, 4)
        w.face('up')
        w.converse(snap=f'crypt_read_{dive}')
        cur = w.w16('wHintCur')
        new = w.bits(UNLOCK) - before
        w.check(f'dive {dive + 1}: the crypt pillar unlocked a hint (shown)',
                len(new) == 1 and cur in new, f'new {sorted(new)} cur {cur}')
        if dive == 0:
            w.snap('crypt')
            w.face('up')
            w.converse()
            w.check('read again in the same dive: the same hint', w.w16('wHintCur') == cur
                    and w.bits(UNLOCK) - before == new)
        got.append(cur)
        w.goto(CITY, 0, 4, 5)
    w.check('the second dive taught another hint', len(set(got)) == 2, str(got))


STUB = 0xDD40          # battle WRAM, unused in the field (tools/census_breeding.py)


def stub(w, hl):
    """di / ld hl, <entry> / rst $10 / jr $ — run one far call, back at the park."""
    m, p = w.m, w.p
    code = [0xF3, 0x21, hl & 0xFF, hl >> 8, 0xD7, 0x18, 0xFE]
    for i, b in enumerate(code):
        m[STUB + i] = b
    pc = p.register_file.PC
    p.register_file.PC = STUB
    for _ in range(60):
        p.tick(1, False)
        if p.register_file.PC == STUB + 5:
            break
    else:
        raise SystemExit(f'stub ${hl:04X} did not return')
    p.register_file.PC = pc


def s_census(w):
    print('census: the scanner\'s row number and HintBreed, stub-called over the special table')
    w.start('continue')
    m = w.m
    from editor2.core.project import Project
    from editor2.core import breeding as B
    prj = Project(json.load(open(w.project)), os.path.dirname(os.path.abspath(w.project)))
    br = B.Breeding(prj.gamedata())
    fast = B.FastResolver(br)
    hr = w.sym['wHintRow'][1]
    species = list(range(215))
    bad, n = [], 0
    for p1 in species[::3]:
        for p2 in species[::2]:
            res, how, idx = fast.resolve(p1, p2, 1)
            m[0xDA6F], m[0xDA70] = p1, p2
            m[0xDA75], m[0xDA76] = 0x28, 0x29
            m[0xD665 + 0x62] = m[0xD6FA + 0x62] = 0          # plus 0 -> 1
            m[0xD665 + 0x4B] = m[0xD6FA + 0x4B] = 1
            stub(w, 0x1602)
            got = m[hr] | m[hr + 1] << 8
            want = idx if how == 'special' else 0xFFFF
            n += 1
            if got != want or m[0xDA71] != res:
                bad.append((p1, p2, got, want))
    w.check(f'bank $69 wHintRow == the model\'s special row (or $FFFF) for {n} crosses',
            not bad, str(bad[:5]))
    # HintBreed: a row in the pool marks its hint, a row outside marks nothing
    in_pool = {c['row']: c['number'] for c in w.hints}
    out_row = next(i for i in range(len(br.special)) if i not in in_pool)
    m[hr], m[hr + 1] = out_row & 0xFF, out_row >> 8
    before_u, before_b = w.bits(UNLOCK), w.bits(BRED)
    stub(w, 0x790B)
    w.check(f'HintBreed with row {out_row} (not in the pool): nothing marked',
            w.bits(UNLOCK) == before_u and w.bits(BRED) == before_b)
    m[hr], m[hr + 1] = 0xFF, 0xFF
    stub(w, 0x790B)
    w.check('HintBreed with $FFFF (no special row made the egg): nothing marked',
            w.bits(UNLOCK) == before_u and w.bits(BRED) == before_b)
    marks = []
    for row, k in sorted(in_pool.items()):
        m[hr], m[hr + 1] = row & 0xFF, row >> 8
        stub(w, 0x790B)
        marks.append(k in w.bits(UNLOCK) and k in w.bits(BRED))
    w.check(f'HintBreed with each of the {len(in_pool)} pool rows marks exactly its hint',
            all(marks) and w.bits(UNLOCK) == set(in_pool.values()), str(marks))


def negative(w):
    """bank $77 StoryCommand.hint -> `xor a / ld [$D8E1], a / ret` (the command does
    nothing and reports "none": a bare `ret` leaves $D8E1 stale, the archive's loop then
    runs on with no command and the game hangs — S158), bank $16 HintBreed16's rst $10
    -> nops."""
    rom = bytearray(open(w.rom, 'rb').read())
    b, a = w.sym['StoryCommand.hint']
    o = b * 0x4000 + a - 0x4000
    assert rom[o:o + 2] == b'\x3d\xc0', rom[o:o + 5].hex()   # dec a / ret nz
    rom[o:o + 5] = b'\xaf\xea\xe1\xd8\xc9'
    b, a = w.sym['HintBreed16']
    o = b * 0x4000 + a - 0x4000 + 3                    # after `call BreedResolveOffspring`
    assert rom[o] == 0x21 and rom[o + 3] == 0xD7, rom[o:o + 4].hex()
    rom[o:o + 4] = b'\x00\x00\x00\x00'
    open(w.rom, 'wb').write(rom)
    w.romb = bytes(rom)
    w.no_snaps = True
    print('NEGATIVE CONTROL: StoryCommand kind 8 does nothing ($D8E1 := 0); HintBreed16 calls no HintBreed')


STEPS = {'empty': s_empty, 'pick': s_pick, 'riddle': s_riddle, 'both': s_both,
         'archive': s_archive, 'breed': s_breed, 'persist': s_persist,
         'newgame': s_newgame, 'crypt': s_crypt, 'census': s_census}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--only', default='')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = HintWalk(a.build, a.sav, a.keep, a.project)
    if a.negative:
        negative(w)
    if not os.path.exists(os.path.join(a.keep, 'continue.state')) or not a.only:
        s_continue(w)
    only = [s for s in a.only.split(',') if s] or (
        ['empty', 'pick', 'breed', 'census'] if a.negative else list(STEPS))
    for name in only:
        if name == 'archive' and not os.path.exists(os.path.join(a.keep, 'picked.state')):
            s_pick(w)
        STEPS[name](w)
    print(f'WALK: {"PASS" if not w.fails else "FAIL %d" % w.fails}  ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
