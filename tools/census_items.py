#!/usr/bin/env python3
"""census_items.py — ITEMS measured in the game (S151, ROADMAP E9; PROJECT_COMPILER
§2.59, DATA_STRUCTURES "Items (S151)").

S151 moved every item record to bank $77 (entry 16 ItemRecordCopy, which also sets
wItemBase = the item's BEHAVIOUR id) and let a project add NEW items 44-127 that run
a base item's code. The census boots a built ROM to the title screen in PyBoy and,
from a WRAM stub (PYBOY_DEBUGGING S109 / S130: a stub that ends in a marker write;
a hook that abandons a routine restores SP and jumps to the marker), calls the
game's own item routines for EVERY id — the model is editor2/core/items.py:

  record   bank $03 entry 2 (the copy every item flow does first) for ids 0-127
           and a few past the table: $DA62-$DA6D == the model's record (zeros past
           the table) and wItemBase == the model's base (0 past the table);
  usable   bank $03 entry 3 (may it be used now?): the id its jump table dispatches
           on (A at its `rst $00`) == the base;
  effect   bank $03 entry 4 (the field effect): the same at its `rst $00`;
  battle   bank $77 entry 17 (the battle menu's scan) and 18 (the pick, the item in
           bag slot 0): the battle skill handed to bank $54 ([$db4c] at bank $54
           entries 0 / 5) == base + $AF; entry 18's wItemInUse == the item;
  texts    every item name / description slot (bank $41 modes 8 / 9, rows 0-127) and
           every use line (mode 13, rows 0-55), shown (CallTextEngine) and copied
           (RunTextHandler) as census_text_override.py does == the project's text
           (a new item's own, an edit, or the build's original);
  sell     ShopSellPrice ($09) for every item: what a shop pays == the model (a
           tenth for a staff-based item, else 3/4); the SELL list builder
           SetFld9_4c24 and the Vault's deposit list SetFld9_5199 on bags of new
           items: the list at $C0D8 == the distinct ids (sellable only for SELL),
           in id order, and the counts at $D665 + id.

Usage:
  census_items.py --make DIR [--base PROJECT]    the census project: the base project
        (default editor2/example-project) + 84 new items (ids 44-127, every base twice,
        varied fields, own use lines) + edits of the game's items; built into
        DIR/build/build
  census_items.py --project DIR [--rom ROM] [--negative] [--out F]
  census_items.py --selftest      (verify check 5, offline: the model reproduces the
        game's 44 records, and the saved census is clean)
--negative: two pokes of a ROM copy — (base) ItemRecordCopy's `ld [wItemBase], a` ->
nops: the field dispatches / the sell price of the new items must FAIL; (battle)
BattleSkillOf's base-table read -> nop: the battle checks must FAIL.
Writes extracted/items_census.json.
"""
import argparse
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
try:
    from tools.pyboy_harness import boot, adv                     # noqa: E402
except ImportError:
    boot = adv = None
from editor2.core import items as IT, gametext as GT, textmark as TM   # noqa: E402
from tools.census_text_override import run_stub as text_stub, rom_text, CALL_SHOW, \
    CALL_COPY, BUF                                                     # noqa: E402

OUT = os.path.join(REPO, 'extracted', 'items_census.json')
STUB = 0xDD40
MARK = STUB - 1
SP0 = 0xDFF0
DA62 = 0xDA62
BAG, VAULT = 0xCA51, 0xCA65
STAFF_BASES = {0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x25, 0x27}


