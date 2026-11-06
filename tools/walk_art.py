#!/usr/bin/env python3
"""walk_art.py — S170: monster art past banks $7F / $7C / $7A on the real game (PyBoy on the
user's .sav).

S170 lets `gamedata.art` re-art every original monster (0-214): the streams that do not fit
the three art banks spill into the 4 MB ROM's banks $80+ (taken LAST, after the page-2
banks), and every stream is stored as the smaller of its literal copy and a compressed
re-encode (editor2/core/art.py `pack` / `place`). No engine change: every reader of a
monster's art (the 13 battle-pose sites over ROM0 MonsterBattleGfxTable, the eight walking
gfx-ID copies) hands the table word to ROM0 WaitDMATransfer / WaitLCDTransfer ->
DecompressTileLayout, which maps any bank $01-$FF. This walk measures that.

The demo (examples/s170_mirror_demo/build_demo.py): all 215 re-arted — the battle pose
mirrored, the walking art with colours 1 / 2 swapped, their own walk styles.

  static   the BUILT ROM: every species' battle-table word and its row in all eight walking
           copies (the same word in each) resolve — through the ROM's own pointer tables —
           to a stream that decodes (dwm/sprite_codec.decode == the game's decoder, S106) to
           exactly the project's picture; how many live in banks $80+; no row still names
           the original stream;
  decode   (every step below) a hook on ROM0 WaitDMATransfer / WaitLCDTransfer: each time
           the game unpacks a monster's art, the bytes it wrote (VRAM in its current bank, or
           WRAM) == the project's picture of that gfx-ID; an original monster stream (a
           reader that missed the new table) = FAIL;
  follow   CONTINUE: the three followers' VRAM ($8200 / $8300 / $8400) == their walking art;
  swap     the party's species := three monsters stored in banks $80+ (the record's +$09),
           the room re-entered: the followers' VRAM == their walking art;
  menu     the field menu -> the first monster -> its pages: the battle pose unpacked;
  battle   a forced wild battle against a monster stored in banks $80+ (and one in $7F):
           its pose unpacked into VRAM == the mirrored picture;
  farm     (S170, the user's report) the farm's monster NPCs are PLAIN NPCs (ids $3A-$4C) whose
           sheets ROM0 $2ADF names — 19 monsters' ORIGINAL walking streams: unpacked == the
           original pictures (by design), the followers there == the new art;
  stub     every one of the project's art gfx-IDs unpacked by the game's own WaitDMATransfer
           (a stub call from a calm field into VRAM $8800): the bytes == the picture — all
           430 streams through the game's decoder; and the frames each took vs the ORIGINAL
           stream of the same monster (still in the ROM) — the load-speed comparison.

  python3 tools/walk_art.py --build DEMO/build/build --project DEMO/project.json \\
      --sav USER.sav --keep KEEP [--negative] [--steps …]

--negative: in the ROM copy every gfx-ID word that names a bank $80+ loses bit 7 of its bank
(the art read from bank $00-$7F instead): every check of a monster stored in banks $80+ must
FAIL (those in $7F / $7C / $7A pass — information).
Prints `ok` / `FAIL` per check and `WALK: PASS` / `WALK: FAIL n`.
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.pyboy_harness import adv, tap, PARTY_LIST, PLAYER_TX, PLAYER_TY   # noqa: E402
from tools.walk_regions import s_continue                                    # noqa: E402
from tools.walk_reclaim import ReclaimWalk, DEFEND                            # noqa: E402
from dwm import sprite_codec as C                                            # noqa: E402

REC, RECSZ = 0xCAC1, 149
STUB, MARK = 0xDEC0, 0xDEDC
# the eight walking copies: (label, rows before species 0)
WALK_TABLES = [('ScreenTransDataTable', 16), ('FollowerGfxTable06', 16),
               ('FollowerGfxTable07', 16), ('FollowerGfxTable09', 16),
               ('FollowerGfxTable0B', 16), ('FollowerGfxTable12', 16),
               ('FollowerGfxTable18', 0), ('FollowerGfxTable59', 0)]
BATTLE, WALK = 576, 256


def off(b, a):
    return b * 0x4000 + (a - 0x4000 if a >= 0x4000 else a)


class ArtWalk(ReclaimWalk):
    def load_tables(self, prj):
        """The project's pictures by species + the built ROM's gfx-IDs."""
        from editor2.core import art as AR
        res = AR.resolve(prj)
        self.want = {}                               # sid -> {'battle': bytes, 'walk': bytes}
        for sid, r in res.items():
            self.want[sid] = {'battle': C.decode(r['battle_art']) if r['battle_art'] else None,
                              'walk': C.decode(r['follower_art']) if r['follower_art'] else None}
        # the expectations come from the BUILT ROM; the emulator (and the static check) run
        # the walk's copy — the same bytes, unless --negative changed them
        rom = open(os.path.join(self.build, 'rom.gbc'), 'rb').read()
        self.romb = open(self.rom, 'rb').read()
        b, a = self.sym['MonsterBattleGfxTable']
        self.bgid = {s: rom[off(b, a) + 2 * s] | rom[off(b, a) + 2 * s + 1] << 8 for s in range(221)}
        self.wgid = {}
        for lab, skip in WALK_TABLES:
            b, a = self.sym[lab]
            self.wgid[lab] = {s: rom[off(b, a) + 2 * (s + skip)] | rom[off(b, a) + 2 * (s + skip) + 1] << 8
                              for s in range(215)}
        orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
        self.orig = orig
        ob = 0x2B9F
        self.vanilla_b = {s: orig[ob + 2 * s] | orig[ob + 2 * s + 1] << 8 for s in range(215)}
        ow = 0x49DF
        self.vanilla_w = {s: orig[ow + 2 * (s + 16)] | orig[ow + 2 * (s + 16) + 1] << 8
                          for s in range(215)}
        # gfx-ID -> (sid, kind, picture) for the project's art
        self.by_gid = {}
        for sid, wv in self.want.items():
            if wv['battle'] is not None:
                self.by_gid[self.bgid[sid]] = (sid, 'battle', wv['battle'])
            if wv['walk'] is not None:
                self.by_gid[self.wgid['ScreenTransDataTable'][sid]] = (sid, 'walk', wv['walk'])
        # an ORIGINAL monster stream that no patched row names any more = stale if unpacked
        still = set(self.bgid.values())
        for lab, skip in WALK_TABLES:
            b, a = self.sym[lab]
            for s in range(-skip, 221):
                still.add(rom[off(b, a) + 2 * (s + skip)] | rom[off(b, a) + 2 * (s + skip) + 1] << 8)
        # S170: the NPC SHEET table ROM0 $2ADF (96 words) — ids $3A-$4C share 19 monsters'
        # ORIGINAL walking streams (the game's decorative monster NPCs): still named, by design
        self.npc_gid = [rom[0x2ADF + 2 * i] | rom[0x2ADF + 2 * i + 1] << 8 for i in range(96)]
        still.update(self.npc_gid)
        self.npc_alias = set(self.npc_gid) & set(self.vanilla_w.values())   # the 19 shared
        self.stale = {}
        for sid in self.want:
            if self.want[sid]['battle'] is not None and self.vanilla_b[sid] not in still:
                self.stale[self.vanilla_b[sid]] = (sid, 'battle')
            if self.want[sid]['walk'] is not None and self.vanilla_w[sid] not in still:
                self.stale[self.vanilla_w[sid]] = (sid, 'walk')

    def ext(self, sid):
        return self.bgid[sid] >> 8 >= 0x80

    # -- the decode log
    def start(self, state=None):
        super().start(state)
        self.dec = []                                 # (gid, dest, vbk, caller, got bytes)
        self.pend = None
        for lab in ('WaitDMATransfer', 'WaitLCDTransfer'):
            b, a = self.sym[lab]
            self.p.hook_register(b, a, self._enter, lab)
            self.p.hook_register(b, a + 13, self._leave, lab)

    def _enter(self, lab):
        if self.pend is not None and self.pend[0] == lab:
            return                                    # the lock's busy-wait loops here
        rf, m = self.p.register_file, self.m
        sp = rf.SP
        self.pend = (lab, rf.D << 8 | rf.E, rf.HL, m[0xFF4F] & 1,
                     (m[0x4000], m[sp] | m[sp + 1] << 8))

    def _leave(self, lab):
        if self.pend is None:
            return
        _l, gid, dest, vbk, caller = self.pend
        self.pend = None
        npc = gid in self.npc_alias
        if gid not in self.by_gid and gid not in self.stale and not npc:
            return
        n = (len(self.by_gid[gid][2]) if gid in self.by_gid else
             WALK if npc else (BATTLE if self.stale[gid][1] == 'battle' else WALK))
        if 0x8000 <= dest < 0xA000:
            got = bytes(self.p.memory[vbk, dest:dest + n])
        else:
            got = bytes(self.m[dest + i] for i in range(n))
        self.dec.append((gid, dest, vbk, caller, got))

    def decode_checks(self, what, since=0, want_sids=()):
        new = self.dec[since:]
        ours = [d for d in new if d[0] in self.by_gid]
        stale = [d for d in new if d[0] in self.stale]
        bad = [d for d in ours if d[4] != self.by_gid[d[0]][2]]
        sids = {self.by_gid[d[0]][0] for d in ours}
        callers = sorted({f'${c[0]:02X}:{c[1]:04X}' for _g, _d, _v, c, _x in ours})
        self.check(f'{what}: {len(ours)} unpack(s) of the project\'s art, each == its picture',
                   bool(ours) and not bad,
                   f'callers {" ".join(callers[:8])}; species {sorted(sids)[:10]}'
                   + (f'; WRONG {[(hex(g), hex(d)) for g, d, *_ in bad[:4]]}' if bad else ''))
        self.check(f'{what}: no original monster stream unpacked', not stale,
                   ', '.join(f'{self.stale[g][0]} {self.stale[g][1]} ${g:04X} by ${c[0]:02X}:{c[1]:04X}'
                             for g, _d, _v, c, _x in stale[:4]))
        for sid in want_sids:
            hit = [d for d in ours if self.by_gid[d[0]][0] == sid]
            self.check(f'{what}: species {sid} ({"bank $80+" if self.ext(sid) else "bank $7F/$7C/$7A"}, '
                       f'${self.bgid[sid]:04X}) unpacked == its picture',
                       bool(hit) and all(d[4] == self.by_gid[d[0]][2] for d in hit),
                       f'{len(hit)} unpack(s)')

    def party(self):
        m = self.m
        return [m[PARTY_LIST + k] for k in range(3) if m[PARTY_LIST + k] != 0xFF]

    def follower_checks(self, what):
        m = self.m
        for k, slot in enumerate(self.party()):
            sid = m[REC + RECSZ * slot + 9]
            got = bytes(self.p.memory[0, 0x8200 + 0x100 * k:0x8300 + 0x100 * k])
            want = self.want.get(sid, {}).get('walk')
            self.check(f'{what}: follower {k} (species {sid}, '
                       f'{"bank $80+" if self.wgid["ScreenTransDataTable"][sid] >> 8 >= 0x80 else "$7F/$7C/$7A"}) '
                       f'VRAM ${0x8200 + 0x100 * k:04X} == its walking art', want is not None and got == want,
                       f'gfx ${self.wgid["ScreenTransDataTable"][sid]:04X}')


def s_static(w):
    print('static: the built ROM\'s tables -> streams -> pictures')
    rom = w.romb
    bad_b = bad_w = 0
    split = [False] * 8
    n_ext = 0
    bb, ba = w.sym['MonsterBattleGfxTable']

    def word(o):
        return rom[o] | rom[o + 1] << 8
    for sid, wv in sorted(w.want.items()):
        if wv['battle'] is not None:
            g = word(off(bb, ba) + 2 * sid)
            n_ext += g >> 8 >= 0x80
            if C.decode(C.read_stream(rom, C.gfxid_stream_offset(rom, g)[3])) != wv['battle']:
                bad_b += 1
        if wv['walk'] is not None:
            gs = [word(off(*w.sym[lab]) + 2 * (sid + skip)) for lab, skip in WALK_TABLES]
            if len(set(gs)) != 1:
                split[0] = True
            if C.decode(C.read_stream(rom, C.gfxid_stream_offset(rom, gs[0])[3])) != wv['walk']:
                bad_w += 1
    nb = sum(1 for v in w.want.values() if v['battle'] is not None)
    nw = sum(1 for v in w.want.values() if v['walk'] is not None)
    w.check(f'{nb} battle poses: MonsterBattleGfxTable -> the ROM\'s stream == the picture', bad_b == 0,
            f'{bad_b} wrong')
    w.check(f'{nw} walking arts: the eight copies name ONE gfx-ID per species', not split[0])
    w.check(f'{nw} walking arts: -> the ROM\'s stream == the picture', bad_w == 0, f'{bad_w} wrong')
    banks = sorted({g >> 8 for g in w.by_gid})
    print(f'  info: {n_ext} of {nb} battle poses in banks $80+; art banks used: '
          + ' '.join(f'${b:02X}' for b in banks))
    w.check('some of the art lives in banks $80+ (the point of the demo)', any(b >= 0x80 for b in banks))
    same = [sid for sid, v in w.want.items()
            if (v['battle'] is not None and w.bgid[sid] == w.vanilla_b[sid])
            or (v['walk'] is not None and any(w.wgid[lab][sid] == w.vanilla_w[sid]
                                              for lab, _s in WALK_TABLES))]
    w.check('no re-arted species\' row still names its original stream', not same, f'{same[:8]}')
    shared = sorted(set(w.vanilla_b.values()) - set(w.stale)) if w.want else []
    print(f'  info: {len(w.stale)} original streams no row names any more; still named by a '
          f'row that is not a re-arted monster: {len([g for g in shared if g in set(w.bgid.values())])} '
          '(e.g. Darkdrium\'s pose $320F = the summons 216-220, Iron Rule 8)')
    # compression: the stored streams vs their literal size
    lit = sum(3 + len(v[2]) for v in w.by_gid.values())
    stored = sum(len(C.read_stream(rom, C.gfxid_stream_offset(rom, g)[3])) for g in w.by_gid)
    print(f'  info: {len(w.by_gid)} streams, {stored:,} B stored vs {lit:,} B literal '
          f'({100 * stored / lit:.0f} %)')


def s_follow(w):
    print('follow: CONTINUE -> the followers\' VRAM')
    w.follower_checks('after CONTINUE')
    w.decode_checks('CONTINUE')


def s_swap(w):
    print('swap: the party := three monsters stored in banks $80+, the room re-entered')
    w.start('continue')
    m = w.m
    pick = [s for s in sorted(w.want) if w.ext(s) and w.wgid['ScreenTransDataTable'][s] >> 8 >= 0x80]
    pick = [pick[len(pick) // 6], pick[len(pick) // 2], pick[-1]]
    for k, slot in enumerate(w.party()):
        m[REC + RECSZ * slot + 9] = pick[k % 3]
    n0 = len(w.dec)
    mid, reg = w.where()
    x, y = m[PLAYER_TX], m[PLAYER_TY]
    w.goto(mid, reg, x, y - 8 if y >= 8 else y)
    w.snap('swap')
    w.follower_checks('re-entered')
    w.decode_checks('the room re-entered', n0, want_sids=pick[:len(w.party())])
    w.save('swapped')


def s_menu(w):
    print('menu: the field menu -> the first monster -> its pages')
    w.start('swapped')
    p = w.p
    n0 = len(w.dec)
    tap(p, 'a', hold=3, wait=90)                  # the field menu
    w.snap('menu_0')
    tap(p, 'a', hold=3, wait=90)                  # its first entry (the party)
    w.snap('menu_1')
    tap(p, 'a', hold=3, wait=120)                 # the first monster
    w.snap('menu_2')
    for k in range(3):
        tap(p, 'a', hold=3, wait=90)
        w.snap(f'menu_{3 + k}')
    lead = w.m[REC + RECSZ * w.party()[0] + 9]
    w.decode_checks('the menu', n0, want_sids=[lead])
    for _ in range(8):
        tap(p, 'b', wait=30)
    w.idle()


def eid_of(w, sid):
    from editor2.core import gamedata as G
    rows = G.vanilla(REPO)['tables']['enemy_stats']['rows']
    for i, r in enumerate(rows):
        if i and bytes.fromhex(r)[0] == sid:
            return i
    return None


def s_battle(w):
    print('battle: forced wild battles against monsters stored in banks $80+ / $7F')
    ext = [s for s in sorted(w.want) if w.ext(s) and eid_of(w, s)]
    home = [s for s in sorted(w.want) if not w.ext(s) and eid_of(w, s)]
    for sid in (ext[len(ext) // 3], ext[-1], home[len(home) // 2]):
        w.start('swapped')
        n0 = len(w.dec)
        eid = eid_of(w, sid)
        w.battle(eid, 900, party=DEFEND)
        w.snap(f'battle_{sid}')
        w.decode_checks(f'battle vs species {sid} (EID {eid})', n0, want_sids=[sid])


def s_farm(w):
    """S170 (the user, on the test ROM: "monster NPCs on farm have not been affected"): the
    farm's monsters are PLAIN NPCs (sprite ids $3A-$4C) whose sheets ROM0 $2ADF names — the
    ORIGINAL walking streams of 19 monsters, not the species tables. They keep the original
    art by design; the followers on the same screens show the new art."""
    print('farm: the game\'s decorative monster NPCs keep their original art')
    w.start('continue')
    m = w.m
    orig = w.orig
    vw = {g: s for s, g in w.vanilla_w.items()}
    seen = {}
    for x, y in ((15, 13), (25, 13), (5, 5)):
        n0 = len(w.dec)
        w.goto(0x04, 0, x, y)
        adv(w.p, 120)
        w.snap(f'farm_{x}_{y}')
        for i in range(8):
            spr = m[0xD7D2 + 32 * i + 1]
            if 0x3A <= spr <= 0x4C and m[0xD7D2 + 32 * i + 0x0F] == 0:
                seen[spr] = w.npc_gid[spr]
        for g, _d, _v, c, got in w.dec[n0:]:
            if g in vw and g in w.npc_gid:
                want = C.decode(C.read_stream(orig, C.gfxid_stream_offset(orig, g)[3]))
                w.check(f'farm NPC sheet ${g:04X} (= {vw[g]}\'s ORIGINAL walking stream, by '
                        f'${c[0]:02X}:{c[1]:04X}) unpacked == the original picture', got == want)
        w.follower_checks(f'farm ({x},{y})')
    w.check('the farm shows monster NPCs of the $3A-$4C block', bool(seen),
            ' '.join(f'${s:02X}->{vw.get(g, "?")}' for s, g in sorted(seen.items())))


def s_stub(w):
    print('stub: every art gfx-ID unpacked by WaitDMATransfer into VRAM $8800 (+ the speed)')
    w.start('swapped')
    w.idle()
    w.save('calm')
    b, a = w.sym['WaitDMATransfer']
    ok = bad = 0
    frames = {'ours': [], 'orig': [], 'lit': []}
    wrong = []

    # one state reload per gfx-ID is slow: run them back to back from one stub frame
    w.start('calm')
    m, p = w.m, w.p
    LY0, LY1 = 0xDEDA, 0xDEDB             # the stub (26 B from $DEC0) samples LY at its start + end

    def stub(gid):
        # ldh a,[LY] / ld [LY0],a / ld de,gid / ld hl,$8800 / call WaitDMATransfer /
        # ldh a,[LY] / ld [LY1],a / ld a,$A5 / ld [MARK],a / jr @
        return [0xF0, 0x44, 0xEA, LY0 & 0xFF, LY0 >> 8, 0x11, gid & 0xFF, gid >> 8,
                0x21, 0x00, 0x88, 0xCD, a & 0xFF, a >> 8, 0xF0, 0x44, 0xEA, LY1 & 0xFF,
                LY1 >> 8, 0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8, 0x18, 0xFE]

    def unpack(gid):
        for i, v in enumerate(stub(gid)):
            m[STUB + i] = v
        m[MARK] = 0
        p.register_file.PC = STUB
        k = 0
        while m[MARK] != 0xA5 and k < 120:
            p.tick()
            k += 1
        return (k - 1) * 154 + m[LY1] - m[LY0]
    for gid, (sid, kind, pic) in sorted(w.by_gid.items()):
        t = unpack(gid)
        got = bytes(p.memory[0, 0x8800:0x8800 + len(pic)])
        frames['ours'].append(t)
        if m[MARK] == 0xA5 and got == pic:
            ok += 1
        else:
            bad += 1
            wrong.append((sid, kind, hex(gid)))
        # the same monster's ORIGINAL stream (still in the ROM), for the speed
        frames['orig'].append(unpack(w.vanilla_b[sid] if kind == 'battle' else w.vanilla_w[sid]))
        if getattr(w, 'lit', None):
            t = unpack(w.lit[gid])
            frames['lit'].append(t)
            if bytes(p.memory[0, 0x8800:0x8800 + len(pic)]) != pic:
                wrong.append(('literal', sid, kind))
                bad += 1
    w.check(f'{len(w.by_gid)} art streams unpacked by the game == their pictures', bad == 0,
            f'{ok} ok, {bad} wrong {wrong[:5]}')
    fo, fv = frames['ours'], frames['orig']
    unit = 'scan lines (154 a frame; the stub reads LY before and after)'
    print(f'  info: time per unpack in {unit} — the project\'s streams avg {sum(fo) / len(fo):.0f} '
          f'(max {max(fo)}), the original streams avg {sum(fv) / len(fv):.0f} (max {max(fv)})')
    if frames['lit']:
        fl = frames['lit']
        print(f'  info: the same pictures stored LITERAL (pre-S170) avg {sum(fl) / len(fl):.0f} '
              f'(max {max(fl)})')
    w.check('the project\'s streams unpack no slower than the originals (average, +5 %)',
            sum(fo) / len(fo) <= 1.05 * sum(fv) / len(fv))


def stage_literals(w):
    """For the speed comparison only: the LITERAL form (the pre-S170 storage) of every one of
    the project's pictures, written into the walk's ROM copy at banks $F0+ (self-ID + pointer
    table + streams; refused unless those banks are empty in this build)."""
    from editor2.core.sheet_import import literal_stream
    rom = bytearray(open(w.rom, 'rb').read())
    bank, items, w.lit = 0xF0, [], {}

    def flush(bank, items):
        base = bank * 0x4000
        if any(rom[base + 1:base + 0x4000]):
            raise SystemExit(f'bank ${bank:02X} is not empty in this build')
        addr = 0x4001 + 2 * len(items)
        for i, (_g, st) in enumerate(items):
            rom[base + 1 + 2 * i:base + 3 + 2 * i] = bytes((addr & 0xFF, addr >> 8))
            rom[base + addr - 0x4000:base + addr - 0x4000 + len(st)] = st
            addr += len(st)
    used = 1
    for gid, (_sid, _k, pic) in sorted(w.by_gid.items()):
        st = literal_stream(pic)
        if used + 2 + len(st) > 0x4000:
            flush(bank, items)
            bank, items, used = bank + 1, [], 1
        w.lit[gid] = bank << 8 | len(items)
        items.append((gid, st))
        used += 2 + len(st)
    flush(bank, items)
    open(w.rom, 'wb').write(rom)
    print(f'speed reference: {len(w.lit)} literal streams staged in banks $F0-${bank:02X} of the walk\'s ROM copy')


def negative_rom(w):
    """In the ROM copy, inside every art bank $80+, the pointer table is rotated by one entry
    among the battle poses and among the walking arts (each stays a valid stream of its own
    kind — no crash): every gfx-ID in banks $80+ now names ANOTHER monster's picture. The
    checks of the monsters stored there must FAIL; those in $7F / $7C / $7A pass."""
    rom = bytearray(open(w.rom, 'rb').read())
    rom0 = open(os.path.join(w.build, 'rom.gbc'), 'rb').read()
    b, a = w.sym['MonsterBattleGfxTable']
    o = off(b, a)
    kind = {}
    for s_ in range(215):
        kind[rom0[o + 2 * s_] | rom0[o + 2 * s_ + 1] << 8] = 'battle'
    b, a = w.sym['ScreenTransDataTable']
    o = off(b, a) + 32
    for s_ in range(215):
        kind[rom0[o + 2 * s_] | rom0[o + 2 * s_ + 1] << 8] = 'walk'
    n = 0
    for bank in sorted({g >> 8 for g in kind if g >> 8 >= 0x80}):
        base = bank * 0x4000
        for k in ('battle', 'walk'):
            idx = sorted(g & 0xFF for g in kind if g >> 8 == bank and kind[g] == k)
            ptr = [rom0[base + 1 + 2 * i:base + 3 + 2 * i] for i in idx]
            for j, i in enumerate(idx):
                rom[base + 1 + 2 * i:base + 3 + 2 * i] = ptr[(j + 1) % len(ptr)]
            n += len(idx) if len(idx) > 1 else 0
    open(w.rom, 'wb').write(rom)
    w.negative = True
    print(f'NEGATIVE CONTROL: {n} pointer-table entries of the art banks $80+ rotated (each '
          'gfx-ID there names another monster\'s picture of the same kind)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--build', required=True)
    ap.add_argument('--project', required=True)
    ap.add_argument('--sav', required=True)
    ap.add_argument('--keep', required=True)
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--steps', default='static,follow,swap,menu,battle,farm,stub')
    a = ap.parse_args()
    os.makedirs(a.keep, exist_ok=True)
    w = ArtWalk(a.build, a.sav, a.keep)
    from editor2.core.project import Project
    prj = Project.load(a.project)
    prj.repo_root = REPO
    if a.negative:
        negative_rom(w)
    w.load_tables(prj)
    if 'stub' in a.steps.split(','):
        stage_literals(w)
    steps = {'static': s_static, 'follow': s_follow, 'swap': s_swap, 'menu': s_menu,
             'battle': s_battle, 'farm': s_farm, 'stub': s_stub}
    todo = [x for x in a.steps.split(',') if x]
    if 'static' in todo:
        s_static(w)
    if any(x != 'static' for x in todo):
        s_continue(w)
    for name in todo:
        if name == 'static':
            continue
        try:
            steps[name](w)
        except Exception as e:                       # noqa: BLE001 — a step that crashes fails
            import traceback
            traceback.print_exc()
            w.check(f'{name} ran', False, repr(e))
    print(f'WALK: {"PASS" if not w.fails else "FAIL " + str(w.fails)} ({w.checks} checks)')
    return 1 if w.fails else 0


if __name__ == '__main__':
    sys.exit(main())
