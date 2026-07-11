"""validators.py — build-time enforcement of the hard-won rules.

Every rule cites its source (KEY_LESSONS.md entry or owning reference doc).
The class of bug that cost the most sessions — wrong-size entries, missing
terminators, guessed screen bytes, table overshoots, bank overflow found at
runtime — becomes a build ERROR pointing at the offending project.json
field. Warnings surface risky-but-legal authoring.

Returns (errors, warnings): lists of strings. Errors abort the emit.
"""

from . import formats as F
from . import textenc as T
from . import scriptgen as S

# Bank capacity constants: template head sizes measured from the reference
# patched build's game.sym (S53; see PROJECT_COMPILER.md §bank-accounting).
# addr(first generated label) - $4000. Pinned by tools/build_project.py
# --pin-templates after a successful regression build; None = check skipped
# with a warning.
TEMPLATE_SIZE = {
    0x60: 283,   # addr(CustomScriptMasterTable)-$4000, S53 reference game.sym
    0x71: 116,    # addr(Custom26DDTable)-$4000, S55 (S53 head 103 + 13-byte flag-derivation fix)
}
BANK_SIZE = 0x4000


def _payload_bytes(asm_text):
    """Exact byte size of generated db/dw/ds lines (quote-aware)."""
    total = 0
    for raw in asm_text.splitlines():
        line = raw.strip()
        if line.startswith('db ') or line.startswith('dw '):
            kind = line[:2]
            body = line[3:]
            # strip trailing comment outside quotes
            toks, cur, inq = [], '', False
            for ch in body:
                if ch == '"':
                    inq = not inq
                    cur += ch
                elif ch == ';' and not inq:
                    break
                elif ch == ',' and not inq:
                    toks.append(cur.strip())
                    cur = ''
                else:
                    cur += ch
            if cur.strip():
                toks.append(cur.strip())
            for t in toks:
                if not t:
                    continue
                if t.startswith('"') and t.endswith('"'):
                    total += len(t) - 2          # charmap: 1 byte per char
                else:
                    total += 1 if kind == 'db' else 2
        elif line.startswith('ds '):
            arg = line[3:].split(';')[0].split(',')[0].strip()
            total += F.val(arg)
    return total


