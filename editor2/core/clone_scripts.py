"""clone_scripts.py — repair copies made by the S92-S147 copy extractor (S148, no Qt).

ROADMAP ARC CAP4 "$3E" box (S148): `tools/extract_room.py` (Make editable / a
copy of a game room) stopped decoding a script at op `$16` — the legacy
decompiler called it "return"; its handler (`ScriptCmd16_RefreshSprites`, bank
$04) redraws OAM + the BG map address and YIELDS (`ret`), and the game CONTINUES
the script next frame. The copy laid the decoded ops out in address order, so it
fell from the `$16` straight into whichever decoded block came next by address:

  * the Castle's script 0: 3 sites, 186 words lost (the King's post-game arrival
    "It's you [HERO]!", "How was it?", the Starry Night gift) — after `$4522` the
    copy ran `$46EE`;
  * the Starry Shrine's script 0: the END after 2 `$16`s (the hatch and "Anything
    else?" paths fell into the next block);
  * the Priest gate floor's scripts 1 / 2: `restore_bgm` + END after "HEAL!!!".

`repair(doc)` (Document._migrate_refresh_sprites, user S148: "replace") finds every
copied script of the project (a room with a `source_mapID` < $6B, its positional
script table) whose game script the old extractor got wrong, and at each broken
`$16` inserts the missing run (the fixed extractor's items) — only where the
copy still has the broken shape (the item after the `$16` is the old
extractor's next item). A site that no longer has that shape (the script was
edited) is left alone and reported (`warnings`). The inserted steps are the
game's own: a vanilla step counter they name becomes the copy's counter label
when that screen still follows the game (`step_counter.vanilla`, as the copy
step did); their tile patches are lowered by `_migrate_clone_patches` after
this; tests of story flags in them are not folded to a kept story point
(ARC CAP4c) — the Cutscenes tab shows them.
"""

import copy
import importlib.util
import os

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

_ER = {}
_PLAN = {}


