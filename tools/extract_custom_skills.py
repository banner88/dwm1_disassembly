#!/usr/bin/env python3
"""
extract_custom_skills.py — S111 (ROADMAP P3.11c): read the DATA of the custom
skills ($DE-$E9) out of a built patched ROM (+ its game.sym) into
editor2/core/custom_skills.json, the compiler's built-in baseline for them
(PROJECT_COMPILER §2.27; BATTLE_SKILL_SYSTEM §13-§14).

Until S111 these bytes were hand data in patches/bank_041/054/056/007/006/058/
04c/05f/072.asm; the compiler now emits them from custom_skills.json +
gamedata.skills.<224-254> overrides. This tool was run ONCE on the S110 pin
(534bfb62…, patched) to write the baseline; `--check` re-reads a built ROM and
compares it with the JSON (the byte-identity proof of the move). Reads three
layouts: the S110 pin's hand tables, the S111 engine's (CustomLearnTable
$E0-$FE, CustomMPCostTable from $DE) and the S155 engine's (CustomLearnTable
from $DE; + Repel / LoneWolf $DE/$DF, Punish..Rust $EB-$EE and their result
lines) and the S156 engine's (+ Plunder $EA and its line, when StealTable is in
the .sym; r2: the rise pages from CustomLine_PlunderDEF / _AGL) — test_compiler --rom
runs extract() on the example build.

USAGE
  python3 tools/extract_custom_skills.py --rom <build>/rom.gbc --sym <build>/game.sym [--write]
  python3 tools/extract_custom_skills.py --rom … --sym … --check
"""
import argparse
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from editor2.core import monster_text as MT  # noqa: E402

OUT = os.path.join(REPO, 'editor2', 'core', 'custom_skills.json')
IDS = range(0xDE, 0xEA)
HANDLER = {0xDE: 'retired', 0xDF: 'retired', 0xE0: 'magicburn', 0xE1: 'tame',
           0xE2: 'tame', 0xE3: 'tame', 0xE4: 'anchor', 0xE5: 'quake', 0xE6: 'quake',
           0xE7: 'quake', 0xE8: 'quake', 0xE9: 'mourn'}
# S155: the built-ins of S155 (Repel / LoneWolf on the retired POCs' ids $DE /
# $DF, Punish / Finish / Rupture / Rust $EB-$EE; Plunder $EA held) — read when
# the build has the S155 engine (CustomPctTable in the .sym)
S155_IDS = (0xDE, 0xDF, 0xEB, 0xEC, 0xED, 0xEE)
S155_HANDLER = {0xDE: 'repel', 0xDF: 'lonewolf', 0xEB: 'punish', 0xEC: 'finish',
                0xED: 'rupture', 0xEE: 'rust'}
S155_LINES = (('lonewolf_line', 'CustomLine_LoneWolf'), ('punish_line', 'CustomLine_Punish'),
              ('finish_line', 'CustomLine_Finish'), ('rupture_line', 'CustomLine_Rupture'),
              ('rust_line', 'CustomLine_Rust'))
# S156: Plunder $EA — read when the build has the S156 engine (StealTable in the .sym)
S156_IDS = (0xEA,)
S156_HANDLER = {0xEA: 'plunder'}
S156_LINES = (('plunder_line', 'CustomLine_Plunder'),)


def parse_sym(path):
    out = {}
    for line in open(path):
        p = line.split()
        if len(p) == 2 and ':' in p[0]:
            b, a = p[0].split(':')
            out[p[1]] = (int(b, 16), int(a, 16))
    return out


class Rom:
    def __init__(self, path, sym):
        self.d = open(path, 'rb').read()
        self.s = parse_sym(sym)

    def at(self, bank, addr, n):
        o = bank * 0x4000 + (addr - 0x4000 if bank else addr)
        return self.d[o:o + n]

    def lab(self, name, n, off=0):
        b, a = self.s[name]
        return self.at(b, a + off, n)

    def word(self, bank, addr):
        x = self.at(bank, addr, 2)
        return x[0] | x[1] << 8

    def string(self, bank, addr, end=0xF0):
        out = bytearray()
        while True:
            c = self.at(bank, addr + len(out), 1)[0]
            out.append(c)
            if c == end:
                return bytes(out)