def validate(prj, generated=None):
    """generated=None → content checks (run BEFORE emit so schema errors
    are reported as validation, not emitter crashes); generated={target:
    text} → bank-accounting checks only (needs the emitted text)."""
    errors, warnings = [], []
    if generated is not None:
        _validate_accounting(prj, generated, errors, warnings)
        return errors, warnings
    warnings += list(prj.warnings)
    rooms = [r for r in prj.rooms if not r.get('placeholder')]

    # ------------------------------------------------------------- master
    # KEY_LESSONS S53 finding: CustomScriptRead indexes the master table by
    # (wScriptMapType-$6B) on the bank-$06 scroll path (raw wMapID). A table
    # narrower than the room count overshoots for high rooms when they
    # scroll. Default = full width; compat list reproduces the legacy
    # 3-entry layout for byte-identity and is flagged.
    compat = (prj.build.get('compat') or {}).get('master_table_rooms')
    if compat:
        cov = {F.val(m) for m in compat}
        exposed = [F.hexb(F.val(r['mapID'])) for r in prj.rooms
                   if F.val(r['mapID']) not in cov]
        if exposed:
            warnings.append(
                "build.compat.master_table_rooms reproduces the LEGACY "
                f"narrow master table; rooms {', '.join(exposed)} overshoot "
                "it if they ever scroll (single-screen rooms cannot scroll, "
                "which is the only reason the legacy layout is benign — "
                "KEY_LESSONS S53). Remove the compat key to emit the fixed "
                "full-width table.")
        order = [F.val(m) for m in compat]
        if order != sorted(order) or order[0] != 0x6B or \
                order != list(range(0x6B, 0x6B + len(order))):
            errors.append(
                "build.compat.master_table_rooms must be dense ascending "
                "from $6B (the table is indexed wScriptMapType-$6B)")

    # ------------------------------------------------- per-room structure
    for r in rooms:
        rid = r.get('id', F.hexb(F.val(r['mapID'])))
        mid = F.val(r['mapID'])
        screens = prj.room_screens(r)
        if not screens:
            errors.append(f"room {rid}: no screens")
            continue

        # scripts: index 0 reserved for room entry (KEY_LESSONS S2 "Script
        # index 0 = room entry script"); NPC ids reference 1+.
        table = dict(prj.room_script_table(r))
        if table and 0 not in table:
            errors.append(f"room {rid}: script table has entries but no "
                          "index 0 (room-entry) — index 0 is RESERVED and "
                          "runs on every scroll/reload (KEY_LESSONS S2)")
        for idx, sid in table.items():
            try:
                prj.script(sid)
            except Exception as e:
                errors.append(f"room {rid}: script[{idx}]: {e}")

        # $26DD record: required for mapID >= $70 (bank $71 far table lifts
        # the ceiling — PROJECT_STATE keystone S42); ignored below $70
        # (those read the in-ROM0 table by raw mapID).
        if mid >= 0x70 and not r.get('record'):
            errors.append(f"room {rid}: mapID {F.hexb(mid)} >= $70 requires "
                          "a 'record' (Custom26DDTable row — bank $71 "
                          "supplies tileset/dims/threshold past the $6F "
                          "ceiling)")
        if mid < 0x70 and r.get('record'):
            warnings.append(f"room {rid}: 'record' ignored for mapID < $70 "
                            "(in-ROM0 $26DD table is used; see "
                            "PROJECT_COMPILER.md §records)")
        rec = r.get('record')
        if rec:
            w, h = F.val(rec['width_px']), F.val(rec['height_px'])
            if w % 160 or h % 128:
                errors.append(f"room {rid}: record dims {w}x{h} not multiples"
                              " of 160x128 (ROOM_DATA_FORMAT: width=cols*160,"
                              " height=rows*128; KEY_LESSONS S10 movement "
                              "clamp)")
            cols, rows_n = w // 160, h // 128
            top = max(screens)
            if top >= 4 and rows_n < 2:
                errors.append(f"room {rid}: screen index {top} implies 2 "
                              "rows but record height is 1 row "
                              "(KEY_LESSONS S10: dimensions gate scrolling)")

        single_width = True
        if rec:
            single_width = F.val(rec['width_px']) <= 160

        for i, s in screens.items():
            if not (0 <= i <= 7):
                errors.append(f"room {rid} screen {i}: index outside the "
                              "4x2 grid (ROOM_DATA_FORMAT)")
            lay = s.get('layout')
            if not lay:
                errors.append(f"room {rid} screen {i}: missing layout")
            spawn_seen = False
            for n in s.get('npcs', []):
                x, y = n.get('x'), n.get('y')
                if not (0 <= x <= 9 and 0 <= y <= 7):
                    errors.append(f"room {rid} screen {i}: NPC/spawn at "
                                  f"({x},{y}) outside 10x8 walk grid "
                                  "(ROOM_DATA_FORMAT scroll/walk grid)")
                if n['kind'] == 'spawn':
                    spawn_seen = True
                    if F.val(n.get('script', 0)) != 0:
                        errors.append(
                            f"room {rid} screen {i}: spawn entry script must "
                            "be 0 — the interaction scan includes spawn "
                            "entries; nonzero makes a 'ghost NPC' "
                            "(KEY_LESSONS 'Spawn point NPC entry can be "
                            "talked to')")
                else:
                    sid = n.get('script')
                    if sid not in (None, 'none'):
                        try:
                            si = prj.script_index(r, sid)
                            if si == 0:
                                errors.append(
                                    f"room {rid} screen {i}: NPC references "
                                    "script index 0 — reserved for room "
                                    "entry (KEY_LESSONS S2)")
                        except Exception as e:
                            errors.append(f"room {rid} screen {i}: {e}")
                    if n.get('facing') and n['facing'] not in F.FACING:
                        errors.append(f"room {rid} screen {i}: unknown "
                                      f"facing {n['facing']!r}")
            if not spawn_seen and i == min(screens):
                warnings.append(f"room {rid} screen {i}: no spawn entry — "
                                "entering from an exit still works (source "
                                "exit supplies coords, KEY_LESSONS S4) but "
                                "teleports need one")
            for e in s.get('exits', []):
                if 'screen_byte' not in e:
                    errors.append(
                        f"room {rid} screen {i}: exit ({e.get('x')},"
                        f"{e.get('y')}) has no screen_byte — NEVER guessed; "
                        "copy from an existing exit to the same destination "
                        "(KEY_LESSONS v14-v18 + S40 off-map spawn)")
                    continue
                sb = F.val(e['screen_byte'])
                dest = e.get('dest')
                try:
                    dmid = prj.resolve_dest(dest)
                except Exception as ex:
                    errors.append(f"room {rid} screen {i}: exit dest "
                                  f"{dest!r}: {ex}")
                    continue
                if isinstance(dest, str) and dest.startswith('room:'):
                    dr = prj.room_by_mid(dmid)
                    drec = dr.get('record')
                    d_single = (not drec) or F.val(drec['width_px']) <= 160
                    if d_single and (sb & 0x0F) != 0:
                        warnings.append(
                            f"room {rid} screen {i}: exit to "
                            f"{F.hexb(dmid)} has screen_byte "
                            f"{F.hexb(sb)} but the destination is "
                            "single-width — low nibble should be $00 or the "
                            "player spawns off-map (KEY_LESSONS S40)")
                ty = F.val(e.get('y'))
                if ty in (0, 7):
                    warnings.append(
                        f"room {rid} screen {i}: exit at trigger_y={ty} is a "
                        "BOUNDARY exit (Entry 9 path, walk-into-edge); it "
                        "cannot coexist with a scroll transition on that "
                        "edge (KEY_LESSONS S10 Entry 6 vs Entry 9)")

    # ------------------------------------------------------------ dialogue
    for e in prj._dialogue:
        tid = e['_tid']
        try:
            if not T.entry_terminator_ok(e):
                errors.append(
                    f"text {F.hexw(tid)} ({e.get('id','')}): must end "
                    "$F7 $F0 (plain) or $E7 $F0 (choice) — $E7 is CHOICE, "
                    "not END (KEY_LESSONS S2 / TEXT_SYSTEM)")
            stream = T.entry_stream(e)
            flat = []
            for kind, v in stream:
                flat += (v if kind == 'ctl' else [None] * len(v))
            for j, b in enumerate(flat):
                if b == 0xEE and (j == 0 or flat[j - 1] != 0xEF):
                    errors.append(
                        f"text {F.hexw(tid)}: bare $EE newline — must be "
                        "$EF $EE (KEY_LESSONS S2 '$EE needs $EF before it')")
        except T.TextError as ex:
            errors.append(f"text {F.hexw(tid)} ({e.get('id','')}): {ex}")

    # ------------------------------------------------------------- scripts
    sw = []
    for sid, sc in prj._scripts.items():
        try:
            S.emit_script(f"chk_{sid}", sc['ops'],
                          warnings=sw)
        except S.ScriptError as ex:
            errors.append(str(ex))
    warnings += sw

    # ----------------------------------------------------------- palettes
    for pal in prj.palettes:
        rows = pal.get('colors_rgb555')
        if not rows or len(rows) != 8 or any(len(x) != 4 for x in rows):
            errors.append(f"palette {pal.get('id')}: needs exactly 8 "
                          "sub-palettes x 4 colours (GATE_GENERATION §7.1; "
                          "the S6 regex bug that dropped line 8 broke dialog "
                          "rendering — KEY_LESSONS 'Palette regex must write "
                          "exactly 8 db lines')")
            continue
        bad_rows = [ri for ri, row in enumerate(rows)
                    if F.val(row[1]) != 0x6BFF or F.val(row[3]) != 0x0000]
        if bad_rows:
            warnings.append(
                f"palette {pal.get('id')} rows {bad_rows}: idx1 != $6BFF or "
                "idx3 != $0000 — engine FORCES those two colours at runtime; "
                "authored values there will not display (KEY_LESSONS S7/S39)")
        if not pal.get('label'):
            errors.append(f"palette {pal.get('id')}: missing 'label'")

    return errors, warnings


