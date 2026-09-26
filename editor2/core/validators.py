"""validators.py — build-time enforcement of the hard-won rules.

Every rule cites its source (KEY_LESSONS.md entry or owning reference doc).
The class of bug that cost the most sessions — wrong-size entries, missing
terminators, guessed screen bytes, table overshoots, bank overflow found at
runtime — becomes a build ERROR pointing at the offending project.json
field. Warnings surface risky-but-legal authoring.

Returns (errors, warnings): lists of strings. Errors abort the emit.
"""

import os

from . import formats as F
from . import textenc as T
from . import scriptgen as S

# Bank capacity constants: template head sizes measured from the reference
# patched build's game.sym (S53; see PROJECT_COMPILER.md §bank-accounting).
# addr(first generated label) - $4000. Pinned by tools/build_project.py
# --pin-templates after a successful regression build; None = check skipped
# with a warning.
TEMPLATE_SIZE = {
    0x60: 492,   # addr(CustomScriptMasterTable)-$4000 — S97 reference game.sym (383 S94b -> 492 S97: entry-8 dw + CustomStateRules + the CustomReadStep call)
                 # (283 S53 -> 348 S70 -> 358 S70v3 (+2x5B wCustomY7Cmp arming): entry-7 dw + VanillaExitResolve +
                 # factored CopyExitListToBuffer in the template head; 383 S94: VanillaExitResolve rows keyed
                 # by (mapID, screen) — `db mapID, screen` with $FF = any screen)
    0x71: 142,    # addr(Custom26DDTable)-$4000, S64 (S55 116 + entry-2 dw + CustomRoomBGMResolve; measured from the S64 reference game.sym)
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

    # ------------------------------------------------------------- music
    # M3b (S64): resolve custom.music up front so schema/reference errors
    # surface as validation. Capacity: fixed 95-slot record area (ids
    # $9E-$FC) + streams $4180-$7FFF (song_codec constants; SOUND_SYSTEM §8).
    if prj.custom.get('music') or any(r.get('music') for r in prj.rooms):
        try:
            lib, room_bgm, ids, mw = prj.music_resolved()
        except Exception as e:
            errors.append(f"custom.music: {e}")
        else:
            warnings += [w for w in mw if w not in warnings]
            from . import music as M
            repo = M._repo_root(getattr(prj, 'repo_root', None) or prj.root)
            sc = M.song_codec(repo)
            total = 0
            for song in lib['songs']:
                for c in song['channels']:
                    total += len(sc.emit_tokens(c['header'], c['tokens']))
            cap = 0x8000 - sc.SONG_BANK_STREAMS_AT
            if total > cap:
                errors.append(
                    f"custom.music: {total} stream bytes exceed bank $74 "
                    f"capacity ({cap}) — the libraries are a catalog; only "
                    "assign what fits (or a second song bank is a future "
                    "AudioMasterTableExt row)")

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
            errors.append(
                "build.compat.master_table_rooms reproduces the LEGACY "
                f"narrow master table but rooms {', '.join(exposed)} are not "
                "covered — since S70 the bank $01 initial-entry revert routes "
                "EVERY custom room's FIRST ENTRY through CustomScriptRead, so "
                "an uncovered room overshoots the table at entry (not merely "
                "on scroll as pre-S70). Remove the compat key (full-width "
                "table) or cover every room.")
        else:
            warnings.append(
                "build.compat.master_table_rooms covers all rooms — the "
                "compat table is then byte-identical to the default "
                "full-width table; the key is legacy-only (S70)")
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

        # S97 state rules (ROADMAP P3.5a): resolvable flags, states that
        # exist, and a warning for flags outside the save image.
        if r.get('state_rules') and not r.get('placeholder'):
            try:
                resolved = prj.state_rules(r)
            except Exception as e:
                errors.append(str(e))
                resolved = []
            from .project import FLAG_PERSIST_LIMIT
            seen = set()
            for k, lst in resolved:
                for st, terms in lst:
                    for idx, _clr in terms:
                        if idx >= FLAG_PERSIST_LIMIT and idx not in seen:
                            seen.add(idx)
                            warnings.append(
                                f"room {rid}: state rule tests flag "
                                f"{F.hexw(idx)} — $0278+ is not in the save "
                                "image, so the state resets on reload "
                                "(EVENT_FLAGS.md)")

        # $26DD record: required for EVERY non-placeholder room (S94 — rows
        # $6B-$6F are the compiler-owned ROM0 region, $70+ the bank $71
        # Custom26DDTable; PROJECT_STATE keystone S42 + S94).
        if not r.get('record'):
            errors.append(f"room {rid}: mapID {F.hexb(mid)} requires a "
                          "'record' (tileset/dims/collision threshold — "
                          "ROM0 rows $6B-$6F or Custom26DDTable $70+)")
        rec = r.get('record')
        if rec:
            w, h = F.val(rec['width_px']), F.val(rec['height_px'])
            if w % 160 or h % 128:
                errors.append(f"room {rid}: record dims {w}x{h} not multiples"
                              " of 160x128 (ROOM_DATA_FORMAT: width=cols*160,"
                              " height=rows*128; KEY_LESSONS S10 movement "
                              "clamp)")
            cols, rows_n = w // 160, h // 128
            need_rows = max(i // 4 for i in screens) + 1
            need_cols = max(i % 4 for i in screens) + 1
            if rows_n < need_rows or cols < need_cols:
                # S96: a WARNING, not an error — vanilla rooms do this on
                # purpose (Labyrinth $42, the Forest Mazes $53/$61-$63: record
                # 1x1, extra screens entered only through an exit's
                # screen_byte, like the GreatTree floors — KEY_LESSONS S92).
                # A screen outside the record cannot be SCROLLED to.
                outside = sorted(i for i in screens
                                 if i // 4 >= rows_n or i % 4 >= cols)
                warnings.append(
                    f"room {rid}: screens {outside} lie outside the record's "
                    f"{cols}x{rows_n} scroll area — reachable only through an "
                    "exit/redirect naming them (screen_byte), never by "
                    "walking off an edge (KEY_LESSONS S10/S92)")
            if cols > 4 or rows_n > 4:
                errors.append(f"room {rid}: record {cols}x{rows_n} exceeds the "
                              "engine's 4x4 scroll grid (ROOM_DATA_FORMAT)")

        single_width = True
        if rec:
            single_width = F.val(rec['width_px']) <= 160

        for i, s in screens.items():
            if not (0 <= i <= 15):
                errors.append(f"room {rid} screen {i}: index outside the "
                              "4x4 grid (ROOM_DATA_FORMAT: row*4+col, "
                              "engine ceiling 16 — capacities.json)")
            lay = s.get('layout')
            if not lay:
                errors.append(f"room {rid} screen {i}: missing layout")
                continue
            # S92 states[] ([G-G] backend half): validate EVERY step entry.
            states = prj.screen_states(s)
            if s.get('states') and (s.get('npcs') or s.get('exits')):
                errors.append(
                    f"room {rid} screen {i}: has BOTH 'states' and top-level "
                    "npcs/exits — with states, all content lives inside the "
                    "state items (top-level layout is the inheritable "
                    "default)")
            if len(states) > 16:
                warnings.append(
                    f"room {rid} screen {i}: {len(states)} states — the "
                    "engine indexes counter*6 with NO clamp (CustomPtrChase); "
                    "keep the counter in range via the entry script")
            for v, st in enumerate(states):
                _validate_state(prj, r, rid, i, v, st, len(states),
                                errors, warnings)
            # S98: no "spawn entry" requirement any more — the $8F "spawn"
            # is an EXAMINE SPOT (PyBoy-measured); arrival always comes from
            # the source exit / warp (KEY_LESSONS S4). A map_transition warp
            # lands on its own pixel coords (PyBoy S98, no $8F in the room).

    _validate_layouts_tilesets(prj, errors, warnings)

    # ---------------------------------------------- progression (S70, E2)
    from .project import QUEST_EID_BASE, QUEST_EID_CAP
    ens = prj.progression.get('enemies', []) if hasattr(prj, 'progression') \
        else []
    eids = sorted(e['_eid'] for e in ens)
    if eids:
        if eids != list(range(QUEST_EID_BASE, QUEST_EID_BASE + len(eids))):
            errors.append(
                f"progression.enemies: EIDs must be dense from "
                f"{QUEST_EID_BASE} (rows are tail-appended at $14:$7ECC; a "
                "gap would misaddress every later row — EID*25+$4C1D)")
        if len(eids) > QUEST_EID_CAP:
            errors.append(
                f"progression.enemies: {len(eids)} rows exceed the bank $14 "
                f"free-tail capacity ({QUEST_EID_CAP} rows / 308 bytes)")
    for e in ens:
        eid = e['_eid']
        ctx = f"progression.enemies[{e.get('id')}]"
        if not (0 <= F.val(e.get('species', -1)) <= 255):
            errors.append(f"{ctx}: species must be 0-255 (byte field)")
        if not (1 <= F.val(e.get('level', 0)) <= 99):
            errors.append(f"{ctx}: level must be 1-99")
        if not (0 <= F.val(e.get('joinability', 7)) <= 7):
            errors.append(f"{ctx}: joinability 0-7 ($00 always joins, $07 "
                          "never — MONSTER_DATA)")
        for f16 in ('exp', 'hp', 'mp', 'atk', 'def', 'agl', 'int'):
            if not (0 <= F.val(e.get(f16, 0)) <= 0xFFFF):
                errors.append(f"{ctx}: {f16} must be 16-bit")
        ai = e.get('ai_weights', [0, 0, 0, 0])
        if len(ai) != 4 or any(not (0 <= F.val(x) <= 255) for x in ai):
            errors.append(f"{ctx}: ai_weights must be 4 bytes")
        sk = e.get('skills', [])
        if len(sk) > 4 or any(not (0 <= F.val(x) <= 255) for x in sk):
            errors.append(f"{ctx}: skills must be <= 4 byte ids ($FF pads)")
        if F.val(e.get('joinability', 7)) != 7 and F.val(e.get('hp', 0)) > 1023:
            warnings.append(
                f"{ctx}: joinable enemy with hp {F.val(e['hp'])} — fight EID "
                "== join EID means the JOINED monster inherits these stats "
                "as its creation base (80-100% roll, MONSTER_DATA)")

    # ------------------------------- vanilla exit extensions (S70, Entry 6)
    # S94b: VanillaExitResolve takes the FIRST row matching (mapID, screen);
    # an 'any' row shadows every per-screen row of the same map behind it,
    # and two rows for one (map, screen) can never both fire.
    seen_keys = {}
    for ext in getattr(prj, 'vanilla_exit_exts', []):
        mid = F.val(ext.get('mapID', -1))
        scr = ext.get('screen', 'any')
        scr_k = 'any' if scr in (None, 'any') else F.val(scr)
        src = ('entrance_redirects' if ext.get('_generated')
               else 'vanilla_exit_extensions')
        for (pm, ps), psrc in seen_keys.items():
            if pm == mid and (ps == scr_k or 'any' in (ps, scr_k)):
                errors.append(
                    f"{src}: vanilla ${mid:02X} screen {scr_k} already has an "
                    f"exit override from {psrc} (screen {ps}) — one override "
                    "per (room, screen); merge them into one entry")
        seen_keys[(mid, scr_k)] = src
    for ext in getattr(prj, 'vanilla_exit_exts', []):
        mid = F.val(ext.get('mapID', -1))
        ctx = f"vanilla_exit_extensions[{F.hexb(mid) if mid >= 0 else '?'}]"
        if not (0 <= mid < 0x6B):
            errors.append(f"{ctx}: mapID must be a VANILLA room (< $6B) — "
                          "custom rooms own their exit lists in bank $60")
        scr = ext.get('screen', 'any')
        if scr not in (None, 'any') and not (0 <= F.val(scr) <= 15):
            errors.append(f"{ctx}: screen must be 0-15 or 'any'")
        if 'step_counter' not in ext:
            errors.append(f"{ctx}: step_counter (the room's vanilla WRAM "
                          "counter, e.g. $D95E for MedalMan) is required — "
                          "variants are selected by its value")
        steps = ext.get('steps') or []
        if not (1 <= len(steps) <= 16):
            errors.append(f"{ctx}: needs 1-16 step variants")
        for si, st in enumerate(steps):
            rows = st.get('exits') or []
            if len(rows) > 17:
                errors.append(f"{ctx} step {si}: {len(rows)} rows exceed the "
                              "wCustomExitBuffer copy budget (17 rows + "
                              "terminator in 127 bytes)")
            for e in rows:
                x, y = F.val(e.get('x', -1)), F.val(e.get('y', -1))
                if x == 0xFF:
                    errors.append(f"{ctx} step {si}: trigger_x $FF is the "
                                  "list terminator (CROSSBANK_ROOMS "
                                  "authoring rule 2)")
                # S94b: Entry 9 (boundary y=0/7) reads the extension too.
                if 'screen_byte' not in e:
                    errors.append(f"{ctx} step {si}: exit ({x},{y}) has no "
                                  "screen_byte — NEVER guessed (KEY_LESSONS "
                                  "v14-v18/S40)")
                dest = e.get('dest')
                try:
                    dmid = prj.resolve_dest(dest)
                except Exception as ex:
                    errors.append(f"{ctx} step {si}: dest {dest!r}: {ex}")
                    continue
                if dmid >= 0x6B and F.val(e.get('gate_flag', 0)) != 0:
                    errors.append(
                        f"{ctx} step {si}: exit to custom room "
                        f"{F.hexb(dmid)} must use gate_flag=0 (flag=1 takes "
                        "the gate-entry path and garbage-indexes "
                        "GateFloorDataTable — CROSSBANK_ROOMS mapID audit)")

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
            if 'lines' in e and 'raw' not in e:
                ls = e['lines']
                if len(ls) > T.BOX_LINES or (ls and len(ls[0]) > T.FIRST_LINE):
                    warnings.append(
                        f"text {F.hexw(tid)} ({e.get('id','')}): 'lines' form — "
                        f"lines past {T.BOX_LINES} scroll without waiting and the "
                        f"first line has {T.FIRST_LINE} cells after '*:' (engine "
                        "wraps mid-word); the 'boxes' form waits per box (S97 r2)")
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

    # ------------------------------------------------ talk scripts (S98)
    by_did = {e.get('id'): e for e in prj._dialogue if e.get('id')}
    for sid, sc in prj._scripts.items():
        t = sc.get('talk')
        if not t:
            continue
        ctx = f"script {sid} (talk)"

        def _dlg(did, what):
            if did and did not in by_did:
                errors.append(f"{ctx}: {what} dialogue {did!r} not defined")
            return by_did.get(did)
        q = _dlg(t.get('text'), 'question' if t.get('question') else 'text')
        if q is not None:
            if t.get('question') and not q.get('choice'):
                errors.append(f"{ctx}: a YES/NO talk needs its text to end in the "
                              "choice box — dialogue 'choice': true ($E7 $F0)")
            if not t.get('question') and q.get('choice'):
                warnings.append(f"{ctx}: the text opens a YES/NO box but the talk "
                                "has no question (the answer is ignored)")
        for part in ('yes', 'no', 'then'):
            b = t.get(part) or {}
            d = _dlg(b.get('text'), f'{part} reply')
            if d is not None and d.get('choice'):
                warnings.append(f"{ctx}: the {part} reply opens another YES/NO box "
                                "that nothing reads")
            mv = b.get('move')
            if mv:
                try:
                    dmid = prj.resolve_dest(mv.get('dest'))
                    dr = prj.room_by_mid(dmid) if str(mv.get('dest', '')).startswith('room:') else None
                    if dr is not None and int(mv.get('screen', 0)) not in prj.room_screens(dr):
                        errors.append(f"{ctx}: {part}.move goes to screen {mv.get('screen')} "
                                      f"which room {dr.get('id')} does not have")
                except Exception as ex:
                    errors.append(f"{ctx}: {part}.move: {ex}")

    # ------------------------------------------------------ doors (S98)
    # S98 r2: a door is a named OBJECT (exit rows on one cell sharing a
    # `door` id); `link` names the partner object (custom id or vanilla
    # `vdoor_MM_k_x_y`, whose redirect row carries `door`/`link`). An
    # unconnected door has no dest and is not emitted. S98 r1 projects
    # (two ends sharing one id, no `link`) are checked the old way.
    cells, links, names, unlinked = {}, {}, {}, []
    for r in rooms:
        for k, s in prj.room_screens(r).items():
            for st in (s.get('states') or [s]):
                for e in st.get('exits', []):
                    did = e.get('door')
                    if not did:
                        continue
                    cells.setdefault(did, set()).add(
                        ('room', F.val(r['mapID']), k, F.val(e['x']), F.val(e['y'])))
                    names[did] = e.get('name') or did
                    if e.get('link'):
                        links[did] = e['link']
                    if 'dest' not in e:
                        unlinked.append((did, r.get('id'), k, F.val(e['x']), F.val(e['y'])))
    for rd in prj.custom.get('entrance_redirects') or []:
        did = rd.get('door')
        if did:
            cells.setdefault(did, set()).add(
                ('vanilla', F.val(rd['mapID']), F.val(rd['screen']),
                 F.val(rd['x']), F.val(rd['y'])))
            names.setdefault(did, did)
            if rd.get('link'):
                links[did] = rd['link']
    seen_unlinked = set()
    for did, rid, k, x, y in unlinked:
        if did not in seen_unlinked:
            seen_unlinked.add(did)
            warnings.append(f"door '{names[did]}' (room {rid} screen {k} ({x},{y})) is not "
                            "connected to another door yet — it does nothing in game")
    for did, es in sorted(cells.items()):
        if did in links or did in seen_unlinked:
            if len(es) != 1:
                warnings.append(f"door '{names[did]}' sits on {len(es)} cells {sorted(es)} — "
                                "a door object is one cell (a hand edit?)")
            if did in links:
                other = links[did]
                if other not in cells:
                    warnings.append(f"door '{names[did]}' is linked to {other!r}, which does "
                                    "not exist")
                elif links.get(other) != did:
                    warnings.append(f"door '{names[did]}' leads to '{names.get(other, other)}' "
                                    "but that door does not lead back")
        elif len(es) != 2:
            warnings.append(f"door {did}: {len(es)} end(s) {sorted(es)} — a door has "
                            "exactly two (the editor keeps them paired; a hand edit "
                            "may have broken the pair)")

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
        free1 = bool(pal.get('free_color1'))
        bad_rows = [ri for ri, row in enumerate(rows)
                    if (F.val(row[1]) != 0x6BFF and not (free1 and ri < 4))
                    or F.val(row[3]) & 0x7FFF != 0x0000]
        if free1 and any(F.val(r[1]) & 0x8000 or F.val(r[0]) & 0x8000 or
                         F.val(r[2]) & 0x8000 for r in rows):
            warnings.append(f"palette {pal.get('id')}: bit 15 set in a colour — "
                            "ignored by the hardware")
        if bad_rows:
            warnings.append(
                f"palette {pal.get('id')} rows {bad_rows}: idx1 != $6BFF or "
                "idx3 != $0000 — engine FORCES those two colours at runtime; "
                "authored values there will not display (KEY_LESSONS S7/S39)")
        if not pal.get('label'):
            errors.append(f"palette {pal.get('id')}: missing 'label'")

    return errors, warnings


def _validate_state(prj, r, rid, i, v, st, n_states, errors, warnings):
    """One screen step-entry's NPC/exit checks (S92: runs per state)."""
    tag = (f"room {rid} screen {i}" if n_states == 1
           else f"room {rid} screen {i} state {v}")
    real_npcs = [n for n in st.get('npcs', [])
                 if (n.get('kind') == 'npc'
                     or (n.get('kind') == 'raw' and n.get('bytes')
                         and F.val(n['bytes'][0]) < 0x80))]
    if len(real_npcs) > 8:
        errors.append(
            f"{tag}: {len(real_npcs)} NPCs — the per-screen-state ceiling is "
            "8 HARD (S91 measured: $0B:$470F fills exactly $101 B at $D7D2; "
            "a 9th entry silently corrupts $D8D9+ script state — "
            "capacities.json / ROOM_DATA_FORMAT 'NPC capacity')")
    elif len(real_npcs) > 3:
        warnings.append(
            f"{tag}: {len(real_npcs)} NPCs with distinct sprites may exhaust "
            "the per-screen sprite-sheet VRAM budget (S91: order-filled; "
            "8 light sheets fit, ~2-3 heavy exhaust; overflow renders "
            "BLANK, no crash) — verify in PyBoy")
    try:
        prj.resolve_layout(st['layout'], ctx=tag)
    except Exception as ex:
        errors.append(str(ex))
    for n in st.get('npcs', []):
        if n.get('kind') == 'raw':
            bs = n.get('bytes', [])
            if len(bs) != 5 or any(not (0 <= F.val(b) <= 255) for b in bs):
                errors.append(f"{tag}: raw interact entry must be exactly "
                              "5 bytes 0-255 (ROOM_DATA_FORMAT interact "
                              "entry)")
            continue
        x, y = n.get('x'), n.get('y')
        if not (0 <= x <= 9 and 0 <= y <= 7):
            errors.append(f"{tag}: NPC/spawn at ({x},{y}) outside 10x8 walk "
                          "grid (ROOM_DATA_FORMAT scroll/walk grid)")
        if n['kind'] == 'spawn':
            # S98: the legacy 'spawn' kind emits an $8F EXAMINE SPOT (PyBoy-
            # measured, ROOM_DATA_FORMAT "Interact entries"): an A press on or
            # facing the cell runs its script — script 0 = the room's ENTRY
            # script (KEY_LESSONS 'ghost NPC'). Nothing reads it as a spawn.
            if F.val(n.get('script', 0)) == 0:
                warnings.append(
                    f"{tag}: legacy 'spawn' marker at ({x},{y}) is an $8F "
                    "examine spot (S98) — pressing A on or facing it re-runs the "
                    "room's ENTRY script (index 0). It does not choose where the "
                    "player appears (the exit does); delete it unless intended")
        elif n['kind'] in ('examine', 'step'):
            sid = n.get('script')
            if sid in (None, 'none'):
                errors.append(f"{tag}: {n['kind']} spot ({x},{y}) needs a script "
                              "(byte 4 = the room's script index)")
            elif isinstance(sid, int):
                if not 0 <= sid <= 0xFF:
                    errors.append(f"{tag}: {n['kind']} spot script index {sid} out of range")
            else:
                try:
                    if prj.script_index(r, sid) == 0:
                        warnings.append(
                            f"{tag}: {n['kind']} spot ({x},{y}) runs script index 0 "
                            "— the room's ENTRY script")
                except Exception as e:
                    errors.append(f"{tag}: {e}")
            if n['kind'] == 'examine' and n.get('facing', 'any') not in F.EXAMINE_FACING:
                errors.append(f"{tag}: examine facing must be one of "
                              f"{sorted(F.EXAMINE_FACING)}")
        else:
            sid = n.get('script')
            if isinstance(sid, int):
                # S97: a cloned raw entry edited in the GUI keeps its raw
                # script index when the room's table has no id for it
                if not 0 <= sid <= 0xFF:
                    errors.append(f"{tag}: NPC script index {sid} out of range")
            elif sid not in (None, 'none'):
                try:
                    si = prj.script_index(r, sid)
                    if si == 0:
                        errors.append(
                            f"{tag}: NPC references script index 0 — "
                            "reserved for room entry (KEY_LESSONS S2)")
                except Exception as e:
                    errors.append(f"{tag}: {e}")
            if n.get('facing') and n['facing'] not in F.FACING:
                errors.append(f"{tag}: unknown facing {n['facing']!r}")
            # S97 behaviour (type byte low nibble — ROOM_DATA_FORMAT "NPC
            # behaviour types"): gate-only wanderers freeze elsewhere; the
            # patterned walkers never test tiles, so a path leaving the
            # 10x8 screen walks the NPC off-screen.
            try:
                bv = F.behaviour_value(n.get('behaviour', 0))
            except ValueError as e:
                errors.append(f"{tag}: {e}")
                bv = 0
            if bv in F.GATE_ONLY_BEHAVIOURS:
                warnings.append(
                    f"{tag}: NPC ({x},{y}) behaviour {F.BEHAVIOUR_NAMES[bv]} "
                    "only acts on the gate-floor wanderer screen ($C926) — "
                    "in a room it stands frozen and unanimated")
            off = [(x + dx, y + dy) for dx, dy in F.npc_path(bv)
                   if not (0 <= x + dx <= 9 and 0 <= y + dy <= 7)]
            if off:
                warnings.append(
                    f"{tag}: NPC ({x},{y}) {F.BEHAVIOUR_NAMES.get(bv, bv)} "
                    f"walks off the screen at {off[0]} (walkers ignore "
                    "walls and edges)")
    for e in st.get('exits', []):
        if 'screen_byte' not in e:
            errors.append(
                f"{tag}: exit ({e.get('x')},{e.get('y')}) has no "
                "screen_byte — NEVER guessed; copy from an existing exit to "
                "the same destination (KEY_LESSONS v14-v18 + S40 off-map "
                "spawn)")
            continue
        sb = F.val(e['screen_byte'])
        dest = e.get('dest')
        try:
            dmid = prj.resolve_dest(dest)
        except Exception as ex:
            errors.append(f"{tag}: exit dest {dest!r}: {ex}")
            continue
        if isinstance(dest, str) and dest.startswith('room:'):
            dr = prj.room_by_mid(dmid)
            # S98: the low nibble IS the destination screen index on the 4x4
            # grid ($2DE7 offsets) — screen 4 of a 1-wide, 2-high room is
            # legal; the check is "does that screen exist" (KEY_LESSONS S40:
            # a stale nibble stranded the player off-map)
            dscreens = prj.room_screens(dr) if not dr.get('placeholder') else {}
            if dscreens and (sb & 0x0F) not in dscreens:
                errors.append(
                    f"{tag}: exit to {F.hexb(dmid)} arrives on screen "
                    f"{sb & 0x0F} (screen_byte {F.hexb(sb)}), which that room "
                    "does not have — the player would land off-map (KEY_LESSONS S40)")
        ex, ey = F.val(e.get('x')), F.val(e.get('y'))
        edge = _edge_neighbour(prj, r, i, ex, ey)
        if edge:
            side, nb = edge
            if side == 'bottom':
                warnings.append(
                    f"{tag}: exit ({ex},{ey}) on the bottom row borders screen "
                    f"{nb} — in a custom room a y=7 exit fires on WALK-ON, so "
                    "the player can never walk down into that screen through "
                    "this cell (S70v3 / S98)")
            else:
                warnings.append(
                    f"{tag}: edge exit ({ex},{ey}) on the {side} edge never "
                    f"fires — screen {nb} lies beyond that edge and pushing "
                    "into it SCROLLS instead (PyBoy S98: x=9 exit + neighbour "
                    "screen -> scroll; Entry 6 skips x=0/9 and y=0 rows)")


def _edge_neighbour(prj, r, key, x, y):
    """S98: ('left'|'right'|'top'|'bottom', neighbour screen) when an exit
    cell sits on a screen edge that borders another screen of the room inside
    the record's scroll area (the engine scrolls there), else None."""
    try:
        screens = prj.room_screens(r)
    except Exception:
        return None
    rec = r.get('record') or {}
    try:
        cols = F.val(rec.get('width_px', 160)) // 160
        rows = F.val(rec.get('height_px', 128)) // 128
    except Exception:
        cols = rows = 1
    c, rw = key % 4, key // 4
    for side, cond, dc, dr in (('left', x == 0, -1, 0), ('right', x == 9, 1, 0),
                               ('top', y == 0, 0, -1), ('bottom', y == 7, 0, 1)):
        if not cond:
            continue
        nc, nr = c + dc, rw + dr
        if 0 <= nc < cols and 0 <= nr < rows and (nr * 4 + nc) in screens:
            return side, nr * 4 + nc
    return None


def _validate_layouts_tilesets(prj, errors, warnings):
    """S92 [G-A]: content checks for custom.layouts / custom.tilesets."""
    for lay in prj.layouts:
        lid = lay.get('id', '?')
        if 'tiles' not in lay and 'attr' not in lay:
            errors.append(f"custom.layouts {lid!r}: needs 'tiles' and/or "
                          "'attr'")
        for key, name in (('tiles', 'tile'), ('attr', 'palette')):
            grid = lay.get(key)
            if grid is None:
                continue
            if len(grid) != 16 or any(len(row) != 20 for row in grid):
                errors.append(f"custom.layouts {lid!r}: {key} must be 16 "
                              "rows x 20 cols (visible grid; the 12 VRAM "
                              "pad cols are added at compile)")
                continue
            hi = 255 if key == 'tiles' else 15
            for rr, row in enumerate(grid):
                for cc, vv in enumerate(row):
                    if not (0 <= int(vv) <= hi):
                        errors.append(
                            f"custom.layouts {lid!r}: {name} value {vv} at "
                            f"({rr},{cc}) outside 0-{hi}")
                        break
                else:
                    continue
                break
    for ts in prj.tilesets:
        tid = ts.get('id', '?')
        if ('raw2bpp' in ts) == ('spec' in ts):
            errors.append(f"custom.tilesets {tid!r}: exactly one of "
                          "'raw2bpp' or 'spec'")
            continue
        key = 'raw2bpp' if 'raw2bpp' in ts else 'spec'
        path = os.path.join(prj.root, ts[key])
        if not os.path.exists(path):
            errors.append(f"custom.tilesets {tid!r}: {key} file not found: "
                          f"{ts[key]}")
        elif key == 'raw2bpp' and os.path.getsize(path) != 2048:
            errors.append(f"custom.tilesets {tid!r}: raw2bpp must be 2048 "
                          f"bytes, got {os.path.getsize(path)}")
        elif key == 'spec':
            import json
            try:
                spec = json.load(open(path))
            except Exception as ex:
                errors.append(f"custom.tilesets {tid!r}: spec unreadable: "
                              f"{ex}")
                continue
            for row in spec.get('palette', []):
                slot = int(row.get('slot', -1))
                if not (0 <= slot < 128):
                    errors.append(f"custom.tilesets {tid!r}: spec slot "
                                  f"{slot} outside 0-127")
                if slot in (77, 78):
                    warnings.append(
                        f"custom.tilesets {tid!r}: spec places a tile at "
                        f"slot {slot} — the animated no-go zone "
                        "(KEY_LESSONS: indices 77-78 are animated by the "
                        "engine; build_combined_tileset reserves them)")


def bank_usage(generated):
    """{bank: (used_bytes, capacity)} for the compiler-owned banks, measured
    on the generated text exactly as the pre-build overflow check does
    (S96: the editor's space meters read this). Banks $64/$67 are pure
    payload; $60/$71 add their pinned template head."""
    out = {}
    for bank, fname in ((0x64, 'patches/bank_064.asm'),
                        (0x67, 'patches/bank_067.asm')):
        text = generated.get(f"file:{fname}")
        if text is not None:
            out[bank] = (_payload_bytes(text), BANK_SIZE)
    for bank, fname in ((0x60, 'patches/bank_060.asm'),
                        (0x71, 'patches/bank_071.asm')):
        text = generated.get(f"file:{fname}")
        if text is None:
            continue
        gen_bytes = _payload_bytes(
            text.split('SCRIPT DATA (generated', 1)[-1]
            if bank == 0x60 else
            text.split('Custom26DDTable —', 1)[-1])
        out[bank] = ((TEMPLATE_SIZE.get(bank) or 0) + gen_bytes, BANK_SIZE)
    return out


def _validate_accounting(prj, generated, errors, warnings):
    # EDITOR_DESIGN §6: bank overflow must fail BEFORE rgbasm runs (rgbasm
    # reports only the first excess byte — KEY_LESSONS S52 #3).
    usage = bank_usage(generated)
    for bank in (0x64, 0x67):
        # S92: banks $64/$67 have no engine template head — the db/dw payload
        # (self-ID + pointer table + streams) IS the whole bank.
        if bank not in usage:
            continue
        gen_bytes = usage[bank][0]
        if gen_bytes > BANK_SIZE:
            errors.append(
                f"bank ${bank:02X} OVERFLOW: {gen_bytes} > {BANK_SIZE} "
                "bytes of layout/tileset data — trim content "
                "(KEY_LESSONS S52: rgbasm reports only the first excess "
                "byte)")
        elif gen_bytes > BANK_SIZE - 256:
            warnings.append(
                f"bank ${bank:02X}: {BANK_SIZE - gen_bytes} bytes free "
                "(under 256) — nearly full")
    for bank in (0x60, 0x71):
        if bank not in usage:
            continue
        tmpl = TEMPLATE_SIZE.get(bank)
        total = usage[bank][0]
        gen_bytes = total - (tmpl or 0)
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