# --------------------------------------------------------------------------- make
def make_project(out_dir, base):
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    shutil.copytree(base, out_dir, ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(out_dir, 'project.json')
    d = json.load(open(pj))
    items = []
    for i in range(IT.FIRST_NEW, IT.ID_MAX + 1):
        k = i - IT.FIRST_NEW
        e = {'id': i, 'name': f'Item{i}', 'base': 1 + k % 43,
             'description': f'Census item {i}\nworks like {1 + k % 43}',
             'price': (i * 37) % 9000, 'consume': (i * 13) % 101, 'power': (i * 3) % 256,
             'field_use': k % 4 != 1, 'pick_monster': k % 3 != 2,
             'sellable': k % 5 != 0, 'keep_on_loss': k % 2 == 0}
        if k % 3 == 0:
            e['use_text'] = f'{{ins 00}} tries\nItem{i}!'
        else:
            e['use_message'] = k % 48
        if k % 7 == 0:
            e['result_text'] = f'Item{i} did\nsomething.'
        items.append(e)
    d.setdefault('custom', {})['items'] = items
    gd = d.setdefault('gamedata', {})
    gd['items'] = {'29': {'consume': 0}, '1': {'power': 50, 'price': 9},
                   '24': {'sellable': False}, '41': {'keep_on_loss': False},
                   '19': {'field_use': False, 'use_message': 30}}
    json.dump(d, open(pj, 'w'), indent=1, ensure_ascii=False)
    r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                        '--project', out_dir, '--build'], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(r.stdout[-3000:] + r.stderr[-3000:])
    print(f'census project: {len(items)} new items, built into {out_dir}/build/build')


# --------------------------------------------------------------------------- the stub
def sym_table(rom):
    out = {}
    for line in open(os.path.join(os.path.dirname(rom), 'game.sym')):
        m = re.match(r'([0-9a-f]+):([0-9a-f]+) (\S+)', line)
        if m:
            out[m.group(3)] = (int(m.group(1), 16), int(m.group(2), 16))
    return out


class Rig:
    def __init__(self, rom_path):
        tmp = tempfile.mkdtemp()
        rc = os.path.join(tmp, 'census.gbc')
        shutil.copy(rom_path, rc)
        self.p = boot(rc)
        adv(self.p, 600)
        self.st = io.BytesIO()
        self.p.save_state(self.st)
        self.m = self.p.memory
        self.caught = None
        self.marker = None

    def reset(self):
        self.st.seek(0)
        self.p.load_state(self.st)

    def run(self, code, pokes=(), frames=400):
        """code = the stub's middle bytes; the marker write follows. -> True if done."""
        m = self.m
        body = [0xF3] + list(code)
        self.marker = STUB + len(body)
        body += [0x3E, 0xA5, 0xEA, MARK & 0xFF, MARK >> 8, 0x18, 0xFE]
        for i, b in enumerate(body):
            m[STUB + i] = b
        for a, v in pokes:
            m[a] = v
        m[MARK] = 0
        self.caught = None
        self.p.register_file.SP = SP0
        self.p.register_file.PC = STUB
        for _ in range(frames):
            self.p.tick(1, False)
            if m[MARK] == 0xA5:
                return True
        return False

    def abandon_hook(self, bank, addr, read):
        """At bank:addr record read() and leave the routine (SP back, PC -> marker)."""
        def cb(_ctx):
            if self.caught is None:
                self.caught = read()
            self.p.register_file.SP = SP0
            self.p.register_file.PC = self.marker
        self.p.hook_register(bank, addr, cb, None)

    def stop(self):
        self.p.stop(save=False)


def far(hl):
    return [0x21, hl & 0xFF, hl >> 8, 0xD7]          # ld hl, nn / rst $10