def extract(r):
    sk = {}
    b41, ptr41 = r.s['SkillNamePtrTable']
    b56, ptr56 = r.s['SkillDescPtrTable']
    none56 = r.s['SkillDesc_None'][1]
    b54, rptr = r.s['CustomRecordPtrTable']
    b07, mpt = r.s['CustomMPCostTable']
    b58, ann = r.s['AnnounceTemplateTable']
    _, cann = r.s['CustomAnnounceTable']
    b4c, mptr = r.s['CustomMsgPtrTable']
    dummy = r.s['CustomMsg_dummy'][1]
    b5f, prox = r.s['CustomProxyTable']
    learn = {}
    s111 = 'CustomLearnTable' in r.s          # the S111 engine (one table, $E0-$FE)
    s155 = 'CustomPctTable' in r.s            # the S155 engine (the table from $DE)
    s156 = 'StealTable' in r.s                # the S156 engine (Plunder)
    ids = sorted(set(IDS) | set(S155_IDS) | (set(S156_IDS) if s156 else set())) if s155 \
        else list(IDS)
    if s111:
        t = r.s['CustomLearnTable']
        first = 0xDE if s155 else 0xE0
        for sid in ids:
            if sid < first:
                continue
            row = r.at(t[0], t[1] + 18 * (sid - first), 18)
            if row[0] != 0xFF:                 # level $FF = not learnable
                learn[sid] = row
        mp_first = 0xDE
    else:                                      # the S110 pin (hand tables)
        t1 = r.s['CustomLearnReqTable']
        for k, sid in enumerate((0xE1, 0xE2, 0xE3)):
            learn[sid] = r.at(t1[0], t1[1] + 18 * k, 18)
        t2 = r.s['CustomLearnReqTable2']
        for k, sid in enumerate((0xE5, 0xE6, 0xE7, 0xE8, 0xE9)):
            learn[sid] = r.at(t2[0], t2[1] + 18 * k, 18)
        mp_first = 0xE0
    for sid in ids:
        name = r.string(b41, r.word(b41, ptr41 + 2 * sid))[:-1]
        dp = r.word(b56, ptr56 + 2 * sid)
        desc = None if dp == none56 else r.string(b56, dp)[:-1]
        rp = r.word(b54, rptr + 2 * (sid - 0xDE))
        record = None if rp == 0x41CF else r.at(b54, rp, 19)
        mp = None if sid < 0xE0 and not s155 else r.word(b07, mpt + 2 * (sid - mp_first))
        tpl = r.at(b58, ann + sid, 1)[0] if sid < 0xE2 else r.at(b58, cann + sid - 0xE2, 1)[0]
        mp_ = r.word(b4c, mptr + 2 * (sid - 0xDE))
        msg = None if mp_ == dummy else r.string(b4c, mp_)
        hd = S155_HANDLER[sid] if s155 and sid in S155_HANDLER else \
            S156_HANDLER[sid] if s156 and sid in S156_HANDLER else HANDLER[sid]
        e = {'label': MT.decode(name), 'handler': hd,
             'name': MT.decode(name),
             'description': MT.desc_lines(desc) if desc else None,
             'mp': mp,
             'record': record.hex() if record else None,
             'learn': learn[sid].hex() if sid in learn else None,
             'announce_template': tpl,
             'message': msg.hex() if msg else None,
             'proxy': r.at(b5f, prox + sid - 0xDE, 1)[0]}
        if s155 and sid in S155_HANDLER:
            e['_since'] = 'S155'
        if s156 and sid in S156_HANDLER:
            e['_since'] = 'S156'
        sk[str(sid)] = e
    banners = {k: r.string(b4c, r.s[lab][1]).hex()
               for k, lab in (('quake_allies', 'CustomMsg_QuakeAllies'),
                              ('quake_flew', 'CustomMsg_QuakeFlew'),
                              ('mourn_boost', 'CustomMsg_MournBoost'))
               + (S155_LINES if s155 else ()) + (S156_LINES if s156 else ())}
    if s156 and 'CustomLine_PlunderDEF' in r.s:   # [S156 r2] line 7 / 8 = the line + a page
        main = bytes.fromhex(banners['plunder_line'])
        for key, lab in (('plunder_def_rise', 'CustomLine_PlunderDEF'),
                         ('plunder_agl_rise', 'CustomLine_PlunderAGL')):
            full = r.string(b4c, r.s[lab][1])
            banners[key] = (b'\xed' + full[len(main) - 2 + 4:]).hex()
    b72, tm = r.s['TameMeterTable']
    tame = {str(sid): r.word(b72, tm + 2 * k) for k, sid in enumerate((0xE1, 0xE2, 0xE3))}
    _, qp = r.s['QuakePowerTable']
    quake = {str(sid): list(r.at(b72, qp + 2 * k, 2)) for k, sid in
             enumerate((0xE5, 0xE6, 0xE7, 0xE8))}
    return {'skills': sk, 'banners': banners, 'tame_meter': tame, 'quake_power': quake}