def _validate_accounting(prj, generated, errors, warnings):
    # EDITOR_DESIGN §6: bank overflow must fail BEFORE rgbasm runs (rgbasm
    # reports only the first excess byte — KEY_LESSONS S52 #3).
    if True:
        for bank, fname in ((0x60, 'patches/bank_060.asm'),
                            (0x71, 'patches/bank_071.asm')):
            text = generated.get(f"file:{fname}")
            if text is None:
                continue
            tmpl = TEMPLATE_SIZE.get(bank)
            gen_bytes = _payload_bytes(
                text.split('SCRIPT DATA (generated', 1)[-1]
                if bank == 0x60 else
                text.split('Custom26DDTable —', 1)[-1])
            if tmpl is None:
                warnings.append(
                    f"bank ${bank:02X}: template size not pinned yet — "
                    "pre-build overflow check limited to generated payload "
                    f"({gen_bytes} bytes); run build_project.py "
                    "--pin-templates after the first successful build")
                if gen_bytes > BANK_SIZE:
                    errors.append(f"bank ${bank:02X}: generated payload "
                                  f"alone ({gen_bytes}) exceeds bank size")
            else:
                total = tmpl + gen_bytes
                if total > BANK_SIZE:
                    errors.append(
                        f"bank ${bank:02X} OVERFLOW: template {tmpl} + "
                        f"generated {gen_bytes} = {total} > {BANK_SIZE} "
                        "bytes — trim content (rgbasm would only report the "
                        "first excess byte; KEY_LESSONS S52)")
                elif total > BANK_SIZE - 256:
                    warnings.append(
                        f"bank ${bank:02X}: {BANK_SIZE - total} bytes free "
                        "(under 256) — nearly full")