# --------------------------------------------------------------------------- census
def census(project, rom_path, quiet=False):
    from editor2.core.project import Project
    prj = Project.load(project)
    prj.repo_root = REPO
    r = IT.resolve(prj, REPO)
    count = r['count']
    rom = open(rom_path, 'rb').read()
    sy = sym_table(rom_path)
    wbase = sy['wItemBase'][1]
    winuse = sy['wItemInUse'][1]
    res = {'items': count, 'new': len(r['new']), 'checks': 0, 'by_class': {}, 'fails': []}

    def check(what, ok, detail=''):
        res['checks'] += 1
        cls = ' '.join(what.split()[:2]) if what.startswith('battle') else what.split()[0]
        c = res['by_class'].setdefault(cls, [0, 0])
        c[0] += bool(ok)
        c[1] += 1
        if not ok:
            res['fails'].append({'check': what, 'detail': detail})

    rig = Rig(rom_path)
    # -- record + wItemBase -------------------------------------------------
    ids = list(range(0, IT.ID_MAX + 1)) + [128, 200, 254, 255]
    for i in ids:
        rig.reset()
        ok = rig.run([0x3E, i, 0xEA, 0x5E, 0xDA] + far(0x0302), [(wbase, 0xEE)])
        got = bytes(rig.m[DA62 + k] for k in range(IT.RECORD))
        want = r['records'][i] if i < count else bytes(IT.RECORD)
        wb = r['base'][i] if i < count else 0
        check(f'record {i}', ok and got == want, f'{got.hex()} vs {want.hex()}')
        check(f'wItemBase {i}', ok and rig.m[wbase] == wb, f'{rig.m[wbase]} vs {wb}')
    rig.stop()
    # -- the two bank $03 dispatches (A at their rst $00) -------------------
    rig = Rig(rom_path)
    rst3 = 0x69A2 + 9          # ItemCheckUsable: ld a,[da5e] / cp $ff / ret z / ld a,[wItemBase] / rst
    rst4 = 0x6E24 + 12         # ItemApplyEffect: … call ItemLoadRecord / ld a,[wItemBase] / rst
    assert rom[0x03 * 0x4000 + rst3 - 0x4000] == 0xC7 and rom[0x03 * 0x4000 + rst4 - 0x4000] == 0xC7
    rig.abandon_hook(0x03, rst3, lambda: ('usable', rig.p.register_file.A))
    rig.abandon_hook(0x03, rst4, lambda: ('effect', rig.p.register_file.A))
    for i in range(1, count):
        if i >= IT.GAME_ITEMS and i not in r['new']:
            continue
        for kind, code in (('usable', far(0x0302) + far(0x0303)), ('effect', far(0x0304))):
            rig.reset()
            rig.run([0x3E, i, 0xEA, 0x5E, 0xDA, 0x3E, 0x00, 0xEA, 0x60, 0xDA] + code)
            got = rig.caught
            check(f'{kind} {i}', got == (kind, r['base'][i]), f'{got} vs base {r["base"][i]}')
    rig.stop()
    # -- the battle menu (bank $77 entries 17 / 18 -> bank $54 entries 0 / 5) --
    rig = Rig(rom_path)
    e0 = rom[0x54 * 0x4000 + 1] | rom[0x54 * 0x4000 + 2] << 8
    e5 = rom[0x54 * 0x4000 + 11] | rom[0x54 * 0x4000 + 12] << 8
    rig.abandon_hook(0x54, e0, lambda: ('probe', rig.m[0xDB4C], rig.m[0xDB4E]))
    rig.abandon_hook(0x54, e5, lambda: ('pick', rig.m[0xDB4C], rig.m[winuse]))
    for i in range(1, count):
        if i >= IT.GAME_ITEMS and i not in r['new']:
            continue
        skill = (r['base'][i] + 0xAF) & 0xFF
        rig.reset()
        rig.run([0x1E, i] + far(0x7711))                       # ld e, i
        check(f'battle probe {i}', rig.caught == ('probe', skill, 0x0A),
              f'{rig.caught} vs skill ${skill:02X}')
        rig.reset()
        rig.run([0x1E, 0x00] + far(0x7712), [(BAG, i)])
        check(f'battle pick {i}', rig.caught == ('pick', skill, i),
              f'{rig.caught} vs skill ${skill:02X}, item {i}')
    rig.stop()
    # -- the texts (bank $41 modes 8 / 9 / 13) ------------------------------
    edits = {(x.source, x.key): raw for x, raw in GT.resolve(prj, REPO)}
    ix = GT.index(REPO)
    p = boot(rom_path)
    adv(p, 600)
    st = io.BytesIO()
    p.save_state(st)
    rows = [('item_name', IT.NAME_TABLE, n) for n in range(1, count)] + \
           [('item_description', IT.DESC_TABLE, n) for n in range(1, count)] + \
           [('item_use_message', IT.USE_TABLE, n) for n in range(0, IT.USE_MESSAGES
                                                                   + len(r['messages']))]
    res['texts'] = 0
    for src, table, n in rows:
        if src != 'item_use_message' and n >= IT.GAME_ITEMS and n not in r['new']:
            continue
        want = edits.get((src, str(n)))
        if want is None:
            x = ix.get(src, str(n))
            if x is None:
                continue
            o = 0x41 * 0x4000 + table + 2 * n - 0x4000
            want = rom_text(rom, 0x41, rom[o] | rom[o + 1] << 8)
        res['texts'] += 1
        for mode, call in (('show', CALL_SHOW), ('copy', CALL_COPY)):
            st.seek(0)
            p.load_state(st)
            ok = text_stub(p, 0x41, table, n, call)
            mm = p.memory
            if mode == 'show':
                got = rom_text(rom, mm[0xC824], mm[0xC82D] | mm[0xC82E] << 8) if ok else None
                exp = want
            else:
                buf = bytes(mm[BUF + k] for k in range(256))
                got = buf[:buf.find(b'\xf0') + 1] if ok and b'\xf0' in buf else None
                exp = want[:want.index(0xF0) + 1] if want else None
            check(f'{src} {n} {mode}', got == exp, f'{got.hex() if got else None} vs '
                  f'{exp.hex() if exp else None}')
    p.stop(save=False)
    # -- selling and the Vault ($09) ----------------------------------------
    rig = Rig(rom_path)
    sell = sy['ShopSellPrice'][1]
    for i in range(1, count):
        if i >= IT.GAME_ITEMS and i not in r['new']:
            continue
        rec = r['records'][i]
        price = rec[1] | rec[2] << 8
        want = price // 10 if r['base'][i] in STAFF_BASES else price - price // 4
        rig.reset()
        rig.run([0x3E, i, 0xEA, 0x5E, 0xDA, 0x3E, 0x09, 0xEA, 0x00, 0x21,
                 0xCD, sell & 0xFF, sell >> 8, 0x7D, 0xEA, 0x30, 0xDD, 0x7C, 0xEA, 0x31, 0xDD],
                [(0xC968, 0x00)])
        got = rig.m[0xDD30] | rig.m[0xDD31] << 8
        check(f'sell price {i}', got == want, f'{got} vs {want}')
    news = sorted(r['new'])
    bags = [news[k:k + 20] for k in range(0, len(news), 20)] + \
        [[news[0]] * 3 + [news[-1]] * 2 + [1, 29, 24] + news[5:17]]
    for bi, bag in enumerate(bags):
        bag = (bag + [0xFF] * 20)[:20]
        held = [x for x in bag if x != 0xFF]
        for kind, lab in (('sell', 'SetFld9_4c24'), ('deposit', 'SetFld9_5199')):
            a = sy[lab][1]
            rig.reset()
            rig.run([0x3E, 0x09, 0xEA, 0x00, 0x21, 0xCD, a & 0xFF, a >> 8],
                    [(BAG + k, v) for k, v in enumerate(bag)])
            lst = []
            for k in range(40):
                v = rig.m[0xC0D8 + k]
                if v in (0, 0xFF):
                    break
                lst.append(v)
            want = sorted({x for x in held if kind == 'deposit' or not r['records'][x][11] & 1})
            counts = {x: rig.m[0xD665 + x] for x in want}
            wc = {x: (held.count(x) if kind == 'deposit' or not r['records'][x][11] & 1 else 0)
                  for x in want}
            check(f'{kind} list, bag {bi}', lst == want, f'{lst} vs {want}')
            check(f'{kind} counts, bag {bi}', counts == wc, f'{counts} vs {wc}')
    rig.stop()
    return res