def same_as_json(got, base):
    """S111 builds no longer carry the retired POCs' names (Scorch / Smite were
    dropped from bank $41, their name pointers name the empty string): take the
    JSON's for the comparison — every other byte must match."""
    for sid in ('222', '223'):
        g, b = got['skills'].get(sid), base['skills'].get(sid)
        if g and b and g['name'] == '':
            g['name'], g['label'] = b['name'], b['label']
    return got


DOC = [
    "S111 (ROADMAP P3.11c; PROJECT_COMPILER §2.27): the BUILT-IN data of the",
    "custom skills — what every build gets when gamedata.skills.<id> does not",
    "change it. $E0-$E9 read once from the S110 pin by",
    "tools/extract_custom_skills.py (until S111 these were hand bytes in banks",
    "$41/$54/$56/$07/$06/$58/$4C/$5F/$72); S155 added Repel / LoneWolf ($DE/$DF,",
    "the retired S45 POCs' ids) and Punish / Finish / Rupture / Blunt ($EB-$EE)",
    "(\"_since\": \"S155\", authored — PROJECT_COMPILER §2.63). Per skill: name /",
    "description (the SKIL text, null = the empty string), mp (CustomMPCostTable;",
    "the battle copy is record +4), record (19 B hex), learn (18 B hex; null = not",
    "naturally learnable), announce_template (the battle announce message id, $FD =",
    "this skill's own `message`, $FF = none), message (raw battle-text bytes,",
    "$F0-terminated), proxy (the stock skill whose animation / flash / sounds it",
    "borrows). handler = the bank $72 code that runs it (mechanism, not data).",
    "S156 added Plunder ($EA, \"_since\": \"S156\", authored — PROJECT_COMPILER §2.64).",
    "banners = the fixed extra battle lines (Quake, Mourn; S155 the result lines; S156 Plunder's).",
]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rom', required=True)
    ap.add_argument('--sym', required=True)
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    got = extract(Rom(a.rom, a.sym))
    if a.write:
        out = {'_doc': DOC, '_generator': 'tools/extract_custom_skills.py on the S110 pin '
               '534bfb6245e825445f6d45764ed7305e (patched)'}
        out.update(got)
        json.dump(out, open(OUT, 'w'), indent=1)
        print('wrote', OUT)
    if a.check:
        base = json.load(open(OUT))
        same_as_json(got, base)
        bad = [k for k in got if got[k] != base.get(k)]
        if bad:
            for k in bad:
                print('DIFF', k)
            sys.exit(1)
        print('custom_skills.json == ROM: OK')
    if not (a.write or a.check):
        print(json.dumps(got, indent=1))


if __name__ == '__main__':
    main()
