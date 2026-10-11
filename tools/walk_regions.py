#!/usr/bin/env python3
"""walk_regions.py — S141 (ROADMAP ARC CAP3b): the in-game acceptance of REGIONS for the
moments where the GAME moves the player by itself (no door, no NPC warp).

S140 walked doors, stairs and script warps between regions. A place is (region, map id)
(ARCHITECTURE "Regions (S140)"); the engine also moves the player on its own — home after a
lost battle or a WarpWing (bank $71 HubWarp: the hub row's region), back from the breeding
ceremony (op $4E's return point holds a bare map id; the ceremony room $08 is vanilla, so the
region must survive it), into a room a gate serves on a floor (bank $71 entry 4 -> bank $73
entry 22 RegionEnterE) and onto a gate's boss floor (bank $16 -> bank $71 entry 11
BossRegionEnter; GateBossWin compares the region, entry 12). This driver plays each of them
on a build of the S141 demo (`examples/s141_dial_demo/`: the DIAL HALLS — region-2 rooms
MOONDIAL HALL / MOON HEARTH / MOON CELLAR / MOON DAIS at map ids $76-$79, and region-0 DECOYS
with the same map ids: SUNDIAL HALL / SUN HEARTH / SUN CELLAR / SUN DAIS; a move that lost the
region lands in a decoy) on a real save, and checks where the player lands — map id AND
region — plus what the game says there (the hub's arrival scene by reason) and what it
changed (gold halved, the egg, the cleared flag, the portal's swirl). Last, Play here (the
editor's own playback engine, `editor2/core/playback.py` + `play_setup.resolve`) into
region-2 and region-0 places from a new game, the save and a story point.

  python3 tools/walk_regions.py --build DEMO/build/build --sav USER.sav [--steps a,b,…]
          [--keep DIR]  (savestates + pictures)

Steps: continue, enter, lose2, lose0, breed, wing, gate, warpwing0, boss, castle, playhere.
Prints one line per check and `WALK: PASS` / `WALK: FAIL n`. `--negative` removes bank $71
HubWarp's region store in the ROM copy: the moves home that cross regions must then FAIL.
`--negative-sheets` undoes the S141 r3 NPC-sheet fix in the ROM copy (a custom room's sheets
3-5 back in VRAM bank 0): the breed step's NPC picture checks (menu open, after) must then
FAIL (the user's report: after breeding, and while the menu is open, an NPC vanished and
another turned into letters). Needs PyBoy
(PYBOY_DEBUGGING.md; S141 techniques).
"""
import argparse
import copy
import json
import os
import shutil
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import (boot, boot_with_sav, adv, tap, snap, MAP_ID, MAP_REGION,  # noqa: E402
                                 W_REGION, W_CHANGING, W_DEST, W_FLAG, W_KICK, W_XLO, W_XHI,
                                 W_YLO, W_YHI, GAME_MODE, TEXTBOX, SCRIPT_FLAGS, C905_STATE,
                                 IN_GATEWORLD, PLAYER_TX, PLAYER_TY, PARTY_LIST)

CHOICE = 0xC83C              # the YES / NO answer byte: 1 when the box opens (NO), follows the cursor
TEXT_PTR = 0xC82D            # the print pointer: stands still while a box waits for A
GATE_ID, CUR_FLOOR, LAST_FLOOR, BOSS_MAP = 0xC935, 0xC939, 0xC93A, 0xC93B
HUB_REASON = 0xD2EF          # wHubReason
BREED_STAGE = 0xD951
CASTLE_EVENT = 0xD92B
GOLD = 0xCA4B                # 24-bit
BAG = 0xCA51                 # wInventory, 20 slots, $FF = empty
SERVICE_TYPE = 0xC8EF        # op $04's screen type (6 = Grandpa's BREED / HATCH / EXIT)
GAME_STATE_BIT4 = 0xC8EB     # wGameState: bit 4 = an op $04 screen effect / the shop is open
WARPWING = 29
DIAL_GATE = 33
CLEARED = 0x17A0 + DIAL_GATE  # the gate's own cleared flag (GATE_GENERATION §7.9)
HALL, HEARTH, CELLAR, DAIS = 0x76, 0x77, 0x78, 0x79      # map ids; test region 2, decoys 0
TEST_REGION = 2