def summary(res):
    return (f"{res['items']} item ids ({res['new']} new), {res.get('texts', 0)} texts: "
            f"{res['checks'] - len(res['fails'])} / {res['checks']} checks ok, "
            f"{len(res['fails'])} FAIL")


def negative_rom(rom, cls):
    """cls 'base': ItemRecordCopy's `ld [wItemBase], a` -> nops (the field dispatches of the
    new items read a stale base); cls 'battle': BattleSkillOf's `ld a, [hl]` (the base
    table read) -> nop (every battle skill wrong)."""
    sy = sym_table(rom)
    data = bytearray(open(rom, 'rb').read())
    if cls == 'base':
        b, a = sy['ItemRecordCopy']
        o = b * 0x4000 + a - 0x4000
        wb = sy['wItemBase'][1]
        k = data.find(bytes([0xEA, wb & 0xFF, wb >> 8]), o, o + 0x30)
        assert k > 0
        data[k:k + 3] = b'\x00\x00\x00'
    else:
        b, a = sy['BattleSkillOf']
        o = b * 0x4000 + a - 0x4000
        k = data.find(bytes([0x67, 0x7E]), o, o + 0x20)        # ld h, a / ld a, [hl]
        assert k > 0
        data[k + 1] = 0x00
    tmp = tempfile.mkdtemp()
    out = os.path.join(tmp, 'negative.gbc')
    open(out, 'wb').write(data)
    shutil.copy(os.path.join(os.path.dirname(rom), 'game.sym'), tmp)
    return out


