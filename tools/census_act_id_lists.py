#!/usr/bin/env python3
"""census_act_id_lists.py — every battle routine that tests the ACTING skill id,
run for a NEW skill and for its BASE (S163, ROADMAP E17 note "Act-time id lists").

A new skill (ids $EF-$FE and the 14 reclaimed ids $BC-$C1 / $CC-$D3) runs its base's
EFFECT (bank $72 FarSkillFork) with its own record; the enemy AI judges it as its base
(S161, the view). Any OTHER code that decides by the skill's id — a membership list, a
range, a compare ladder — sees the new id itself and may treat it unlike its base (S161
found one: the duplicate-group-cast conversion, fixed by DupBase53). This tool finds
them all, mechanically:

  1. Census projects: the example project + 30 new skills, one per allowed base, each
     with its base's data (the editor's defaults: record, MP, element … copied) — every
     base appears once on a HIGH id and once on a RECLAIMED id (8 builds, 112 bases).
  2. Sites: every instruction of the built ROM that reads the working id `$DB8A`, the
     selected skill `$DB4F` (absolute `ld a, [nn]`, or `ld hl / de / bc, nn` before a
     read) or the action queue `$DCEC` (`ld hl / de / bc, $DCEC`). The record index
     `$DB4C` is seeded with the id too (the game re-derives it from `$DB8A`) but is not a
     START: the game reuses it to pass record fields and slot numbers back (S163: every
     `$DB4C`-start root was that).
  3. Each site runs (tools/sm83run.py, far calls followed) from the read with those
     variables = the id (TAINTED), once for the base and once for the new skill; its
     signature = the ID TESTS taken in the ORIGINAL game's code (a branch whose flags come
     from the id, or a table read indexed by it — instructions whose bytes are the
     original ROM's; the patches' own forks, which map a new id to its base on purpose,
     are left out). A site where a new skill's tests differ from its base's is a
     CANDIDATE — then judged by hand (what the branch decides) and measured in PyBoy.

Banks $57 (the AI rule chains: `$DB8A` holds the BASE there since S161) and the bank
$58 estimate (EstimateView58) are run but tagged `view`: at run time they see the base.

    python3 tools/census_act_id_lists.py                # build + census -> extracted/
    python3 tools/census_act_id_lists.py --reuse DIR    # census already-built DIR/b*/

Output: extracted/act_id_lists_census.json (sites, per-site differing bases, verdicts
from ROOT_VERDICTS below; a root not listed there is NEW and the tool exits 1).
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
from tools.sm83run import CPU                                   # noqa: E402

OUT = os.path.join(REPO, 'extracted', 'act_id_lists_census.json')
EXAMPLE = os.path.join(REPO, 'editor2', 'example-project')
HIGH = list(range(0xEF, 0xFF))                                   # 16
RECL = list(range(0xBC, 0xC2)) + list(range(0xCC, 0xD4))         # 14
VARS = {0xDB8A: 'working id $DB8A', 0xDB4C: 'record index $DB4C',
        0xDB4F: 'selected $DB4F', 0xDCEC: 'action queue $DCEC'}
QUEUE = [0xDCEC + 2 * k for k in range(6)]
# the message numbers a run writes (S163: SkillLushLicks builds its line from the id — `ld a,
# [$db8a] / add $2F`; no branch shows it): the effect selector $DD70 / $DD71 and the line to
# print $C822 / $C823
MSG_VARS = {0xDD70, 0xDD71, 0xC822, 0xC823}
LIMIT = 900

# The verdict of each ROOT left after the S163 fix (judged by hand from the code + PyBoy;
# a root not listed here is reported as NEW — re-check the list when the census grows).
ROOT_VERDICTS = {
    '$00:0987': 'name: the announce copies the skill NAME by the real id (text $06xx — a new '
                'skill\'s own name, as intended)',
    '$50:5A31': 'name: SaveBtl_5ad2 renames the internal ids $DA-$DD; any other id keeps its own '
                'name (the real id, as intended)',
    '$00:2FAA': 'not a skill id: bank $58 jr_058_454d / jr_058_45e1 reuse $DB4F as a SLOT number '
                '(CheckMonsterSlot) in the target pick',
    '$52:74C1': 'not a skill: the hero ITEM action (jr_052_74af, $DB78) — items, not skills, '
                'reach it',
    '$53:4ECE': 'not a base question: DupCastQueueCompare_4eb1 compares two actors\' queued ids '
                'for EQUALITY (two enemies with the same new skill match)',
    '$5F:6379': 'field UI (LoadFldUI_6360): $DB4F there is the field menu\'s scratch',
    '$52:54C3': 'PoisonGas / PoisonAir build their line from $DB4C = a RECORD field there (the '
                'census seeds it with the id); not a base (clone census)',
    '$57:7C57': 'bank $57 entry 1 read raw (CallHelp) — reached only through bank $52 '
                'SetHLBattle_7d77 -> Entry1Base52, which shows it the base (S163)',
    '$57:7C5B': 'bank $57 entry 1 read raw (YellHelp) — the same: Entry1Base52 (S163)',
}


def load_sym(path):
    sym, by_bank = {}, {}
    for line in open(path):
        if not line.strip() or line[0] == ';':
            continue
        a, name = line.split()[:2]
        b, ad = a.split(':')
        b, ad = int(b, 16), int(ad, 16)
        sym[name] = (b, ad)
        if ad < 0x8000:
            by_bank.setdefault(b if ad >= 0x4000 else 0, []).append((ad, name))
    for v in by_bank.values():
        v.sort()
    return sym, by_bank


def label_of(by_bank, bank, addr):
    best = None
    for ad, name in by_bank.get(bank if addr >= 0x4000 else 0, []):
        if ad <= addr:
            if '.' not in name or best is None:
                best = (ad, name)
        else:
            break
    return f"{best[1]}+${addr - best[0]:X}" if best else f"${bank:02X}:{addr:04X}"


def find_sites(rom, banks, sym=None):
    """[(bank, addr, var, how)] — the reads of the id variables (see the module doc), and
    (S163) every call of the act-time base view (ActBase / MenuBase / QueueBase /
    QueueBaseInc / CmpBase in banks $50 / $52 / $53 / $58): the reads they replaced."""
    out = []
    views = {}
    for name, (b, a) in (sym or {}).items():
        if name.startswith(('ActBase', 'MenuBase', 'QueueBase', 'CmpBase', 'Entry1Base')) \
                and '.' not in name:
            views[(b, a)] = name
    for bank in banks:
        base = bank * 0x4000 if bank else 0
        lo = 0x4000 if bank else 0x0000
        data = rom[base:base + 0x4000]
        for i in range(len(data) - 2):
            op, w = data[i], data[i + 1] | data[i + 2] << 8
            if op == 0xFA and w in (0xDB8A, 0xDB4F):
                out.append((bank, lo + i, w, 'ld a,[nn]'))
            elif op in (0x21, 0x11, 0x01) and w in VARS and w != 0xDB4C:
                out.append((bank, lo + i, w, {0x21: 'ld hl', 0x11: 'ld de', 0x01: 'ld bc'}[op]))
            elif op in (0xCD, 0xC3) and (bank, w) in views:
                v = views[(bank, w)]
                var = 0xDB4F if v.startswith('MenuBase') else \
                    0xDCEC if v.startswith('QueueBase') else 0xDB8A
                out.append((bank, lo + i, var, f'call {v}'))
    return out


def run_site(cpu, rom, bank, addr, ident):
    """The ID TESTS (tools/sm83run.py taint: branches whose flags come from the id) of one
    run from the site with the id variables = ident (tainted), and how it stopped."""
    cpu.reset()
    cpu.bank = bank or 1
    for v in (0xDB8A, 0xDB4C, 0xDB4F):
        cpu.poke(v, ident, mark=True)
    for q in QUEUE:
        cpu.poke(q, ident, mark=True)
    cpu.watch_writes = MSG_VARS
    r = cpu.run(addr, limit=LIMIT, follow_far=True)
    stop = (r.kind, None if r.kind == 'limit' else (r.bank, r.pc),
            (r.cf, r.zf) if r.kind == 'ret' else None)
    return r.events, stop, list(cpu.wlog)


def project_for(bases_high, bases_recl, dst):
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(EXAMPLE, dst, ignore=shutil.ignore_patterns('build'))
    pj = os.path.join(dst, 'project.json')
    data = json.load(open(pj))
    sk = data.setdefault('gamedata', {}).setdefault('skills', {})
    for sid, b in list(zip(HIGH, bases_high)) + list(zip(RECL, bases_recl)):
        sk[str(sid)] = {'base': int(b), 'name': f'C{b}'}
    json.dump(data, open(pj, 'w'), indent=1)
    return pj


def plan(bases):
    """8 builds: build k gives HIGH ids bases[16k ...] and RECL ids a rotated slice, so every
    base appears once on a high id and once on a reclaimed one."""
    builds, n = [], len(bases)
    hi_chunks = [bases[i:i + len(HIGH)] for i in range(0, n, len(HIGH))]
    rc_chunks = [bases[i:i + len(RECL)] for i in range(0, n, len(RECL))]
    for k in range(max(len(hi_chunks), len(rc_chunks))):
        builds.append((hi_chunks[k] if k < len(hi_chunks) else [],
                       rc_chunks[k] if k < len(rc_chunks) else []))
    return builds


def census_build(rom_path, sym_path, pairs, banks, orig):
    rom = open(rom_path, 'rb').read()
    sym, by_bank = load_sym(sym_path)
    def vanilla(at):
        """the instruction at (bank, pc) is the original game's own bytes"""
        b, pc = at
        off = (b * 0x4000 + pc - 0x4000) if pc >= 0x4000 else pc
        return b < 0x80 and off + 3 <= len(orig) and rom[off:off + 3] == orig[off:off + 3]
    cpu = CPU(rom, vanilla=vanilla)
    sites = find_sites(rom, banks, sym)
    res = {}
    for bank, addr, var, how in sites:
        key = f"{bank:02X}:{addr:04X}"
        lab = label_of(by_bank, bank, addr)
        cache = {}

        def sig(i):
            if i not in cache:
                cache[i] = run_site(cpu, rom, bank, addr, i)
            return cache[i]
        diffs = []
        for new, base in pairs:
            (eb, sb, wb), (en, sn, wn) = sig(base), sig(new)
            # the ROOT: in the base run's order, the first branch of the ORIGINAL game's code
            # that both runs reach, that went another way, and that tested the id in one of
            # them (a record field read through a patch's fork is the same data for a twin:
            # same way, no root; a branch reached by one run only lies after a root)
            root = None
            for at, (ob, mb, _i) in sorted(eb.items(), key=lambda kv: kv[1][2]):
                if not vanilla(at) or at not in en:
                    continue
                on, mn, _j = en[at]
                if ob != on and (mb or mn):
                    root = (at, ob, on)
                    break
            if not root:
                # no branch parts them: do they print the same message numbers? (the
                # original game's own writes; the first one that differs)
                vb = [x for x in wb if vanilla(x[0])]
                vn = [x for x in wn if vanilla(x[0])]
                k = next((i for i, (x, y) in enumerate(zip(vb, vn)) if x != y), None)
                if k is not None:
                    at = vb[k][0]
                    diffs.append({'new': new, 'base': base, 'root': f"${at[0]:02X}:{at[1]:04X}",
                                  'kind': 'message',
                                  'base_way': f"[${vb[k][1]:04X}] := ${vb[k][2]:02X}",
                                  'new_way': f"[${vn[k][1]:04X}] := ${vn[k][2]:02X}",
                                  'stop_base': _fstop(sb), 'stop_new': _fstop(sn)})
                continue
            if root:
                at, ob, on = root
                diffs.append({'new': new, 'base': base, 'root': f"${at[0]:02X}:{at[1]:04X}",
                              'kind': 'branch', 'base_way': _ways(ob), 'new_way': _ways(on),
                              'stop_base': _fstop(sb), 'stop_new': _fstop(sn)})
        res[key] = {'bank': bank, 'addr': addr, 'var': VARS[var], 'how': how, 'label': lab,
                    # the AI's rule chain and its estimate run with the S161 view on ($DB8A =
                    # the base); bank $57 entry 1 ($7C44-$7C6D) is act-time (Entry1Base52)
                    'view': (bank == 0x57 and not 0x7C44 <= addr < 0x7C6E)
                    or lab.startswith(('EstimateView58', 'FxEstimate58', 'AIDamageEstimate_538f')),
                    'id_tested': any(sig(b)[0] for _n, b in pairs[:4]),
                    'diffs': diffs}
    return res