def _extractor(repo=REPO):
    if repo not in _ER:
        path = os.path.join(repo, 'tools', 'extract_room.py')
        spec = importlib.util.spec_from_file_location('_extract_room_s148', path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        _ER[repo] = (mod, mod._load_param_counts())
    return _ER[repo]


def _items(rom, src, idx, legacy, repo=REPO):
    from . import cutscenes as CS
    er, (pc, bt, nb) = _extractor(repo)
    bank = CS.script_bank(src)
    ptrs = CS.vanilla_script_ptrs(rom, src)
    if idx >= len(ptrs):
        return None, None
    ordered = er.decode_script(rom, bank, ptrs[idx], pc, bt, set(), legacy_stop16=legacy)
    addrs = []
    items = er.ops_to_project(ordered, bt, nb, addrs)
    return items, addrs


def _code(it):
    """An item's opcode (op items), 'end' / 'text' / 'label' otherwise."""
    if isinstance(it, str):
        return 'label'
    if not isinstance(it, list) or not it:
        return None
    if it[0] in ('end', 'text'):
        return it[0]
    if it[0] != 'op':
        return None
    from . import scriptgen as SG
    from . import script_ops as SO
    nm = it[1]
    if isinstance(nm, str):
        if nm in SG.OPS:
            return SG.OPS[nm][0]
        for c, o in SO.OPS.items():
            if o.name == nm:
                return c
        try:
            return int(nm, 16) if nm.lower().startswith(('0x', '$')) else None
        except ValueError:
            return None
    return nm if isinstance(nm, int) else None


def broken_sites(rom, src, idx, repo=REPO):
    """The broken `$16` sites of the game's script (map src, index idx) in a copy
    made by the old extractor: [(n, run, old_next, old_prev)] — n = which `$16` of
    the script (0-based, in item order), run = the missing items, old_next /
    old_prev = the items the old copy has right after / before that `$16`. [] when
    the old copy was right."""
    key = (repo, src, idx)
    if key in _PLAN:
        return _PLAN[key]
    old, old_a = _items(rom, src, idx, True, repo)
    new, new_a = _items(rom, src, idx, False, repo)
    out = []
    if old is None or old == new:
        _PLAN[key] = out
        return out
    old_set = set(old_a)
    n16 = 0
    for i, it in enumerate(old):
        if _code(it) != 0x16:
            continue
        a = old_a[i]
        j = i + 1
        while j < len(old) and _code(old[j]) == 'label':
            j += 1
        nxt = old[j] if j < len(old) else None
        if j < len(old) and old_a[j] == a + 2:
            n16 += 1
            continue
        # the fixed copy: the items from a + 2 up to the next item the old copy had
        k = next(x for x in range(len(new)) if new_a[x] == a and _code(new[x]) == 0x16)
        run = []
        for x in range(k + 1, len(new)):
            if new_a[x] in old_set:
                break
            run.append(new[x])
        p = i - 1
        while p >= 0 and _code(old[p]) == 'label':
            p -= 1
        out.append((n16, run, nxt, old[p] if p >= 0 else None))
        n16 += 1
    _PLAN[key] = out
    return out


def _same(a, b):
    """The old copy's item vs the project's (counters / flags may be renamed by
    later steps: compare the kind / opcode and the parameter count)."""
    ca, cb = _code(a), _code(b)
    if ca != cb:
        return False
    if ca in ('end', 'label', None):
        return True
    return len(a) == len(b)


def _norm(items):
    """Items as words (names and spellings do not matter; label refs do)."""
    from . import cutscenes as CS
    try:
        words, labels = CS.project_words(items)
    except Exception:                                    # noqa: BLE001
        return None
    return [w if not isinstance(w, tuple) else ('L', labels.get(w[1])) for w in words]


def _contains(ops, run, n=4):
    """The run's first n steps (labels skipped) appear in a row somewhere in ops."""
    want = [it for it in run if _code(it) != 'label'][:n]
    have = [it for it in ops if _code(it) != 'label']
    if len(want) < 2:                   # a lone END says nothing
        return False
    for i in range(len(have) - len(want) + 1):
        if all(_same(w, h) for w, h in zip(want, have[i:i + len(want)])):
            return True
    return False


def _steps(items):
    return sum(1 for it in items if isinstance(it, list))


def _rewire(items, lab):
    """A game step counter a copied step names -> the copy's counter label (the
    copy step's rule, `Document.clone_vanilla`)."""
    from .formats import val
    for it in items:
        if isinstance(it, list) and it[0] == 'op' and len(it) >= 3 and \
                _code(it) in (0x12, 0x13, 0x15):
            try:
                a = val(it[2])
            except Exception:                            # noqa: BLE001
                continue
            if a in lab:
                it[2] = lab[a]
    return items


_DIFF = {}


def _differs(rom, src, idx, repo=REPO):
    """The old copy tool's items != the fixed tool's for this game script (a `$16`
    site, or words after a room change: the Starry Shrine's last script)."""
    key = (repo, src, idx)
    if key not in _DIFF:
        try:
            a, _x = _items(rom, src, idx, True, repo)
            b, _y = _items(rom, src, idx, False, repo)
            _DIFF[key] = a != b
        except Exception:                                # noqa: BLE001
            _DIFF[key] = False
    return _DIFF[key]


def repair(doc, rom=None, repo=REPO):
    """Insert the missing runs into the project's copies (module doc). Returns
    (notes, warnings) — sentences for the open log."""
    from .formats import val
    from . import scriptgen as SG
    notes, warnings = [], []
    if rom is None:
        rom = doc._rom_bytes()
    if not rom:
        return notes, warnings
    by_id = {sc.get('id'): sc for sc in doc.custom.get('scripts', [])}
    for r in doc.custom.get('rooms', []):
        if r.get('placeholder') or r.get('source_mapID') is None:
            continue
        try:
            src = val(r.get('source_mapID'))
        except Exception:                                # noqa: BLE001
            continue
        if not isinstance(src, int) or not 0 <= src < 0x6B:
            continue
        # the copy step's counter labels: a vanilla counter address -> the label
        lab = {}
        for scr in (r.get('screens') or {}).values():
            sc_ = scr.get('step_counter') if isinstance(scr, dict) else None
            if isinstance(sc_, dict) and sc_.get('vanilla') is not None and sc_.get('label'):
                try:
                    lab[val(sc_['vanilla'])] = sc_['label']
                except Exception:                        # noqa: BLE001
                    pass
        name = r.get('name') or r.get('id')
        for k, sid in sorted((r.get('scripts') or {}).items(), key=lambda t: int(t[0])):
            sc = by_id.get(sid)
            if not isinstance(sc, dict) or not isinstance(sc.get('ops'), list):
                continue
            plan = broken_sites(rom, src, int(k), repo)
            if not plan and not _differs(rom, src, int(k), repo):
                continue
            old_items, _a = _items(rom, src, int(k), True, repo)
            if old_items is None:
                continue
            ops = sc['ops']
            if _norm(ops) == _norm(old_items):
                # untouched since the copy (no counter / flag rewrites): the fixed copy
                new_items, _b = _items(rom, src, int(k), False, repo)
                new_items = _rewire(copy.deepcopy(new_items), lab)
                sc['ops'] = SG.regroup_ops(new_items)[0]
                notes.append(f'room {name} (a copy of the game\'s map ${src:02X}): script {sid} '
                             f'copied again with the S148 copy tool ({_steps(old_items)} → '
                             f'{_steps(sc["ops"])} steps: op $16 continues, the words after '
                             f'a room change are not copied)')
                continue
            if not plan:
                # words after a room change the old tool copied (never run): drop
                # them up to the next label, keep one END
                from . import script_ops as SO
                out, i, cut = [], 0, 0
                while i < len(ops):
                    it = ops[i]
                    out.append(it)
                    i += 1
                    if _code(it) in SO.TERMINAL:
                        j = i
                        while j < len(ops) and _code(ops[j]) != 'label':
                            j += 1
                        if ops[i:j] != [['end']]:
                            cut += _steps(ops[i:j]) - 1
                            out.append(['end'])
                            i = j
                if cut > 0:
                    sc['ops'] = out
                    notes.append(f'room {name} (a copy of the game\'s map ${src:02X}): script '
                                 f'{sid}: {cut} word(s) after a room change dropped (the S92-'
                                 f'S147 copy tool read the next map\'s table as steps; never run)')
                continue
            todo, bad = [], []
            used = set()
            for _n, run, old_next, old_prev in plan:
                # the site in the project's copy: a `$16` between the old copy's
                # neighbours (a later step may have pruned it — ARC CAP4c keeps only
                # what the kept states reach: then nothing can fall through there)
                first = next((it for it in run if _code(it) != 'label'), None)
                cands, done, seen = [], False, False
                for i, it in enumerate(ops):
                    if _code(it) != 0x16 or i in used:
                        continue
                    j = i + 1
                    while j < len(ops) and _code(ops[j]) == 'label':
                        j += 1
                    q = i - 1
                    while q >= 0 and _code(ops[q]) == 'label':
                        q -= 1
                    have = ops[j] if j < len(ops) else None
                    prev = ops[q] if q >= 0 else None
                    if not (old_prev is None or (prev is not None and _same(old_prev, prev))):
                        continue
                    seen = True
                    if have is not None and old_next is not None and _same(old_next, have):
                        cands.append(i)
                    elif have is not None and first is not None and _same(first, have):
                        done = True                     # repaired already
                if done and not cands:
                    continue
                if not cands and _contains(ops, run):
                    continue                            # the steps are there (edited after)
                if len(cands) == 1:
                    used.add(cands[0])
                    todo.append((cands[0], run))
                elif cands or seen:
                    # several such sites, or the step after this one was edited
                    bad.append(_n)
            if bad:
                warnings.append(
                    f'room {name} (a copy of the game\'s map ${src:02X}): its script {sid} '
                    f'lost steps after a "refresh sprites" step when it was copied '
                    f'(S92-S147 copy tool) and has been edited there since, so it was NOT '
                    f'repaired — make the copy again (Make editable) or compare it with '
                    f'the game\'s script in the Cutscenes tab')
                continue
            if not todo:
                continue
            labels = {it[6:] for it in ops if isinstance(it, str) and it.startswith('label:')}
            steps = 0
            for i, run in sorted(todo, reverse=True):
                ins = _rewire(copy.deepcopy(run), lab)
                labels |= {it[6:] for it in ins if isinstance(it, str) and it.startswith('label:')}
                steps += _steps(ins)
                ops[i + 1:i + 1] = ins
            sc['ops'] = ops = SG.regroup_ops(ops)[0]
            refs = {p[1:] for it in ops if isinstance(it, list) and it and it[0] == 'op'
                    for p in it[2:] if isinstance(p, str) and p.startswith('@')}
            missing = refs - labels
            if missing:                                   # cannot happen for the game's
                warnings.append(f'room {name}: script {sid} repaired but labels '
                                f'{sorted(missing)} are missing — check it')
            notes.append(f'room {name} (a copy of the game\'s map ${src:02X}): script {sid} '
                         f'got back {steps} step(s) the S92-S147 copy tool dropped after '
                         f'"refresh sprites" (op $16 continues — S148); the copy now plays '
                         f'like the game')
    return notes, warnings