def selftest():
    """Offline: the model's records for an empty project == the game's 44 records (from
    the ROM when present, else gamedata_vanilla.json) and the saved census is clean."""
    van = IT.vanilla_records(REPO)
    rom_path = os.path.join(REPO, 'data', 'DWM-original.gbc')
    if os.path.exists(rom_path):
        rom = open(rom_path, 'rb').read()
        o = 0x03 * 0x4000 + 0x71DA - 0x4000
        bad = [i for i in range(IT.GAME_ITEMS) if rom[o + 12 * i:o + 12 * i + 12] != van[i]]
        if bad:
            print(f'FAIL: gamedata_vanilla.json item_info differs from the ROM at items {bad}')
            return 1
    r = IT.resolve({}, REPO)
    if r['records'] != van or r['base'] != list(range(IT.GAME_ITEMS)):
        print('FAIL: an empty project does not reproduce the 44 records / identity bases')
        return 1
    for i, rec in enumerate(van):
        rb = bytearray(rec)
        f = IT.decode(rec)
        IT.apply_fields(rb, {k: f[k] for k in ('price', 'consume', 'field_use', 'pick_monster',
                                               'use_message', 'result_message', 'power',
                                               'sellable', 'keep_on_loss')}, f'item {i}')
        if bytes(rb) != rec:
            print(f'FAIL: item {i}: decode -> apply does not round-trip')
            return 1
    msg = 'OK: the 44 records == the ROM; decode / apply round-trip; identity bases'
    if os.path.exists(OUT):
        res = json.load(open(OUT))
        if res.get('fails'):
            print(f'FAIL: {OUT}: {summary(res)}')
            return 1
        msg += f'; census {summary(res)}'
    print(msg)
    return 0


def main(argv):
    ap = argparse.ArgumentParser()
    ap.add_argument('--make')
    ap.add_argument('--base', default=os.path.join(REPO, 'editor2', 'example-project'))
    ap.add_argument('--project')
    ap.add_argument('--rom')
    ap.add_argument('--negative', action='store_true')
    ap.add_argument('--out', default=OUT)
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args(argv)
    if a.selftest:
        return selftest()
    if a.make:
        make_project(a.make, a.base)
        return 0
    if not a.project:
        ap.error('--project, --make or --selftest')
    rom = a.rom or os.path.join(a.project, 'build', 'build', 'rom.gbc')
    if a.negative:
        rc = 0
        for cls in ('base', 'battle'):
            res = census(a.project, negative_rom(rom, cls), quiet=True)
            kinds = sorted({' '.join(f['check'].split()[:2]) if f['check'].startswith('battle')
                            else f['check'].split()[0] for f in res['fails']})
            print(f'NEGATIVE {cls}: {summary(res)}; failing: {kinds}')
            if not res['fails']:
                print(f'  ERROR: the {cls} poke went unnoticed')
                rc = 1
        return rc
    res = census(a.project, rom)
    print(summary(res))
    for f in res['fails'][:30]:
        print('  FAIL', f)
    json.dump({'_generator': 'tools/census_items.py (S151): every item id stub-called through '
               'the game\'s item routines in PyBoy on a build of '
               + os.path.basename(os.path.abspath(a.project)), **res},
              open(a.out, 'w'), indent=1)
    return 1 if res['fails'] else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