# ------------------------------------------------------------------ helpers
def read_sym(path):
    out = {}
    for ln in open(path):
        ln = ln.split(';')[0].strip()
        if ln:
            a, name = ln.split()
            b, ad = a.split(':')
            out[name] = (int(b, 16), int(ad, 16))
    return out


class Walk:
    def __init__(self, build, sav, keep):
        self.build = build
        self.sav = sav
        self.keep = keep
        self.rom = os.path.join(keep, 'walk.gbc')
        shutil.copy(os.path.join(build, 'rom.gbc'), self.rom)
        self.sym = read_sym(os.path.join(build, 'game.sym'))
        self.negative = False
        man = json.load(open(os.path.join(build, 'manifest.json')))
        self.texts = {int(k[1:], 16): v['id'] for k, v in man['texts'].items()}
        self.p = None
        self.said = []
        self.fails = 0
        self.checks = 0

    # -- emulator
    def break_hub_region(self):
        """The negative control: bank $71 HubWarp forgets the hub row's region (its
        `ld [wWarpRegion], a` -> nops) in the ROM copy. The walk must then FAIL every
        move home that crosses regions (lose0, warpwing0) — so it can see a lost region."""
        b, a = self.sym['HubWarp']
        rom = bytearray(open(self.rom, 'rb').read())
        base = b * 0x4000 + a - 0x4000
        k = rom.find(bytes([0xEA, 0x37, 0xD5]), base, base + 0x60)    # ld [$D537], a
        if k < 0:
            raise SystemExit('HubWarp: no `ld [wWarpRegion], a` found')
        rom[k:k + 3] = b'\x00\x00\x00'
        open(self.rom, 'wb').write(rom)
        self.negative = True
        print(f'NEGATIVE CONTROL: HubWarp\'s wWarpRegion store at ${b:02X}:{0x4000 + k % 0x4000:04X} '
              'removed')

    def old_npc_banks(self):
        """The negative control of the S141 r3 fix: in the ROM copy bank $77 NpcSheetLoad0B
        and NpcDrawBank treat every room as vanilla (their `cp CUSTOM_ROOM_START` branch made
        unconditional) — a custom room's NPC sheets 3-5 back in VRAM bank 0 under the menus'
        tiles: the breed step's sheet checks must then FAIL."""
        rom = bytearray(open(self.rom, 'rb').read())
        for lab, pat, new in (('NpcSheetLoad0B.five', bytes([0xFE, 0x6B, 0xDA]), 0xC3),
                              ('NpcDrawBank', bytes([0xFE, 0x6B, 0xD8]), 0xC9)):
            b, a = self.sym[lab]
            o = b * 0x4000 + a - 0x4000
            k = rom.find(pat, o, o + 0x40)
            if k < 0:
                raise SystemExit(f'{lab}: no `cp CUSTOM_ROOM_START` branch found')
            rom[k + 2] = new                      # jp c -> jp / ret c -> ret
        open(self.rom, 'wb').write(rom)
        print('NEGATIVE CONTROL: bank $77 NpcSheetLoad0B / NpcDrawBank as in a vanilla room '
              '(sheets 3-5 in VRAM bank 0, no bank bit)')

    def shown_npc_tiles(self):
        """{(tile, VRAM bank): 16 bytes} of every NPC-sheet piece the LCD shows now (real
        OAM, tile >= $50: the room's NPC sheets; attr bit 3 = the bank)."""
        m = self.m
        out = {}
        for i in range(40):
            y, x, t, a = (m[0xFE00 + 4 * i + k] for k in range(4))
            if 0 < y < 160 and 0 < x < 168 and t >= 0x50:
                bank = (a >> 3) & 1
                out[(t, bank)] = bytes(self.p.memory[bank, 0x8000 + 16 * t:0x8000 + 16 * t + 16])
        return out

    def npc_sheets(self):
        """{(tile, VRAM bank): 16 bytes} for tiles $50-$AF in both VRAM banks (the room's
        NPC sheets as loaded — taken before a talk)."""
        return {(t, b): bytes(self.p.memory[b, 0x8000 + 16 * t:0x8000 + 16 * t + 16])
                for t in range(0x50, 0xB0) for b in (0, 1)}

    def check_npc_tiles(self, what, sheets):
        """Every NPC piece the LCD shows now reads the same bytes its (tile, bank) held when
        the room was loaded (`sheets` = npc_sheets() before the talk)."""
        now = self.shown_npc_tiles()
        bad = sorted(k for k, v in now.items() if sheets.get(k) != v)
        self.check(f'{what}: every NPC piece on screen shows its own picture', not bad,
                   f"{len(now)} shown; wrong: {' '.join(f'${t:02X}/b{b}' for t, b in bad[:6])}")

    def start(self, state=None):
        if self.p is not None:
            self.p.stop(save=False)
        if state is None:
            self.p = boot_with_sav(self.rom, self.sav)
        else:
            self.p = boot(self.rom)
            with open(os.path.join(self.keep, state + '.state'), 'rb') as f:
                self.p.load_state(f)
        self.m = self.p.memory
        b, a = self.sym['PlaceFwdText']               # every project text (bank $60 entry 5)
        self.p.hook_register(b, a, self._text, None)
        self.said = []

    def _text(self, _ctx):
        m = self.m
        i = 0x0A00 + m[0xC822] * 256 + m[0xC823]
        self.said.append(self.texts.get(i, hex(i)))

    def save(self, name):
        with open(os.path.join(self.keep, name + '.state'), 'wb') as f:
            self.p.save_state(f)

    def snap(self, name):
        snap(self.p, os.path.join(self.keep, name + '.png'))

    def where(self):
        return self.m[MAP_ID], self.m[MAP_REGION]

    # -- checks
    def check(self, what, ok, detail=''):
        self.checks += 1
        if not ok:
            self.fails += 1
        print(f"  {'ok  ' if ok else 'FAIL'} {what}" + (f'  [{detail}]' if detail else ''))

    def check_at(self, what, mid, region):
        got = self.where()
        self.check(f'{what}: map ${mid:02X} region {region}', got == (mid, region),
                   f'at ${got[0]:02X} region {got[1]}')

    def check_said(self, what, prefix):
        hit = [t for t in self.said if str(t).startswith(prefix)]
        self.check(f'{what}: the game said {prefix}…', bool(hit), ', '.join(map(str, self.said[-6:])))

    # -- the field
    def idle(self, maxf=3000, calm_n=6):
        """A calm field (PYBOY_DEBUGGING S140): mode 1, no script, no box, no transition,
        calm_n checks 10 frames apart; A while a box waits."""
        m = self.m
        calm = f = 0
        while f < maxf:
            adv(self.p, 10)
            f += 10
            busy = (m[GAME_MODE] != 1 or m[SCRIPT_FLAGS] & 1 or m[TEXTBOX] & 1
                    or m[W_CHANGING] or m[C905_STATE])
            if not busy:
                calm += 1
                if calm >= calm_n:
                    return True
                continue
            calm = 0
            if m[TEXTBOX] & 1 and f % 30 == 0:
                tap(self.p, 'a', hold=2, wait=2)
        return False

    def keep_enc(self):
        self.m[0xCA39] = 0xFF
        self.m[0xCA3A] = 0x7F

    def goto(self, mid, region, x, y):
        """The warp mailbox (pyboy_harness.warp) with the region NAMED (KEYS_LESSONS S140:
        a plain id keeps the current region)."""
        m = self.m
        for _ in range(3):
            m[SCRIPT_FLAGS] = 0
            m[W_REGION] = region + 1
            m[W_DEST] = mid
            m[W_FLAG] = 0
            px, py = x * 16 + 8, y * 16 + 8
            m[W_XLO], m[W_XHI], m[W_YLO], m[W_YHI] = px & 0xFF, px >> 8, py & 0xFF, py >> 8
            m[W_CHANGING] = 1
            m[W_KICK] = 1
            adv(self.p, 200)
            self.idle()
            for _ in range(3):
                tap(self.p, 'b', wait=20)            # the post-warp status bar
            if self.where() == (mid, region):
                return True
        return False

    def face(self, d):
        tap(self.p, d, hold=6, wait=20)

    def step(self, d):
        m = self.m
        x0, y0 = m[PLAYER_TX], m[PLAYER_TY]
        self.p.button_press(d)
        adv(self.p, 8)
        self.p.button_release(d)
        for _ in range(40):
            adv(self.p, 1)
            if (m[PLAYER_TX], m[PLAYER_TY]) != (x0, y0) or m[W_CHANGING]:
                break
        adv(self.p, 10)

    def talk(self, answers=(), maxf=8000):
        """A on the NPC faced; every box advanced when it WAITS (the print pointer still
        12 frames — a question's YES / NO opens by itself when its text ends, and an A
        held then answers NO: S141); answers[i] for the i-th YES / NO (the cursor is
        moved until $C83C shows it). -> 'idle' | 'battle' | 'map' | 'timeout'."""
        m, p = self.m, self.p
        answers = list(answers)
        here = self.where()
        m[CHOICE] = 0
        tap(p, 'a', hold=3, wait=6)
        f = calm = 0
        last = [None, 0]
        while f < maxf:
            adv(p, 2)
            f += 2
            if m[GAME_MODE] == 2:
                return 'battle'
            if m[CHOICE] == 1:
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
            busy = (m[SCRIPT_FLAGS] & 1 or m[TEXTBOX] & 1 or m[W_CHANGING] or m[C905_STATE])
            if self.where() != here and not busy and m[GAME_MODE] == 1:
                return 'map'
            if busy:
                calm = 0
                ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
                if ptr != last[0]:
                    last[0], last[1] = ptr, f
                elif m[TEXTBOX] & 1 and m[SCRIPT_FLAGS] & 1 and f - last[1] >= 12:
                    tap(p, 'a', hold=2, wait=4)
                    f += 6
                    last[1] = f
            else:
                calm += 1
                if calm > 40:
                    return 'idle'
        return 'timeout'

    def battle_lost(self, maxf=20000):
        """A every 20 frames until the field is back (the party's HP was poked to 1)."""
        m = self.m
        f = 0
        while f < maxf:
            adv(self.p, 20)
            f += 20
            if m[GAME_MODE] == 1 and not m[TEXTBOX] & 1 and not m[SCRIPT_FLAGS] & 1 \
                    and m[W_CHANGING] == 0 and m[C905_STATE] == 0:
                return True
            tap(self.p, 'a', hold=3, wait=2)
        return False

    def battle_won(self, maxf=20000):
        """The enemy's HP poked to 1, no join prompt ($DB85 = 7), A every 50 frames."""
        m = self.m
        f = 0
        fought = False
        while f < maxf:
            adv(self.p, 10)
            f += 10
            if m[GAME_MODE] == 2:
                fought = True
                m[0xDB85] = 7
                for a in (0xDBAB, 0xDBAD, 0xDBAF):
                    if m[a] | m[a + 1] << 8:
                        m[a], m[a + 1] = 1, 0
                if f % 50 == 0:
                    tap(self.p, 'a', hold=3, wait=2)
            elif fought and m[GAME_MODE] == 1:
                return True
        return False

    def party_hp_1(self):
        m = self.m
        for k in range(3):
            s = m[PARTY_LIST + k]
            if s != 0xFF:
                b = 0xCAC1 + 149 * s
                m[b + 0x50], m[b + 0x51] = 1, 0           # current HP (+$50)

    def gold(self):
        m = self.m
        return m[GOLD] | m[GOLD + 1] << 8 | m[GOLD + 2] << 16

    def ext_flag(self, idx):
        o = idx - 0x1000
        return (self.m[0xD140 + (o >> 3)] >> (7 - (o & 7))) & 1

    def follow(self, frames=2400, until=None):
        """Let the game run (A on boxes) until `until()` or the time is up."""
        m = self.m
        for i in range(frames // 10):
            self.keep_enc()
            adv(self.p, 10)
            if m[TEXTBOX] & 1 and i % 4 == 0:
                tap(self.p, 'a', hold=2, wait=2)
            if until is not None and until():
                return True
        return until is None

    def use_warpwing(self):
        """The field menu: ITEM, the WarpWing's page, USE (PYBOY_DEBUGGING S125)."""
        m, p = self.m, self.p
        slot = next((i for i in range(20) if m[BAG + i] == WARPWING), None)
        if slot is None:
            return False
        tap(p, 'a', hold=3, wait=90)
        tap(p, 'right', hold=8, wait=40)
        tap(p, 'a', hold=3, wait=60)
        for _ in range(slot // 5):
            tap(p, 'right', hold=8, wait=30)
        for _ in range(slot % 5):
            tap(p, 'down', hold=8, wait=20)
        tap(p, 'a', hold=3, wait=60)                  # USE / DEL
        tap(p, 'a', hold=3, wait=60)                  # USE: "… throws a WarpWing!"
        here = self.where()
        for _ in range(20):                           # that menu box is no field text box
            if m[W_CHANGING] or self.where() != here:     # ($C8EB bit 0 stays clear): A
                break
            tap(p, 'a', hold=3, wait=30)
        return True

    def kick(self, floor):
        """The staircase kick to the game's floor `floor` (PYBOY_DEBUGGING S115: poke
        floor − 2)."""
        m = self.m
        m[CUR_FLOOR] = floor - 2
        m[W_DEST], m[W_FLAG] = 0, 0x80
        m[W_CHANGING] = 1
        m[W_KICK] = (m[W_KICK] + 1) & 0xFF
        for _ in range(90):
            self.keep_enc()
            adv(self.p, 10)
        self.idle()


# ------------------------------------------------------------------ the walk
def s_continue(w):
    print('continue: the save (a place this build lacks goes home, S138)')
    w.start()
    m = w.m
    adv(w.p, 400)                                     # the S100 recipe: title, CONTINUE
    tap(w.p, 'start')
    adv(w.p, 120)
    tap(w.p, 'a')
    adv(w.p, 120)
    tap(w.p, 'a')
    adv(w.p, 200)
    tap(w.p, 'a')
    for i in range(400):
        adv(w.p, 10)
        if m[GAME_MODE] == 1 and not m[TEXTBOX] & 1 and m[W_CHANGING] == 0:
            break
        if i % 3 == 0:
            tap(w.p, 'a')
    for _ in range(4):
        tap(w.p, 'b', wait=20)
    w.idle()
    w.check('CONTINUE reached the field', w.m[GAME_MODE] == 1, f'at ${w.where()[0]:02X}')
    w.save('continue')


def s_enter(w):
    print('enter: the S141 DEMO NPC in Cities_FOUNT (3, 4) -> MOONDIAL HALL (region 2)')
    w.start('continue')
    w.goto(0x6E, 0, 3, 5)
    w.face('up')
    w.talk([True])
    w.idle()
    w.check_at('the demo NPC sent us to MOONDIAL HALL', HALL, TEST_REGION)
    w.snap('enter')
    w.save('hall')


def lose_to_bruiser(w, what):
    g0 = w.gold()
    w.party_hp_1()
    r = w.talk([True])
    w.check(f'{what}: the BRUISER fight started', r == 'battle', r)
    w.battle_lost()
    w.follow(1200, until=lambda: w.m[HUB_REASON] == 0 and w.idle(600))
    w.check_at(f'{what}: lost -> home = MOON HEARTH', HEARTH, TEST_REGION)
    w.check_said(f'{what}: the hub greeted the loss', 'cs_arrival_lost')
    w.check(f'{what}: gold halved', w.gold() == g0 // 2, f'{g0} -> {w.gold()}')


def s_lose2(w):
    print('lose2: a lost battle in MOONDIAL HALL (region 2) -> the hub MOON HEARTH (region 2)')
    w.start('hall')
    w.goto(HALL, TEST_REGION, 8, 4)
    w.face('up')
    lose_to_bruiser(w, 'region 2')
    w.save('hearth')


def s_lose0(w):
    print('lose0: a lost battle in SUNDIAL HALL (region 0) -> MOON HEARTH (region 2)')
    w.start('hall')
    w.goto(HALL, TEST_REGION, 7, 6)
    w.face('right')
    w.talk([True])
    w.idle()
    w.check_at('the guide (a script warp) -> SUNDIAL HALL', HALL, 0)
    w.save('sun')
    w.goto(HALL, 0, 3, 4)
    w.face('left')
    lose_to_bruiser(w, 'region 0')


def s_breed(w):
    print('breed: Grandpa in MOONDIAL HALL (region 2) -> the ceremony ($08) -> back')
    w.start('hall')
    m, p = w.m, w.p
    w.goto(HALL, TEST_REGION, 5, 3)
    w.face('up')
    adv(p, 30)
    shown0 = w.shown_npc_tiles()                      # the NPCs as drawn before the talk
    sheets0 = w.npc_sheets()                          # their sheets as the room load left them
    w.check('before the talk: the room\'s 5 NPCs drawn (pieces of 4+ sheets shown)',
            len({t & 0xF0 for t, _b in shown0}) >= 4, f'{len(shown0)} pieces')
    m[CHOICE] = 0
    tap(p, 'a', hold=3, wait=6)
    # the first-visit words, then the BREED / HATCH / EXIT menu: op $04 type 6 in
    # $C8EF (the menu keeps $C8EB bit 0 set) — no A once it opens
    for i in range(300):
        adv(p, 10)
        if m[SERVICE_TYPE] == 6:
            break
        if m[TEXTBOX] & 1 and i % 4 == 3:
            tap(p, 'a', hold=2, wait=2)
    adv(p, 150)
    w.check_npc_tiles('Grandpa\'s BREED / HATCH / EXIT menu OPEN', sheets0)
    w.snap('breed_menu_open')
    tap(p, 'a', hold=3, wait=200)                     # BREED -> "Which monster for the pedigree?"
    tap(p, 'a', hold=3, wait=200)                     # the first monster -> "That one? Are you sure?"
    tap(p, 'down', hold=3, wait=20)
    tap(p, 'a', hold=3, wait=250)                     # OK -> "Which monster to breed with?"
    tap(p, 'a', hold=3, wait=200)                     # the first mate
    tap(p, 'down', hold=3, wait=20)
    tap(p, 'a', hold=3, wait=150)                     # OK -> "I bet … will be born!"
    trail = []

    def seen():
        s = (m[MAP_ID], m[MAP_REGION], m[BREED_STAGE])
        if not trail or trail[-1] != s:
            trail.append(s)
        return False

    for stage in (0xF0, 0xF1):
        for _ in range(1200):
            for _ in range(20):
                adv(p, 1)
                seen()
            if m[CHOICE] == 1:                        # "Can I record this joyful event?" /
                adv(p, 20)                            # the HATCH offer: YES
                for _ in range(4):
                    if m[CHOICE] == 0:
                        break
                    tap(p, 'up', hold=6, wait=12)
                tap(p, 'a', hold=3, wait=10)
                m[CHOICE] = 0
                continue
            if m[BREED_STAGE] == stage and (m[MAP_ID], m[MAP_REGION]) == (HALL, TEST_REGION) \
                    and m[GAME_MODE] == 1:
                break
            if not m[SCRIPT_FLAGS] & 1 or m[TEXTBOX] & 1:
                tap(p, 'a', hold=2, wait=2)
        went = any(t[0] == 0x08 for t in trail)
        w.check(f'stage ${stage:02X}: the ceremony room $08 was entered', went,
                ' '.join(f'${a:02X}/{b}/${c:02X}' for a, b, c in trail[-6:]))
        w.check_at(f'stage ${stage:02X}: back from the ceremony in MOONDIAL HALL', HALL, TEST_REGION)
        trail.clear()
    # the rest of the follow-up: the naming screen (15: START, A), "Take … with you
    # now?" (11: A = YES), "Anything else?" (6: EXIT = down, down, A)
    seen11 = False
    last = [None, 0]
    for f in range(0, 9000, 2):
        adv(p, 2)
        t = m[SERVICE_TYPE]
        seen11 = seen11 or t == 11
        ptr = m[TEXT_PTR] | m[TEXT_PTR + 1] << 8
        if ptr != last[0]:
            last[0], last[1] = ptr, f
        if f - last[1] < 40:
            continue
        last[1] = f
        if t == 15 and m[GAME_STATE_BIT4] & 0x10:
            tap(p, 'start', hold=3, wait=10)
            tap(p, 'a', hold=3, wait=10)
        elif t == 6 and seen11 and m[GAME_STATE_BIT4] & 0x10:
            w.check_npc_tiles('"Anything else?" menu OPEN (after the ceremonies)', sheets0)
            tap(p, 'down', hold=4, wait=20)
            tap(p, 'down', hold=4, wait=20)
            tap(p, 'a', hold=3, wait=20)
            break
        elif m[TEXTBOX] & 1 or m[GAME_STATE_BIT4] & 0x10:
            tap(p, 'a', hold=2, wait=4)
    w.idle()
    adv(p, 60)
    w.check_npc_tiles('after BREED, HATCH, naming, "Anything else?" -> EXIT', sheets0)
    w.snap('breed')


def s_wing(w):
    print('wing: the WING KEEPER gives a WarpWing')
    w.start('sun')
    w.goto(HALL, TEST_REGION, 1, 5)
    w.face('up')
    n0 = sum(1 for i in range(20) if w.m[BAG + i] == WARPWING)
    if all(w.m[BAG + i] != 0xFF for i in range(20)):
        w.m[BAG + 19] = 0xFF                          # room in the bag
    w.talk()
    w.idle()
    n1 = sum(1 for i in range(20) if w.m[BAG + i] == WARPWING)
    w.check('a WarpWing more in the bag', n1 == n0 + 1, f'{n0} -> {n1}')
    w.save('wing')


def into_gate(w):
    """From SUNDIAL HALL's arrival cell walk down onto the portal (5, 5)."""
    w.goto(HALL, 0, 5, 3)
    w.keep_enc()
    w.step('down')
    w.step('down')
    w.follow(1500)
    w.idle()
    m = w.m
    w.check('the portal -> the DIAL GATE floor 1',
            (m[GATE_ID], m[CUR_FLOOR] + 1, m[IN_GATEWORLD]) == (DIAL_GATE, 1, 1),
            f'gate {m[GATE_ID]} floor {m[CUR_FLOOR] + 1} map ${m[MAP_ID]:02X} region {m[MAP_REGION]}')


def s_gate(w):
    print('gate: a region-2 room served on floor 2 of a gate entered from region 0; '
          'the WarpWing on floor 3')
    w.start('wing')
    into_gate(w)
    w.save('gate1')
    w.kick(2)
    w.check_at('floor 2 = MOON CELLAR (a gate insert)', CELLAR, TEST_REGION)
    w.save('gate2')
    for _ in range(3):
        w.keep_enc()
        w.step('right')
    w.follow(1200)
    w.idle()
    w.check('the hole -> floor 3', w.m[CUR_FLOOR] + 1 == 3,
            f'floor {w.m[CUR_FLOOR] + 1} map ${w.m[MAP_ID]:02X}')
    w.save('gate3')
    w.check('the WarpWing thrown', w.use_warpwing())
    w.follow(3000, until=lambda: w.where() == (HEARTH, TEST_REGION) and w.m[HUB_REASON] == 0
             and w.idle(400))
    w.check_at('WarpWing (floor 3) -> MOON HEARTH', HEARTH, TEST_REGION)
    w.check_said('WarpWing (floor 3)', 'cs_arrival_warpwing')
    w.check('the sprites are shown ($C8EC 0)', w.m[0xC8EC] == 0)


def s_warpwing0(w):
    print('warpwing0: the WarpWing on floor 1 (still region 0) -> MOON HEARTH (region 2)')
    w.start('gate1')
    w.check('floor 1 is in region 0', w.m[MAP_REGION] == 0, f'region {w.m[MAP_REGION]}')
    w.check('the WarpWing thrown', w.use_warpwing())
    w.follow(3000, until=lambda: w.where() == (HEARTH, TEST_REGION) and w.m[HUB_REASON] == 0
             and w.idle(400))
    w.check_at('WarpWing (floor 1) -> MOON HEARTH', HEARTH, TEST_REGION)
    w.check_said('WarpWing (floor 1)', 'cs_arrival_warpwing')


def swirl_hidden(w):
    """SUNDIAL HALL's portal swirl ($4D) slot: hidden (type bit 6)?"""
    m = w.m
    for n in range(8):
        b = 0xD7D2 + 32 * n
        if m[b + 1] == 0x4D:
            return bool(m[b] & 0x40)
    return None


def s_boss(w):
    print('boss: the boss floor MOON DAIS (region 2): win -> cleared, home')
    w.start('gate2')
    w.check('the DIAL GATE not cleared yet', w.ext_flag(CLEARED) == 0)
    w.kick(4)
    w.check_at('floor 4 = the boss floor MOON DAIS', DAIS, TEST_REGION)
    w.step('up')
    w.step('up')
    w.face('up')
    r = w.talk([True])
    w.check('the DIAL WARDEN fight started', r == 'battle', r)
    w.check('the fight won', w.battle_won())
    w.check(f'the gate cleared (${CLEARED:04X} ON — GateBossWin in region 2)',
            w.ext_flag(CLEARED) == 1)
    w.follow(3000, until=lambda: w.where() == (HEARTH, TEST_REGION) and w.m[HUB_REASON] == 0
             and w.idle(400))
    w.check_at('the warden sends us home -> MOON HEARTH', HEARTH, TEST_REGION)
    w.check_said('home by a script', 'cs_arrival_home')
    w.goto(HALL, 0, 5, 3)
    w.check('SUNDIAL HALL: the portal swirl stopped', swirl_hidden(w) is True)
    w.snap('boss_sun')


def s_castle(w):
    print('castle: the hub OFF (the KEEPER) -> a loss in region 2 goes to the Castle')
    w.start('hearth')
    w.goto(HEARTH, TEST_REGION, 2, 2)
    w.face('up')
    w.talk([True])
    w.idle()
    w.goto(HALL, TEST_REGION, 8, 4)
    w.face('up')
    w.party_hp_1()
    r = w.talk([True])
    w.check('the BRUISER fight started', r == 'battle', r)
    w.battle_lost()
    w.follow(1200)
    w.idle()
    w.check('lost with the hub off -> the Castle (map $00)', w.m[MAP_ID] == 0x00,
            f'at ${w.m[MAP_ID]:02X} region {w.m[MAP_REGION]}')
    w.check('the Castle\'s own arrival code after a loss ($D92B 8, then the priest)',
            w.m[CASTLE_EVENT] in (0x08, 0x03), f'${w.m[CASTLE_EVENT]:02X}')


def s_playhere(w):
    print('playhere: the editor\'s Play here (playback engine) into places of regions 2 and 0')
    if w.p is not None:
        w.p.stop(save=False)
        w.p = None
    from editor2.core import playback as PB, play_setup as PS, cutscenes as CS
    from editor2.core.project import Project
    proj_dir = os.path.dirname(os.path.dirname(os.path.abspath(w.build)))
    data = json.load(open(os.path.join(proj_dir, 'project.json')))
    prj = Project(copy.deepcopy(data), proj_dir)
    prj.repo_root = REPO
    rom = os.path.join(w.build, 'rom.gbc')
    for src in ('newgame', 'sav', 'story'):
        res = PS.resolve({'source': src, 'sav': w.sav, 'step': 5}, prj, REPO)
        eng = PB.Engine(rom, cache_dir=os.path.join(w.keep, 'playback'), sav_path=res['base_sav'],
                        sound=False)
        for mid in (0x200 | HALL, HALL, 0x200 | DAIS):
            rec = CS.room_recipe(mid, 0, 5, 5, facing=0)
            rec = rec._replace(flags_set=tuple(res['flags_set']),
                               flags_clear=tuple(res['flags_clear']), ram=dict(res['ram']))
            eng.start(rec, repoke=False, records=res['records'] or None)
            eng.tick(120)
            m = eng.m
            got = (m[MAP_ID], m[MAP_REGION])
            on = [f for f in res['flags_set'] if f < 0x1000]
            flags_ok = all((m[0xD99B + (f >> 3)] >> (7 - (f & 7))) & 1 for f in on)
            w.check(f'Play here ({src}) ${mid:03X}: map ${mid & 0xFF:02X} region {mid >> 8}, '
                    f'{len(on)} story flags', got == (mid & 0xFF, mid >> 8) and flags_ok
                    and 'the room did not finish loading' not in eng.log,
                    f'at ${got[0]:02X} region {got[1]}; {eng.log[:2]}')
        eng.p.stop(save=False)


STEPS = {'continue': s_continue, 'enter': s_enter, 'lose2': s_lose2, 'lose0': s_lose0,
         'breed': s_breed, 'wing': s_wing, 'gate': s_gate, 'warpwing0': s_warpwing0,
         'boss': s_boss, 'castle': s_castle, 'playhere': s_playhere}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True, help='a build dir of the S141 demo (rom.gbc, '
                    'game.sym, manifest.json; its project.json two levels up)')
    ap.add_argument('--sav', required=True)
    ap.add_argument('--steps', default=','.join(STEPS))
    ap.add_argument('--keep', default=None, help='where the states / pictures go')
    ap.add_argument('--negative', action='store_true', help='HubWarp loses the region: '
                    'lose0 + warpwing0 must FAIL')
    ap.add_argument('--negative-sheets', action='store_true', help='a custom room\'s NPC sheets '
                    '3-5 back in VRAM bank 0 (the pre-S141 r3 engine): the breed step\'s NPC '
                    'picture checks must FAIL')
    a = ap.parse_args()
    keep = a.keep or tempfile.mkdtemp(prefix='walk_regions_')
    os.makedirs(keep, exist_ok=True)
    w = Walk(os.path.abspath(a.build), os.path.abspath(a.sav), os.path.abspath(keep))
    if a.negative:
        w.break_hub_region()
    if a.negative_sheets:
        w.old_npc_banks()
    for name in a.steps.split(','):
        STEPS[name](w)
    if w.p is not None:
        w.p.stop(save=False)
    print(f'WALK: {"PASS" if w.fails == 0 else "FAIL " + str(w.fails)} ({w.checks} checks; '
          f'states + pictures in {keep})')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