def _ways(o):
    return ', '.join(sorted((f"jp ${t[1]:02X}:{t[2]:04X}" if isinstance(t, tuple)
                             else ('taken' if t else 'not')) for t in o))


def _loc(x):
    (b, pc), _t = x
    return f"${b:02X}:{pc:04X}"


def _fmt(x):
    (b, pc), t = x
    if isinstance(t, tuple):
        return f"${b:02X}:{pc:04X} -> jp ${t[1]:02X}:{t[2]:04X}"
    return f"${b:02X}:{pc:04X} {'taken' if t else 'not'}"


def _fstop(s):
    kind, at, fl = s
    out = kind
    if at:
        out += f" ${at[0]:02X}:{at[1]:04X}"
    if fl:
        out += f" C={int(fl[0])} Z={int(fl[1])}"
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--reuse', help='a work dir with b0..b7 already built')
    ap.add_argument('--keep', help='build into this dir and keep it')
    ap.add_argument('--banks', default='00,4c,50,51,52,53,54,55,56,57,58,5f,72,77')
    args = ap.parse_args()
    from editor2.core import custom_skills as CS
    bases = [b for b, _n in CS.clone_bases(REPO, 0xEF)]
    builds = plan(bases)
    work = args.reuse or args.keep or tempfile.mkdtemp(prefix='act_ids_')
    banks = [int(x, 16) for x in args.banks.split(',')]
    merged = {}
    orig = open(os.path.join(REPO, 'data', 'DWM-original.gbc'), 'rb').read()
    for k, (bh, br) in enumerate(builds):
        d = os.path.join(work, f'b{k}')
        if not args.reuse:
            pj = project_for(bh, br, d)
            r = subprocess.run([sys.executable, os.path.join(REPO, 'tools', 'build_project.py'),
                                '--project', pj, '--out', d, '--build'],
                               capture_output=True, text=True)
            if r.returncode:
                print(r.stdout[-3000:], r.stderr[-3000:])
                sys.exit(f'build {k} failed')
        pairs = list(zip(HIGH, bh)) + list(zip(RECL, br))
        res = census_build(os.path.join(d, 'build', 'rom.gbc'),
                           os.path.join(d, 'build', 'game.sym'), pairs, banks, orig)
        for key, v in res.items():
            m = merged.setdefault(key, {kk: vv for kk, vv in v.items() if kk != 'diffs'})
            m.setdefault('diffs', []).extend(v['diffs'])
        print(f'build {k}: {len(pairs)} new skills, {len(res)} sites, '
              f'{sum(1 for v in res.values() if v["diffs"])} with a difference', flush=True)
    cand = {k: v for k, v in merged.items() if v['diffs']}
    new_roots = set()
    for k, v in cand.items():
        v['bases'] = sorted({d['base'] for d in v['diffs']})
        for d_ in v['diffs']:
            if v['view']:
                d_['verdict'] = 'AI rule chain: the S161 view gives $DB8A = the base there'
            else:
                d_['verdict'] = ROOT_VERDICTS.get(d_['root'], 'NEW - not judged yet')
                if d_['root'] not in ROOT_VERDICTS:
                    new_roots.add(d_['root'])
    out = {'_generator': 'tools/census_act_id_lists.py (S163) on census builds of '
                         'editor2/example-project + 30 new skills a build (data/DWM-original.gbc)',
           'bases': bases, 'builds': [{'high': list(zip(HIGH, bh)), 'reclaimed': list(zip(RECL, br))}
                                      for bh, br in builds],
           'n_sites': len(merged), 'new_roots': sorted(new_roots),
           'root_verdicts': ROOT_VERDICTS, 'candidates': cand,
           'sites_same': sorted(k for k, v in merged.items() if not v['diffs'])}
    json.dump(out, open(OUT, 'w'), indent=1)
    print(f'{len(merged)} sites, {len(cand)} where a new skill differs from its base; '
          f'roots outside the AI chain not judged: {len(new_roots)} {sorted(new_roots)} -> {OUT}')
    return 1 if new_roots else 0
    if not (args.reuse or args.keep):
        shutil.rmtree(work, ignore_errors=True)


if __name__ == '__main__':
    sys.exit(main())
