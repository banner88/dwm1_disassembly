#!/usr/bin/env python3
"""census_room_states.py — kept room states of game-room copies (S144, ROADMAP ARC CAP4c).

Every game room is copied twice into a scratch project made from the blank template:
EVERY state (following the game, S118c — the reference) and with the editor's
DEFAULT keep spec (`editor2/core/room_states.default_spec`: the story point after
Starry Night, or "about to do its gate" for a gate's boss floor; the states the
room's own scripts can reach from there). Checks, per kept state:

  picture  the kept copy's screen in its NEW state number renders exactly the
           reference copy's screen in the ORIGINAL state (tiles, attributes,
           palettes — the editor's renderer, `ProjectRenderer.render_screen`);
  people   the NPC / spot entries are the same bytes (script indices included —
           the room's script table is positional, dropped middle entries stub);
  scripts  every script index a kept entry or the entry script names exists;
           no script still names a counter state that is gone (a test or write
           of a number >= the screen's state count);
  build    (--build) the kept project compiles and links (4 MB ROM).

Prints one row per room (states kept per screen, script bytes before → after,
story-flag tests answered, remembered states) and the totals; exit 1 on any
mismatch.

  python3 tools/census_room_states.py [--build] [--rooms 0x01,0x31] [--keep DIR]
  python3 tools/census_room_states.py --negative   # flatten without carrying the
                                                   # attr up: the picture check must fail
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))
sys.path.insert(0, ROOT)

from editor2.core.document import Document                  # noqa: E402
from editor2.core.render_project import ProjectRenderer     # noqa: E402
from editor2.core import room_states as RS                  # noqa: E402
from editor2.core import place_names as PN                  # noqa: E402
from editor2.core.formats import val                        # noqa: E402

BLANK = os.path.join(ROOT, 'editor2', 'templates', 'blank-project')


def scratch(where, name):
    d = os.path.join(where, name)
    os.makedirs(os.path.join(d, 'assets'), exist_ok=True)
    shutil.copy(os.path.join(BLANK, 'project.json'), os.path.join(d, 'project.json'))
    return d


def entries(room, k, i):
    scr = room['screens'][k]
    sts = scr.get('states')
    st = sts[i] if sts else scr
    return [tuple(val(b) for b in e['bytes']) if e.get('kind') == 'raw' else
            ('npc', e.get('x'), e.get('y'), str(e.get('script')))
            for e in st.get('npcs') or []]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--build', action='store_true')
    ap.add_argument('--rooms')
    ap.add_argument('--keep', help='leave the scratch projects in this folder')
    ap.add_argument('--negative', action='store_true')
    a = ap.parse_args()
    if a.negative:
        orig = RS._flatten_into

        def bad(doc, scr, st):
            st = dict(st)
            st.pop('attr', None)
            scr.pop('states', None)
            for key in ('layout', 'palette'):
                if key in st:
                    scr[key] = st[key]
            scr['npcs'] = st.get('npcs', [])
            scr['exits'] = st.get('exits', [])
        RS._flatten_into = bad
    where = a.keep or tempfile.mkdtemp(prefix='s144_states_')
    os.makedirs(where, exist_ok=True)
    pa, pb = scratch(where, 'every_state'), scratch(where, 'kept')
    da, db = Document(pa), Document(pb)
    ra = ProjectRenderer(ROOT, da.project_dir, da.data)
    rb = ProjectRenderer(ROOT, db.project_dir, db.data)
    ra.vanilla_rooms()
    mids = sorted(ra._vanilla_mt)
    if a.rooms:
        mids = [int(x, 16) for x in a.rooms.split(',')]
    bad = 0
    tot_b = tot_a = 0
    rows = []
    for mid in mids:
        name = PN.vanilla_name(mid)
        ida = da.clone_vanilla(mid, name, ROOT, ra)
        idb = db.clone_vanilla(mid, name, ROOT, rb, keep='default')
        rep = db.last_states_report
        A, B = da.room(ida), db.room(idb)
        spec_note = []
        errs = []
        ra.invalidate()
        rb.invalidate()
        spec = RS.default_spec(da, A, RS.default_point(mid))
        for k in sorted(A['screens'], key=int):
            s = spec['screens'][k]
            if s.get('follow'):
                spec_note.append(f's{k}:follow')
                continue
            order = [s['start']] + [i for i in s['keep'] if i != s['start']]
            n_a = RS.n_states(A['screens'][k])
            if n_a > 1:
                spec_note.append(f"s{k}:{'+'.join(map(str, order))}/{n_a}")
            for new, old in enumerate(order):
                ia = ra.render_screen(A, k, old).tobytes()
                ib = rb.render_screen(B, k, new).tobytes()
                if ia != ib:
                    errs.append(f'picture s{k} state {old}->{new}')
                if entries(A, k, old) != entries(B, k, new):
                    errs.append(f'people s{k} state {old}->{new}')
        table = {int(i): sid for i, sid in (B.get('scripts') or {}).items()}
        by_id = {s['id']: s for s in db.custom['scripts']}
        # the game's own gaps (an NPC naming a script its map type lacks — the
        # unused Castle copies, the glitched Copycat House) are not ours
        ref_ok = {int(i) for i, sid in (A.get('scripts') or {}).items()
                  if sid in {s['id'] for s in da.custom['scripts']}}
        for k in B['screens']:
            for i in range(RS.n_states(B['screens'][k])):
                for e in B['screens'][k].get('states', [B['screens'][k]])[i].get('npcs') or []:
                    b = [val(x) for x in e['bytes']]
                    if b[4] != 0xFF and b[4] in ref_ok and \
                            (b[4] not in table or table[b[4]] not in by_id):
                        errs.append(f'script {b[4]} missing (s{k} state {i})')
        labels = {}
        for k, scr in B['screens'].items():
            sc = scr.get('step_counter')
            if isinstance(sc, dict) and sc.get('label') and 'vanilla' not in sc:
                labels[sc['label']] = RS.n_states(scr)
        for sid in set(table.values()):
            for it in (by_id.get(sid) or {}).get('ops') or []:
                if isinstance(it, list) and it and it[0] == 'op' and len(it) > 3 and \
                        it[2] in labels and RS.op_name(it) in ('write_ram', 'check_and_branch'):
                    if val(it[3]) >= labels[it[2]]:
                        errs.append(f'{sid}: {RS.op_name(it)} {it[2]} := {val(it[3])}')
        tot_b += rep['scripts_before']
        tot_a += rep['scripts_after']
        bad += bool(errs)
        rows.append(f"${mid:02X} {name[:30]:30s} {' '.join(spec_note) or '-':34s} "
                    f"{rep['scripts_before']:5d}→{rep['scripts_after']:5d} B  talk {rep['talk']:3d}  "
                    f"kept-by-flag {len(rep['flags'])}  point: {RS.point_label(spec['point'])}"
                    + (f"  ERR {errs[:4]}" if errs else ''))
    print('\n'.join(rows))
    print(f'\nrooms {len(mids)}, mismatched {bad}; scripts {tot_b:,} → {tot_a:,} bytes')
    da.save()
    db.save()
    if a.build:
        r = subprocess.run([sys.executable, os.path.join(ROOT, 'tools', 'build_project.py'),
                            '--project', pb, '--build'], capture_output=True, text=True)
        tail = (r.stdout + r.stderr).strip().splitlines()[-3:]
        print('build:', 'OK' if r.returncode == 0 else 'FAILED', '|', ' | '.join(tail))
        bad += r.returncode != 0
    if not a.keep:
        shutil.rmtree(where, ignore_errors=True)
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
