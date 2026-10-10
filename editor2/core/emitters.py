"""emitters.py — the emitter registry.

Each emitter declares the schema section it consumes and the output target
it owns (a whole generated file, or a marked @BUILD_PROJECT region inside an
existing patch file). Emitters are independent: adding a future subsystem
(e.g. custom music per ROADMAP Arc 3, or the data half of custom skills per
BATTLE_SKILL_SYSTEM §13) means registering a new emitter — no existing
emitter changes. (Design commitment S53: "emitter registry with declared
bank ownership"; reserved schema sections hard-error in project.py until an
emitter exists for them.)

Targets:
  file:patches/bank_060.asm      — whole file (template head + generated data)
  file:patches/bank_071.asm      — whole file (template head + generated tables)
  region:patches/bank_017.asm#room_palettes_a
  region:patches/bank_017.asm#room_render_tables
  region:patches/wram.asm#wram_step_counters
"""

import hashlib
import os

from . import formats as F
from . import textenc as T
from . import scriptgen as S
from . import music as M

HERE = os.path.dirname(__file__)
TEMPLATES = os.path.join(HERE, 'templates')

# sha256 of the verbatim engine heads, extracted S53 from the user-confirmed
# patch files. The compiler refuses to run if a template drifted — the engine
# code is proven in-game; only a deliberate engine session may change it
# (then re-pin these). (Design commitment: "engine template byte-checked
# against proven source".)
TEMPLATE_SHA = {
    'bank_060_head.asm':
        None,   # pinned at first successful regression; see compiler.pin_templates
    'bank_071_head.asm':
        None,
}
TEMPLATE_SHA_FILE = os.path.join(TEMPLATES, 'PINNED_SHA256')


SKILL_SCRIPT_FIRST = 2     # S105: skill script ids 0/1 = no-op (see emit_bank_060)


def template(name):
    path = os.path.join(TEMPLATES, name)
    data = open(path, 'rb').read()
    pins = {}
    if os.path.exists(TEMPLATE_SHA_FILE):
        for line in open(TEMPLATE_SHA_FILE):
            if line.strip():
                h, n = line.split()
                pins[n] = h
    got = hashlib.sha256(data).hexdigest()
    if name in pins and pins[name] != got:
        raise RuntimeError(
            f"engine template {name} does not match its pinned sha256 — "
            "the engine head is user-confirmed code; re-pin only after an "
            "engine session deliberately changes it (PROJECT_COMPILER.md §5)")
    return data.decode()


# ---------------------------------------------------------------------------
# helpers shared by emitters
# ---------------------------------------------------------------------------

def room_idx(room):
    return F.val(room['mapID']) - 0x6B


def room_tag(room):
    return f"CustomRoom{room_idx(room)}"


def banner(title, sub=None):
    bar = "; " + "=" * 77
    out = [bar, f"; {title}"]
    if sub:
        out += [f"; {s}" for s in sub]
    out.append(bar)
    return out


# ---------------------------------------------------------------------------
# bank $60 emitter — rooms + scripts + text (owns file patches/bank_060.asm)
# ---------------------------------------------------------------------------

def emit_bank_060(prj, warnings):
    """S136 (ROADMAP ARC CAP2b): bank $60 = the forwarding head + its own reader
    block + its data (editor2/core/places.py). The places that do not fit go
    to place banks $80+ (emit_place_banks)."""
    from . import places as PL
    return PL.emit_bank_060(prj, warnings, template('bank_060_head.asm'))


def emit_place_banks(prj, warnings):
    from . import places as PL
    return PL.emit_place_banks(prj, warnings)


def _npc_cond_lines(conds):
    """S117 (NG2): the $A0 / $A1 condition prefixes before an NPC entry (bank
    $60 CopyNPCListToBuffer: shown only while the flag is SET / CLEAR; a
    failed one sets the NPC's hidden bit)."""
    return [F.db_line([0xA1 if clr else 0xA0, idx & 0xFF, idx >> 8, 0xFF, 0xFF],
                      comment=f"next NPC shown only while flag {F.hexw(idx)} is "
                              f"{'CLEAR' if clr else 'SET'}")
            for idx, clr in conds]


def _npc_colour_lines(colour):
    """S123: the $A2 colour prefix before an NPC entry (bank $60
    CopyNPCListToBuffer: the next NPC is drawn in OBJ palette p — always, or
    while a flag is SET; entry 11 NpcColourDraw applies it)."""
    if colour is None:
        return []
    pal, flag = colour
    f = 0xFFFF if flag is None else flag
    return [F.db_line([0xA2, pal, f & 0xFF, f >> 8, 0xFF],
                      comment=f"next NPC drawn in OBJ palette {pal}" +
                              ('' if flag is None else f" while flag {F.hexw(flag)} is SET"))]


def _vanilla_npc_exts(prj):
    """S117 (ROADMAP NG2) — VanillaNPCExtTable, read by bank $60 entry 1
    (CustomReadInteract's vanilla branch) for every vanilla room's NPC /
    interact list. Emitted ALWAYS (the template references the label); an
    empty table = a lone $FF. Rows as VanillaExitExtTable: db mapID, screen /
    dw step_counter / db n_steps / dw variant ptrs. Each variant is the
    vanilla list with the gate swirls of a re-bossed / re-routed portal
    conditioned on that gate's cleared flag (Project.vanilla_swirl_overrides)."""
    out = banner("VANILLA-ROOM NPC OVERRIDES — gate swirls (S117, generated)", [
        "Read by bank $60 entry 1 (CustomReadInteract) for every vanilla room",
        "via bank $0B GetRoomDataPtr; no row = the vanilla list unchanged."])
    rows = prj.vanilla_swirl_overrides()
    out.append("VanillaNPCExtTable:")
    bodies = []
    for row in rows:
        mid, k = row['mapID'], row['screen']
        out.append(f"    db {F.hexb(mid)}, {k}   ; {row['name']} screen {k}")
        out.append(f"    dw {F.hexw(row['step_counter'])}   ; vanilla step counter")
        out.append(f"    db {len(row['steps'])}")
        labels = []
        for v, ents in enumerate(row['steps']):
            lbl = f"VNpc{mid:02X}_{k}_V{v}"
            labels.append(lbl)
            bodies.append((lbl, ents))
        out.append("    dw " + ", ".join(labels))
    out.append("    db $FF   ; table terminator")
    out.append("")
    for lbl, ents in bodies:
        out.append(f"{lbl}:")
        for en in ents:
            if en['cond']:
                flag, tgt = en['cond']
                from . import gates as G
                pal = G.cleared_swirl(prj.custom, tgt)     # S123: colour once cleared
                if pal is None:
                    out += _npc_cond_lines([(flag, True)])
                else:
                    out += _npc_colour_lines((pal, flag))
            out.append(F.db_line(en['bytes'], comment=(
                f"gate swirl -> gate {en['cond'][1]} (until cleared)" if en['cond']
                else "vanilla entry")))
        out.append("    db $FF")
        out.append("")
    return out


def _monster_cast_lines(lbl, casts):
    """S101 — MONSTER NPCs of one place: per screen, the 4 display-list pairs
    [species+$10, 1] that sprite ids $F0-$F3 draw (place_readers.asm
    CustomMonsterCast, called first by entry 8). S136: one list per place, in
    the place's block (PlaceCastTable row = its label, $0000 = none)."""
    out = [f"{lbl}:"]
    for k, cast in casts:
        pairs = []
        for sp in (cast + [None] * 4)[:4]:
            pairs += [0xFF, 0x00] if sp is None else [(sp + 0x10) & 0xFF, 0x01]
        out.append(f"    db {k}")
        out.append(F.db_line(pairs, comment="$F0-$F3 = species "
                             + ", ".join(str(x) for x in cast)))
    out.append("    db $FF")
    out.append("")
    return out


def _state_rule_lines(prj, r, lbl, rules):
    """S97 (ROADMAP P3.5a) — one place's custom.rooms[].state_rules, read by
    place_readers.asm CustomStateRules (entry 8). S136: in the place's block
    (PlaceRuleTable row = its label, $0000 = no rules).
      room list: db screen / dw step_counter / dw rules ... db $FF
      rules:     db state / db n_terms / dw flag (bit 15 = must be clear) ...
                 db $FF"""
    tag = room_tag(r)
    screens = prj.room_screens(r)
    out = [f"{lbl}:"]
    for k, _ in rules:
        ctr = prj.step_counter_label(r, k, screens[k])
        out.append(f"    db {k}")
        out.append(f"    dw {ctr}")
        out.append(f"    dw {tag}_S{k}_Rules")
    out.append("    db $FF")
    for k, lst in rules:
        out.append(f"{tag}_S{k}_Rules:")
        for st, terms in lst:
            words = [F.hexw(idx | (0x8000 if clr else 0)) for idx, clr in terms]
            desc = " & ".join(f"{'!' if clr else ''}{F.hexw(idx)}"
                              for idx, clr in terms) or "always"
            out.append(f"    db {st}, {len(terms)}   ; state {st} when {desc}")
            if words:
                out.append("    dw " + ", ".join(words))
        out.append("    db $FF")
    out.append("")
    return out


def _exit_row(prj, src, e):
    """S140 (ROADMAP ARC CAP3a): an exit row's bytes — the 7 of the engine's
    format with the destination's REAL map id, preceded by `$FD <region>` when
    the row leads into a place of another region (Project.exit_prefix; src =
    the source room, None = a vanilla room's extension row). The pinned reader
    CopyExitListToBuffer turns a prefixed row into a link id."""
    dest_s = e['dest']
    dest = prj.resolve_dest(dest_s)
    pre = []
    if isinstance(dest_s, str) and dest_s.startswith('room:') and dest >= 0x6B:
        pre = prj.exit_prefix(src, dest)
        dest = F.mid_real(dest)
    return pre, F.exit_entry(F.val(e['x']), F.val(e['y']), dest,
                             F.val(e.get('gate_flag', 0)),
                             F.val(e['screen_byte']),
                             F.val(e['spawn_x']), F.val(e['spawn_y']))


def _exit_lines(prj, src, e, comment):
    pre, b = _exit_row(prj, src, e)
    out = []
    if pre:
        out.append(F.db_line(pre, comment=f"S140: the next row leads into region {pre[1]}"))
    out.append(F.db_line(b, comment=comment))
    return out


def _vanilla_exit_exts(prj):
    """S70 — custom.vanilla_exit_extensions -> VanillaExitExtTable, read by
    template entry 7 (VanillaExitResolve) for bank $0B RoomEntry6_ExitChecker.
    The label is referenced by the TEMPLATE HEAD, so it is emitted ALWAYS
    (empty table = a lone $FF terminator: every vanilla room scans one byte
    and falls back to the vanilla SharedPtrChase path).
    Row: db mapID, screen ($FF = any) / dw step_counter / db n_steps /
    dw variant ptrs; $FF term (S94b: per-screen keying). A variant list
    REPLACES the (room, screen)'s exit list wholesale for that step, so it
    must contain the vanilla rows PLUS the additions/changes. S94b: Entry 9
    (boundary y=0/7) is diverted too, so boundary rows are live."""
    out = banner("VANILLA-ROOM EXIT EXTENSIONS (S70, generated)", [
        "Read by bank $60 entry 7 (VanillaExitResolve, template head) on",
        "EVERY non-gate room step via bank $0B RoomEntry6_ExitChecker.",
        "Variant selected by [step_counter], clamped to n_steps-1.",
        "Lists are copied to wCustomExitBuffer (<= 17 rows + terminator)."])
    out.append("VanillaExitExtTable:")
    variants = []                      # (label, rows) in first-use order
    by_key = {}
    for ext in prj.vanilla_exit_exts:
        mid = F.val(ext['mapID'])
        steps = ext['steps']
        scr = ext.get('screen', 'any')
        scr_b = 0xFF if scr in (None, 'any', 0xFF, '0xFF', '$FF') else F.val(scr)
        out.append(f"    db {F.hexb(mid)}, {F.hexb(scr_b)}   ; mapID, screen ($FF = any)"
                   + (f" — {ext['comment']}" if ext.get('comment') else ""))
        out.append(f"    dw {F.hexw(F.val(ext['step_counter']))}"
                   "   ; vanilla step counter (WRAM)")
        out.append(f"    db {len(steps)}   ; n_steps (variant count)")
        labels = []
        for st in steps:
            rows = tuple(tuple(sum(_exit_row(prj, None, e), [])) for e in st['exits'])
            key = (mid, rows)
            if key not in by_key:
                lbl = f"VExt{mid:02X}_V{len([v for v in variants if v[0].startswith(f'VExt{mid:02X}_')])}"
                by_key[key] = lbl
                variants.append((lbl, st))
            labels.append(by_key[key])
        out.append("    dw " + ", ".join(labels)
                   + "   ; per-step variant lists (deduped)")
    out.append("    db $FF   ; table terminator")
    out.append("")
    for lbl, st in variants:
        out.append(f"{lbl}:")
        for e in st['exits']:
            out += _exit_lines(prj, None, e, e.get('comment',
                               f"exit ({F.val(e['x'])},{F.val(e['y'])}) -> {e['dest']}"))
        out.append("    db $FF")
        out.append("")
    return out


WARP_OPS = ('map_transition', 'warp_fade', '0x0F', '0x0f', '0x3B', '0x3b')


def _regionize_ops(prj, r, ops):
    """S140 (ROADMAP ARC CAP3a — regions): a script warp ($0F map_transition /
    $3B warp_fade) to a place carries the place's project mapID in its first
    word (a region's places: $16B, $26B, … — the high byte would read as the
    warp's GATE FLAG). Here, per room: the word becomes the real map id, and
    when the warp leaves the room's region (or starts in a global room, whose
    region is whatever the player brought) a `write_ram wWarpRegion, region + 1`
    (op $12, not yielding) goes right before it — the room commit (bank $73
    RegionCommit) enters that region. A word whose low byte is below $6B is a
    vanilla map / a gate number (gate flag in the high byte): untouched. One
    region: nothing changes."""
    if not prj.multi_region():
        return ops
    src = F.val(r['mapID'])
    src_global = prj.is_global(src)
    out = []
    for it in ops:
        if (isinstance(it, list) and len(it) >= 3 and it[0] == 'op'
                and str(it[1]) in WARP_OPS):
            w = S._pval(it[2])
            if isinstance(w, int) and (w & 0xFF) >= 0x6B:
                prj.room_by_mid(w)                      # a place of this project
                if not prj.is_global(w) and (src_global or
                                             F.mid_region(w) != F.mid_region(src)):
                    out.append(['op', 'write_ram', 'wWarpRegion', F.mid_region(w) + 1])
                it = [it[0], it[1], f'0x{F.mid_real(w):04X}'] + list(it[3:])
        out.append(it)
    return out


def _room_scripts(prj, r, text_names, warnings):
    tag = room_tag(r)
    out = [f"; --- {F.hexb(F.val(r['mapID']))} ({r.get('id','')}) scripts ---",
           f"{tag}_ScriptPtrTable:"]
    table = prj.room_script_table(r)          # ordered list of (idx, script_id)
    for idx, sid in table:
        out.append(f"    dw {tag}_Scr{idx:02d}   ; [{idx}] {sid}")
    out.append("")
    for idx, sid in table:
        script = prj.script(sid)
        out += S.emit_script(f"{tag}_Scr{idx:02d}",
                             _regionize_ops(prj, r, _patch_params(r, script['ops'])),
                             text_names=text_names, warnings=warnings)
        out.append("")
    out += _patch_data_lines(r)
    return out


def patch_label(r, name):
    """S119: the bank $60 label of a room's tile patch (custom.rooms[].patch_data)."""
    return f"{room_tag(r)}_Patch_" + ''.join(c if c.isalnum() else '_' for c in str(name))


def _patch_params(r, ops):
    """S119: script params 'patch:NAME' (ops $24 / $61) -> the room's patch label."""
    names = r.get('patch_data') or {}
    out = []
    for it in ops:
        if isinstance(it, list) and it and it[0] == 'op':
            row = list(it[:2])
            for p in it[2:]:
                if isinstance(p, str) and p.startswith('patch:'):
                    nm = p.split(':', 1)[1]
                    if nm not in names:
                        raise ValueError(f"room {r.get('id')}: tile patch {nm!r} has no "
                                         "patch_data")
                    row.append(patch_label(r, nm))
                else:
                    row.append(p)
            out.append(row)
        else:
            out.append(it)
    return out


def _patch_data_lines(r):
    """S119 (ROADMAP P3.8 part d): a room's tile patches for script ops $24 / $61
    in bank $60 (read by entries 9 / 10 CustomDrawTiles / CustomDrawAttrs):
    [offset word = row * 32 + column, bytes …, $D8 next row, $D9 end]."""
    pd = r.get('patch_data') or {}
    if not pd:
        return []
    out = [f"; --- {F.hexb(F.val(r['mapID']))} ({r.get('id','')}) tile patches (S119) ---"]
    for name in sorted(pd):
        b = [F.val(x) & 0xFF for x in pd[name]]
        out.append(f"{patch_label(r, name)}:")
        for i in range(0, len(b), 16):
            out.append(F.db_line(b[i:i + 16]))
    out.append("")
    return out


def _room_data(prj, r):
    tag = room_tag(r)
    out = [f"; --- {F.hexb(F.val(r['mapID']))} ({r.get('id','')}) room data ---",
           f"{tag}_SubTable:"]
    screens = prj.room_screens(r)             # dict idx -> screen
    width = prj.subtable_width(r)
    row = []
    for i in range(width):
        row.append(f"{tag}_Screen{i}" if i in screens else "$FFFF")
    # match hand-authored style: one dw per valid screen, $FFFF runs grouped
    i = 0
    while i < width:
        if i in screens:
            out.append(f"    dw {tag}_Screen{i}")
            i += 1
        else:
            j = i
            while j < width and j not in screens:
                j += 1
            out.append("    dw " + ", ".join(["$FFFF"] * (j - i)))
            i = j
    out.append("")
    for i in sorted(screens):
        s = screens[i]
        ctr = prj.step_counter_label(r, i, s)
        states = prj.screen_states(s)          # S92: >=1 step entries
        multi = len(states) > 1
        out.append(f"{tag}_Screen{i}:")
        out.append(f"    dw {ctr}    ; step counter")
        for v, st in enumerate(states):
            sfx = f"_V{v}" if multi else ""
            lb, le = prj.resolve_layout(st['layout'],
                                        ctx=f"{tag} screen {i} state {v}")
            cm = st.get('comment')
            out.append(f"    db {le}, {F.hexb(lb)}"
                       f"   ; {'state %d: ' % v if multi else ''}step_id, "
                       f"tileset_bank" + (f" — {cm}" if cm else ""))
            out.append(f"    dw {tag}_S{i}{sfx}_NPCs")
            out.append(f"    dw {tag}_S{i}{sfx}_Exits")
        out.append("")
        for v, st in enumerate(states):
            sfx = f"_V{v}" if multi else ""
            out.append(f"{tag}_S{i}{sfx}_NPCs:")
            # S98 (PyBoy-measured + bank $0B code): the examine-spot scan
            # (RoomEntry4 TalkScanExamineSpots) and the step-trigger scan
            # (SearchStepTriggers) both STOP at the first entry with bit 7
            # clear (an NPC) — a spot listed after an NPC never fires. Vanilla
            # lists spots first (157 of 160 lists; $1F screen 0's trailing
            # $81 is dead). Emit spots first, NPCs after, each in authored
            # order; the NPC parser (Entry 7) skips spots anywhere, so NPC
            # slot numbers do not change.
            def _is_spot(n):
                if n['kind'] in ('spawn', 'examine', 'step'):
                    return True
                return n['kind'] == 'raw' and F.val(n['bytes'][0]) >= 0x80
            npcs_in = st.get('npcs', [])
            for n in [n for n in npcs_in if _is_spot(n)] + \
                     [n for n in npcs_in if not _is_spot(n)]:
                if n['kind'] == 'raw':
                    # S92 clone fidelity: verbatim 5-byte interact entry
                    # ($90 walk-on markers, $82 markers, $8F spawns with
                    # spawn-id params — forms the typed schema doesn't model)
                    b = [F.val(v) for v in n['bytes']]
                    if b[0] < 0x80:
                        out += _npc_cond_lines(prj.npc_conditions(r, i, n))
                        out += _npc_colour_lines(prj.npc_colour(r, i, n))
                    out.append(F.db_line(b, comment=n.get('comment',
                               'raw interact entry (cloned verbatim)')))
                elif n['kind'] == 'spawn':
                    b = F.npc_spawn_entry(n['x'], n['y'],
                                          F.val(n.get('script', 0)))
                    out.append(F.db_line(b, comment=f"spawn ({n['x']},{n['y']})"
                               + (f" — {n['comment']}" if n.get('comment') else "")))
                elif n['kind'] in ('examine', 'step'):
                    # S98: invisible interact entries (formats.examine_entry /
                    # step_trigger_entry — ROOM_DATA_FORMAT "Interact entries")
                    sid = n.get('script')
                    sidx = (sid if isinstance(sid, int) else prj.script_index(r, sid))
                    if n['kind'] == 'examine':
                        fac = n.get('facing', 'any')
                        b = F.examine_entry(n['x'], n['y'], sidx, fac)
                        what = f"examine spot ({n['x']},{n['y']}) facing {fac}"
                    else:
                        b = F.step_trigger_entry(n['x'], n['y'], sidx)
                        what = f"step-on trigger ({n['x']},{n['y']})"
                    out.append(F.db_line(b, comment=f"{what} script {sid}"))
                else:
                    sid = n['script']
                    sidx = (0xFF if sid in (None, 'none')
                            else sid if isinstance(sid, int)   # S97: raw index kept
                            else prj.script_index(r, sid))
                    b = F.npc_entry(n.get('facing', 'down'), prj.npc_sprite(r, i, n),
                                    n['x'], n['y'], sidx,
                                    behaviour=n.get('behaviour', 0),
                                    hidden=bool(n.get('hidden', False)))
                    out += _npc_cond_lines(prj.npc_conditions(r, i, n))
                    out += _npc_colour_lines(prj.npc_colour(r, i, n))
                    out.append(F.db_line(
                        b, comment=f"NPC ({n['x']},{n['y']}) script "
                                   f"{sid if sid not in (None,'none') else 'none'}"))
            out.append("    db $FF")
            out.append("")
            out.append(f"{tag}_S{i}{sfx}_Exits:")
            for e in st.get('exits', []):
                dest = prj.resolve_dest(e['dest'])
                what = (f"door '{e.get('name') or e['door']}'" if e.get('door')
                        else 'stairs down (next gate floor)' if e.get('stairs')
                        else f'gate entrance (gate {dest})'
                        if F.val(e.get('gate_flag', 0)) == 1 else 'exit')
                out += _exit_lines(prj, r, e, e.get('comment',
                                   f"{what} ({e['x']},{e['y']}) -> {e['dest']}"))
            out.append("    db $FF")
            out.append("")
    return out


# ---------------------------------------------------------------------------
# bank $71 emitter — dispatch tables (owns file patches/bank_071.asm)
# ---------------------------------------------------------------------------

def emit_bank_071(prj, warnings):
    lines = [template('bank_071_head.asm').rstrip('\n'), ""]
    lines += prj.place_number_block('71') + [""]
    lines += ["; " + "-" * 77,
              "; Custom26DDTable — 8-byte $26DD-style records, one per PLACE in",
              "; place-number order (S140, ARC CAP3a; S94-S139: $6B-$6F in ROM0 $2A35,",
              "; this table from $70): [step_id, gfx_bank, w_lo, w_hi, h_lo,",
              ";  h_hi, threshold, pad] (generated by build_project.py).",
              "; " + "-" * 77,
              "Custom26DDTable:"]
    for r in prj.rooms:
        mid = F.val(r['mapID'])
        if r.get('placeholder'):
            # S92: synthesized dense-sequence placeholder (a declared room
            # above it exists). The row must occupy its place-number slot;
            # all-zero = unused shape (gfx 0, 0x0, threshold 0) — the room
            # is unreachable (no exits target a placeholder).
            lines.append(F.db_line([0] * 8,
                         comment=f"{F.hexb(mid)} placeholder (zero row)"))
            continue
        rec = r['record']
        gb, gid = prj.resolve_gfx(rec, ctx=f"room {r.get('id')} record")
        b = F.record_26dd(gid, gb,
                          F.val(rec['width_px']), F.val(rec['height_px']),
                          F.val(rec['collision_threshold']))
        lines.append(F.db_line(b, comment=F.hexb(mid)))
    lines.append("")
    lines += ["; " + "-" * 77,
              "; RoomEncTable — 3 bytes/place [enabled, gate_id, floor], indexed by",
              "; the place number (S140). enabled=0 -> encounter-silent. (generated)",
              "; " + "-" * 77,
              f"ENC_TABLE_LEN EQU {len(prj.rooms)}",
              "RoomEncTable:"]
    for r in prj.rooms:
        enc = r.get('encounters') or {}
        if enc.get('enabled') and enc.get('list') is not None:
            # S114 (P3.13a): the room's OWN list (bank $76 EncResolve picks it
            # by wMapID) — never pin a gate, inside a dive or outside one
            b = F.enc_row(True, 0xFF, 0)
            state = "enabled, its own list (bank $76)"
        elif enc.get('enabled') and enc.get('follow_gate'):
            # S100: gate byte $FF = use the dive's own gate/floor (entry 1
            # never pins) — for rooms served inside gates
            b = F.enc_row(True, 0xFF, 0)
            state = "enabled, follows the gate being dived"
        else:
            b = F.enc_row(enc.get('enabled', False),
                          F.val(enc.get('gate_id', 0)),
                          F.val(enc.get('floor', 0)))
            state = (f"enabled, gate {F.val(enc.get('gate_id',0))}, "
                     f"floor {F.val(enc.get('floor',0))}"
                     if enc.get('enabled') else "disabled")
        lines.append(F.db_line(b, comment=f"{F.hexb(F.val(r['mapID']))} — {state}"))
    lines.append("")
    lines += ["; " + "-" * 77,
              "; CustomAnimSrcTable — 1 byte/place (place number, S140): the map ID",
              "; whose bank-$01 room-animation handler runs for this room ($6B =",
              "; none). Read by entry 3 CustomAnimSource (S99, P3.3e). (generated)",
              "; " + "-" * 77,
              f"ANIM_TABLE_LEN EQU {len(prj.rooms)}",
              "CustomAnimSrcTable:"]
    for r in prj.rooms:
        src, why = prj.anim_source(r)
        lines.append(F.db_line([src], comment=f"{F.hexb(F.val(r['mapID']))} — {why}"))
    lines.append("")
    lines += _gate_insert_table(prj)
    lines += _hub_table(prj)
    lines += ["; " + "-" * 77,
              "; CustomRoomFlagsTable — 1 byte/place (place number, S140): bit 0 =",
              "; saving NOT allowed (custom.rooms[].can_save false). Read by entry",
              "; 5 CustomRoomFlags for the bank $07 save ladder (S100). Bit 1 =",
              "; sprites stay drawn while a text box is open (text_keeps_sprites,",
              "; entry 8 TextSpriteMode, S121). Bit 7 = NO SUCH PLACE (a placeholder;",
              "; S138 StalePlace: CONTINUE sends a save there home, entry 0 reads the",
              "; Castle's record). (generated)",
              "; " + "-" * 77,
              f"ROOMFLAGS_TABLE_LEN EQU {len(prj.rooms)}",
              "CustomRoomFlagsTable:"]
    for r in prj.rooms:
        fl = prj.room_flags(r)
        lines.append(F.db_line([fl], comment=f"{F.hexb(F.val(r['mapID']))} — "
                     + ("NO SUCH PLACE (placeholder)" if fl & 0x80 else
                        ("no saving" if fl & 1 else "saving allowed")
                        + (", sprites over text" if fl & 2 else ""))))
    lines.append("")
    lines += ["; " + "-" * 77,
              "; CustomRoomBGMTable — the 107 VANILLA map ids $00-$6A / CustomPlaceBGMTable",
              "; — one row per PLACE, place-number order (S140, ARC CAP3a; S138-S139:",
              "; 256 rows by wMapID; S64-S137: 128). Read by entry 2 (CustomRoomBGMResolve",
              "; through RoomSongByte71) for the rewritten LoadNewBGMIdIntoA (patches/",
              "; bank_001.asm). 0 = no assignment -> vanilla derivation; nonzero = the",
              "; room's default BGM id (survives save/reload: the load path re-derives",
              "; here); $FF = a gate room with no song: the dive's gate song (S116).",
              "; Gate floors (wInGateworld!=0) are excluded by the resolver. (generated)",
              "; " + "-" * 77,
              f"PLACE_SONG_LEN EQU {len(prj.rooms)}",
              "CustomRoomBGMTable:"]
    room_bgm = prj.music_room_bgm(warnings)
    names = prj.music_song_ids()
    by_id = {v: k for k, v in names.items()}

    def _tag(v):
        return 'follow the gate' if v == M.FOLLOW_GATE else by_id.get(v, F.hexb(v))
    for i in range(0, M.VANILLA_ROWS, 16):
        row = room_bgm[i:min(i + 16, M.VANILLA_ROWS)]
        tags = [f"${i+j:02X}=" + _tag(v) for j, v in enumerate(row) if v]
        lines.append(F.db_line(row, comment=f"mapIDs ${i:02X}-${i + len(row) - 1:02X}"
                     + (": " + ", ".join(tags) if tags else "")))
    lines += M.place_song_lines(prj, "CustomPlaceBGMTable", room_bgm, _tag)
    lines.append("")
    lines += _gate_boss_region_lines(prj)
    lines += M.emit_bank_071_tables(prj, warnings)
    lines += prj.region_table_lines('71')
    return "\n".join(lines) + "\n"


def _gate_boss_region_lines(prj):
    """S140 (ROADMAP ARC CAP3a): GateBossRegionTable — per gate 0-95, the region
    of its boss room (0: vanilla boss rooms, region-0 places). Read by bank $71
    BossRegion71 (entries 11 / 12: the bank $16 boss floor, bank $76
    GateBossWin, the boss-room song)."""
    regs = [0] * 96
    try:
        for gid, c in prj.gate_configs().items():
            if 0 <= gid < 96:
                regs[gid] = c.get('boss_region', 0)
    except Exception:                                            # noqa: BLE001
        pass
    out = ["; S140 (ARC CAP3a): GateBossRegionTable — the region of each gate's boss room",
           "GateBossRegionTable:"]
    for i in range(0, 96, 16):
        out.append(F.db_line(regs[i:i + 16], comment=f"gates {i}-{i + 15}"))
    out.append("")
    return out


def _gate_insert_table(prj):
    """GateInsertTable (S100, P3.7b) — record layout in the bank $71 template
    (entry 4 CustomGateInsert); rules in custom.gate_inserts[] list order."""
    out = ["; " + "-" * 77,
           "; GateInsertTable — custom rooms served on gate floors (S100, P3.7b).",
           "; [gate, floor_lo, floor_hi (0-based), chance, once_bit, mapID, region",
           ";  (S140), spawn_x lo/hi, spawn_y lo/hi, n_terms] + n_terms x dw flag",
           "; (bit 15 = must be CLEAR); $FF ends. Read by entry 4. (generated)",
           "; " + "-" * 77,
           "GateInsertTable:"]
    for row in prj.gate_insert_rows():
        b = [row['gate'], row['first'] - 1, row['last'] - 1, row['chance_byte'],
             row['once_bit'], F.mid_real(row['mapID']), F.mid_region(row['mapID']),
             row['px'] & 0xFF, row['px'] >> 8, row['py'] & 0xFF, row['py'] >> 8,
             len(row['terms'])]
        what = (("every gate" if row['gate'] == 0xFE else f"gate {row['gate']}")
                + f" floors {row['first']}-" + ("boss-1" if row['last'] > 255 else str(row['last']))
                + (f" {row['chance']}%" if row['chance_byte'] < 0x80 else
                   f" chance by level (row {row['chance_byte'] & 0x7F})")
                + f" -> {row['room_id']} ({F.hexb(row['mapID'])})"
                + (" once/dive" if row['once_bit'] else ""))
        out.append(F.db_line(b, comment=what))
        for idx, clr in row['terms']:
            out.append(f"    dw ${idx | (0x8000 if clr else 0):04X}   ; flag "
                       f"{F.hexw(idx)} must be {'clear' if clr else 'set'}")
    out.append("    db $FF")
    out.append("")
    from . import breeders as BR              # S127: GATE_ANY + ScaledChanceTable
    out += BR.emit_chance_lines(prj)
    out.append("")
    return out


def _hub_table(prj):
    """HubTable (S125, ROADMAP P3.14d) — record layout in the bank $71 template
    (entry 9 HubWarp); rules in custom.hub.rules[] list order."""
    out = ["; " + "-" * 77,
           "; HubTable — where the game sends the player home (S125, P3.14d).",
           "; [n_terms] + n_terms x dw flag (bit 15 = must be CLEAR) + [mapID,",
           ";  region (S140), spawn_x lo/hi, spawn_y lo/hi]; mapID 0 = the Castle (the vanilla",
           ";  arrival codes); $FF ends; no rule holds -> the Castle. Read by",
           ";  entry 9 HubWarp. (generated)",
           "; " + "-" * 77,
           "HubTable:"]
    for ru in prj.hub_rules():
        out.append(F.db_line([len(ru['terms'])],
                   comment=f"rule {ru['index'] + 1}: "
                   + ('always' if not ru['terms'] else f"{len(ru['terms'])} flag term(s)")
                   + (f" — {ru['comment']}" if ru.get('comment') else '')))
        for idx, clr in ru['terms']:
            out.append(f"    dw ${idx | (0x8000 if clr else 0):04X}   ; flag "
                       f"{F.hexw(idx)} must be {'clear' if clr else 'set'}")
        what = ('the Castle (vanilla)' if ru['castle'] else
                f"{ru['room_id']} screen {ru['screen']} ({ru['x']},{ru['y']})")
        out.append(F.db_line([F.mid_real(ru['mapID']), F.mid_region(ru['mapID']),
                              ru['px'] & 0xFF, ru['px'] >> 8,
                              ru['py'] & 0xFF, ru['py'] >> 8],
                             comment=f"-> {F.hexb(ru['mapID'])} {what}"))
    out.append("    db $FF")
    out.append("")
    return out


# ---------------------------------------------------------------------------
# bank $17 region emitters — per-room render tables + palette blocks
# ---------------------------------------------------------------------------

def _palette_asm(prj, pal):
    out = [f"{pal['label']}:"]
    rows = pal['colors_rgb555']
    cmts = pal.get('row_comments') or [None] * 8
    if pal.get('free_color1'):
        # S96: FreeColor1Hook (patches/bank_017.asm) keeps this palette's own
        # colour 1 in each of slots 0-3 whose colour 3 carries bit 15 (ignored
        # by the hardware; colour 3 is forced black anyway). Per slot and
        # kept in the WRAM buffer, so the field menu's standalone palette
        # re-force leaves it alone (S96 round 4).
        rows = [list(r) for r in rows]
        for s in range(4):
            rows[s][3] = F.val(rows[s][3]) | 0x8000
    for row, cm in zip(rows, cmts):
        b = F.palette_row(row)
        out.append(F.db_line(b, comment=cm))
    return out


def emit_region_palettes_a(prj, warnings):
    """S137 (ROADMAP ARC CAP2c): empty — every project palette now lives with
    the rooms that use it, in their home bank (render_lines below). The
    region stays so a bank_017.asm of any age still splices."""
    return "; (S137: the project's palettes live in the rooms' home banks — places.py)\n"


def palette_slots_asm(pal, label):
    """S137: the 32 B a place bank keeps of a project palette — slots 0-3,
    the only ones the game loads (CustomPalCheck b = 4; LoadPal_46a1). The S96
    free-colour-1 marker (colour 3 bit 15) is set as before."""
    out = [f"{label}:   ; palette {pal['id']} (slots 0-3)"]
    rows = pal['colors_rgb555'][:4]
    cmts = (pal.get('row_comments') or [None] * 8)[:4]
    if pal.get('free_color1'):
        rows = [list(r) for r in rows]
        for s_ in range(4):
            rows[s_][3] = F.val(rows[s_][3]) | 0x8000
    for row, cm in zip(rows, cmts):
        out.append(F.db_line(F.palette_row(row), comment=cm))
    return out


def room_holes(r):
    """S135: screen numbers inside a room's size (record width / height, the
    4-wide screen grid) that the room does not define — the player can walk into
    them. Rooms without a record (legacy $6B-$6F) report none."""
    rec = r.get('record') or {}
    screens = {int(k) for k in (r.get('screens') or {})}
    if not screens or 'width_px' not in rec or 'height_px' not in rec:
        return []
    cols = max(1, F.val(rec['width_px']) // 160)
    rows = max(1, F.val(rec['height_px']) // 128)
    return [row * 4 + c for row in range(min(rows, 4)) for c in range(min(cols, 4))
            if row * 4 + c not in screens]


def render_lines(prj, r, warnings):
    """S137 (ROADMAP ARC CAP2c): a place's render tables + palettes, part of its
    BLOCK in its home bank (places.room_block). Read by the home bank's
    CustomRenderCopy (place_readers.asm entry 13) for bank $17 CustomAttrCheck:

        RoomAttr_<mid>:     16 x dw (screen 0-15) -> ScrAttr_<mid>_<k> ($0000 = absent)
        ScrAttr_<mid>_<k>:  dw <step counter label>, db n_states,
                            per state: db attr_entry, attr_bank / dw pal_ptr
        RPal_<mid>_<n>:     32 B (slots 0-3) per project palette the room uses

    pal_ptr = a palette block of this bank, or a vanilla palette in BANK $17
    with bit 15 set (a borrow: the walk reads it there). Returns (lines,
    'RoomAttr_<mid>') — or ([], None) for a placeholder / screenless room (the
    Castle fallback, as before). (S94b-S136: the same tables in bank $17,
    without n_states, region room_render_tables.)"""
    mid = F.val(r['mapID'])
    screens = prj.room_screens(r)
    if r.get('placeholder') or not screens:
        return [], None
    label = f"RoomAttr_{mid:02X}"
    holes = room_holes(r)
    if holes:
        warnings.append(
            f"room {r.get('id')}: screen(s) {', '.join(str(k) for k in holes)} lie "
            "inside the room's size but were never made — walking into one shows "
            "stray tiles (the game's placeholder screen). Add them, or make the "
            "room smaller (S135: they used to CRASH the game — measured; they now "
            f"borrow screen {min(screens)}'s colours)")
    row = []
    for k in range(16):
        if k in screens:
            row.append(f"ScrAttr_{mid:02X}_{k}")
        elif k in holes:
            # S135: a screen inside the room's size gets a real row (the old
            # bank $17 walk crashed on $0000; S137's reader would fall back
            # to the Castle's colours instead — the room's own look is better)
            row.append(f"ScrAttr_{mid:02X}_{min(screens)}")
        else:
            row.append("$0000")
    out = [f"{label}:    ; {r.get('id')}: render rows, screen 0-15 (S137, CAP2c)"]
    for i in range(0, 16, 4):
        out.append("    dw " + ", ".join(row[i:i + 4]))
    pals = {}                                   # palette id -> (label, pal)
    for k in sorted(screens):
        s_ = screens[k]
        states = prj.screen_states(s_)
        ctr = prj.step_counter_label(r, k, s_)
        out += [f"ScrAttr_{mid:02X}_{k}:", f"    dw {ctr}    ; step counter",
                f"    db {len(states)}    ; states"]
        for n in range(len(states)):
            ae = prj.state_attr_entry(r, k, n, ctx=f"room {r.get('id')} screen {k} state {n}")
            if ae is None:
                raise ValueError(
                    f"room {r.get('id')} screen {k} state {n}: no attr grid "
                    "resolves (states[].attr / layout item attr / render.attr)")
            kind, pal = prj.state_palette_ref(r, k, n)
            if kind == 'palette':
                pid = pal
                if pid not in pals:
                    pals[pid] = (f"RPal_{mid:02X}_{len(pals)}", prj._pal_by_id[pid])
                pal_s, why = pals[pid][0], f"palette {pid}"
            else:
                pal_s, why = (F.hexw(pal | 0x8000),
                              f"vanilla source palette ${pal:04X} in bank $17 (borrow, bit 15)")
            out.append(f"    db {F.hexb(ae[1])}, {F.hexb(ae[0])}    ; state {n}: attr entry, bank")
            out.append(f"    dw {pal_s}    ; state {n}: {why}")
    for lbl, pal in pals.values():
        out += palette_slots_asm(pal, lbl)
    out.append("")
    return out, label


def emit_region_render_tables(prj, warnings):
    """S137 (ROADMAP ARC CAP2c): empty — a room's render rows and palettes are
    part of its place block (render_lines; places.room_block), read through
    bank $60 entry 13. The region stays so any bank_017.asm still splices."""
    return ("; S137 (ROADMAP ARC CAP2c): the rooms' render rows + palettes live in\n"
            "; their home banks (places.py); bank $17 CustomAttrCheck far-calls bank\n"
            "; $60 entry 13 for them. Nothing is generated here any more.\n")


# ---------------------------------------------------------------------------
# wram region emitter — custom step counters ($CD80+, CF3-freed window, S65;
# ROOM_DATA_FORMAT "Room State System": NOT SRAM-persistent — the CF3 save
# copy skips the window's SRAM image $A3BA-$AD9E in both directions)
# ---------------------------------------------------------------------------

def emit_region_wram_steps(prj, warnings):
    """Step-counter labels at exact addresses inside the fixed-size region
    ($CD80.. inside the CF3-freed window $CC80-$D664 — see patches/wram.asm
    banner; TRANSIENT by construction). Holes between explicit addresses
    become `ds` fillers so every label lands at its declared address; the
    region is padded to its fixed size so its footprint (and everything the
    section places after it) is layout-stable; region end is capped at $D000
    (wram0 section boundary, validated in project.py)."""
    from .project import STEP_COUNTER_BASE
    alloc = prj.step_counter_allocation()      # ordered [(label, addr, cm)]
    size = prj.wram_region_size
    out, cursor = [], STEP_COUNTER_BASE
    for label, addr, cm in alloc:
        if addr > cursor:
            out.append(f"    ds {addr - cursor} ; reserved hole "
                       "(explicit addresses above leave a gap)")
        out.append(f"{label}:: db ;{addr:04x} — {cm}")
        cursor = addr + 1
    end = STEP_COUNTER_BASE + size
    if cursor < end:
        out.append(f"    ds {end - cursor} ; reserved (padded to region_size; "
                   "region ends at $D000 — PROJECT_COMPILER.md §2.6)")
    # S118c: screens of cloned rooms that follow the game's own room state —
    # the label IS the original room's counter (no byte here; saved by the game)
    for label, addr, cm in prj.step_counter_game():
        out.append(f"{label} EQU ${addr:04X} ; {cm}")
    # S140 (ROADMAP ARC CAP3a): the regional area (bank $73 RegionEnter zeroes
    # wCustomStepRegional .. $CFFF on a region change) + the other regions'
    # counters at the same addresses
    overlay, base = prj.step_counter_overlay()
    out.append(f"wCustomStepRegional EQU ${base:04X} ; S140: the regions' shared counters start here")
    for label, addr, cm in overlay:
        out.append(f"{label} EQU ${addr:04X} ; {cm}")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------
# bank $74 emitter — custom song bank (owns file patches/bank_074.asm)
# ---------------------------------------------------------------------------

def emit_bank_074(prj, warnings):
    """The first song bank: project songs (library refs / inline / files) ->
    the proven song_codec emit path (fixed 95-slot record area, streams from
    $4180). Deterministic: a pure function of project.json + the referenced
    library JSONs (repo-committed extracted/ data) + project song files."""
    P = prj.music_plan()
    warnings += [w for w in P.warnings if w not in warnings]
    return M.song_bank_asm(prj, 0x74)


def emit_bank_075(prj, warnings):
    """S116: the second song bank (the songs past bank $74's 16,000 stream
    bytes, from the split id; AudioMasterTableExt row 5). All zero but the bank
    byte when nothing spills."""
    return M.song_bank_asm(prj, 0x75)


def emit_region_audio_master(prj, warnings):
    return M.emit_region_master_table(prj, warnings)


# ---------------------------------------------------------------------------
# Project enemy rows (S101; was the S70 bank-$14 12-row tail region)
#   file:patches/bank_06b.asm           — template head + the 25-byte rows
#   region:patches/bank_014.asm#boss_redirects — BossRedirectTableExt
# ---------------------------------------------------------------------------

# The 34 vanilla BossRedirectTable pairs ($14:$4893, fight EID -> join EID),
# in ROM order. The rewritten LookupBossRedirect scans BossRedirectTableExt =
# project rows FIRST, then these, then $FFFF (test_compiler --rom checks this
# list against the ROM bytes).
VANILLA_REDIRECTS = [
    (4, 486), (11, 12), (31, 484), (32, 485), (51, 52), (53, 54), (55, 56),
    (75, 76), (77, 78), (79, 80), (99, 100), (101, 102), (103, 104),
    (123, 124), (125, 126), (127, 128), (147, 148), (149, 150), (153, 154),
    (175, 176), (177, 178), (179, 180), (199, 200), (201, 202), (203, 204),
    (205, 206), (207, 208), (209, 210), (211, 212), (213, 214), (215, 216),
    (217, 218), (219, 220), (221, 222)]


def enemy_row_bytes(e):
    """progression.enemies item -> the 25-byte enemy-stats row (MONSTER_DATA
    "Enemy Stats Table"): [species, exp:2, joinability, level, hp:2, mp:2,
    atk:2, def:2, agl:2, int:2, ai:4, skills:4]."""
    sp, lv = F.val(e['species']), F.val(e['level'])
    exp = F.val(e.get('exp', 0))
    join = F.val(e.get('joinability', 7))
    row = [sp, exp & 0xFF, (exp >> 8) & 0xFF, join, lv]
    for f16 in ('hp', 'mp', 'atk', 'def', 'agl', 'int'):
        v = F.val(e.get(f16, 0))
        row += [v & 0xFF, (v >> 8) & 0xFF]
    ai = [F.val(x) for x in e.get('ai_weights', [0, 0, 0, 0])]
    sk = [F.val(x) for x in e.get('skills', [])]
    row += (ai + [0] * 4)[:4] + (sk + [0xFF] * 4)[:4]
    return row


def emit_bank_06b(prj, warnings):
    from .project import PROJECT_EID_BASE
    rows = prj.quest_enemy_rows()
    lines = [template('bank_06b_head.asm').rstrip('\n'), ""]
    lines += ["; " + "-" * 77,
              "; ProjectEnemyRows — progression.enemies, row = EID - 519 (generated",
              "; by build_project.py; S101). An empty project keeps one zero row.",
              "; " + "-" * 77,
              f"PROJECT_EID_BASE EQU {PROJECT_EID_BASE}",
              f"PROJECT_ENEMY_ROWS EQU {max(1, len(rows))}",
              "ProjectEnemyRows:"]
    if not rows:
        lines.append(F.db_line([0] * 25, comment="(no project enemies)"))
    for e in rows:
        b = enemy_row_bytes(e)
        what = (f"EID {e['_eid']} {e['id']} — species {b[0]} L{b[4]}, "
                f"joinability {b[3]}")
        if e.get('join_as') is not None:
            what += f", joins as {e.get('join_as')}"
        lines.append(f"ProjectEnemy_{e['_eid']}:   ; {what}")
        lines.append(F.db_line(b))
    return "\n".join(lines) + "\n"


def emit_bank_06c(prj, warnings):
    """S102: own tile animations (custom.rooms[].tile_anims). S139 (ROADMAP ARC
    CAP2d): bank $6C = the forwarder head + TileAnimDirectory + the player and
    the rooms that fit; the rest go to animation banks $80+ (tileanim.plan,
    emit_anim_banks). Record layout: templates/tileanim_player.asm."""
    from . import tileanim as TA
    return TA.emit_bank_06c(prj, warnings)


def emit_anim_banks(prj, warnings):
    """S139 (ARC CAP2d): one whole file per animation bank $80+."""
    from . import tileanim as TA
    return TA.emit_anim_banks(prj, warnings)


def emit_region_redirects14(prj, warnings):
    out = ["; BossRedirectTableExt (S101): fight EID -> join EID, scanned by the",
           "; rewritten LookupBossRedirect (bank $14 entry 6). Project rows first",
           "; (progression.enemies[].join_as), then the 34 vanilla rows, then",
           "; $FFFF. Generated by editor2 `redirects14`; the pad fills the bank.",
           "BossRedirectTableExt:"]
    for fight, join, name in prj.enemy_redirects():
        out.append(f"    dw {fight}, {join}   ; project: {name}")
    # S103: the vanilla 34 as gamedata.boss_joins leaves them (== ROM when unedited)
    gd = prj.gamedata()
    for fight, join in gd.redirects:
        edited = "   ; gamedata.boss_joins" if fight in gd.edited['redirect'] else ""
        out.append(f"    dw {fight}, {join}{edited}")
    out.append("    dw $FFFF, $0000")
    out.append("    ds $8000 - @, $00")
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------
# bank $16 region emitter — GateFloorDataTable (S101, custom.gates[])
# ---------------------------------------------------------------------------

def emit_region_gates16(prj, warnings):
    """custom.gates[] -> the 32 x 8-byte GateFloorDataTable ($16:$70A6, read by
    entry 5: bytes 0-2 floor-type rows, 3 floor count incl. the boss floor,
    4 boss map, 5/6 boss arrival TILE, 7 depth tier — GATE_GENERATION §1).
    Untouched gates = the vanilla row bytes (extracted/gate_names.json 'row',
    tools/map_gate_names.py), so an empty custom.gates is byte-identical."""
    out = ["; (generated by editor2 `gates16` from custom.gates[] — vanilla rows until edited)",
           "GateFloorDataTable:"]
    for gid, c in sorted(prj.gate_configs().items()):
        if gid >= 32:
            continue                # S115: new gates' rows live in bank $76 (enc76)
        why = f"{c['name']} (last floor: {c['floors']})"
        if c['edited']:
            bits = []
            if c['boss_room']:
                bits.append(f"boss room {c['boss_room']} ({F.hexb(c['boss_map'])}) "
                            f"arrival tile {c['spawn']}")
            if c['hand_made']:
                bits.append("hand-made floors")
            why += " — EDITED: " + ("; ".join(bits) if bits else "settings")
        out.append(F.db_line(c['row'], comment=why))
    return "\n".join(out) + "\n"


# ---------------------------------------------------------------------------
# bank $64 emitter — layouts + attr maps (owns file patches/bank_064.asm)
# P3.2 [G-A], S92. Entry allocation lives in Project (declaration order,
# tiles-then-attr per item) so room references resolve before emission.
# ---------------------------------------------------------------------------

def _stream_block(label, data, comment):
    out = [f"{label}:  ; {comment}"]
    for i in range(0, len(data), 16):
        out.append("    db " + ", ".join(f"${b:02X}" for b in data[i:i + 16]))
    return out


def _stream_bank_body(prj, bank):
    """S135: self-ID byte + pointer table + the streams the plan put in `bank`."""
    out = [f"    db ${bank:02X}  ; bank self-ID"]
    items = prj.stream_plan()['banks'].get(bank, [])
    for e, (key, lbl, data, cm) in enumerate(items):
        out.append(f"    dw {lbl}   ; entry {e}")
    out.append("")
    for key, lbl, data, cm in items:
        if cm is None:
            cm = (f"{len(data)} bytes compressed (2048 decompressed)"
                  if key[0] == 'tileset' else f"{key[0]} {key[1]} (LZSS)")
        out += _stream_block(lbl, data, cm)
        out.append("")
    return out


def emit_bank_064(prj, warnings):
    out = banner("BANK $64 — custom room layouts + attr maps (generated)", [
        "Generated by build_project.py from custom.layouts[] — the P3.2",
        "[G-A] fold. Entries in declaration order (tiles, then attr, per",
        "item); S135 (ARC CAP2a): first fit — what does not fit here goes",
        "to an overflow bank $80+ (bank_0xx.asm, editor2/core/project.py",
        "stream_plan). Every reference carries its bank: the room step",
        "[entry, bank] and the bank $17 render rows [attr_entry, attr_bank].",
        "Engine reads via DecompressTileLayout ($1627): D=bank, E=entry.",
        "Formats: ROOM_DATA_FORMAT / GATE_GENERATION §7.2; LZSS via",
        "tools/compress_tiles.py (deterministic — byte-identity regression)."])
    out.append('SECTION "ROM Bank $064", ROMX[$4000], BANK[$64]')
    out += _stream_bank_body(prj, 0x64)
    return "\n".join(out).rstrip("\n") + "\n"


def emit_bank_067(prj, warnings):
    out = banner("BANK $67 — custom tileset GFX (generated)", [
        "Generated by build_project.py from custom.tilesets[] — the P3.2",
        "[G-A] fold of the S6-S10 multi-tileset import pipeline. Each entry",
        "= 2048-byte 2bpp sheet (128 tiles), LZSS. Sources: committed",
        "raw2bpp sheets, or a multi-tileset editor-export spec resolved via",
        "tools/build_combined_tileset.py's cherry-pick core. Loaded by",
        "DecompressTileLayout via a room record's gfx_bank/gfx_id",
        "(ROOM_DATA_FORMAT 'Tileset Graphics System'). S135 (ARC CAP2a):",
        "first fit — what does not fit here goes to an overflow bank $80+."])
    out.append('SECTION "ROM Bank $067", ROMX[$4000], BANK[$67]')
    out += _stream_bank_body(prj, 0x67)
    return "\n".join(out).rstrip("\n") + "\n"


def stream_bank_file(bank):
    return f"bank_{bank:03x}.asm"


def emit_stream_banks(prj, warnings):
    """S135 (ROADMAP ARC CAP2a): the overflow banks $80+ of the LZ streams —
    layouts / attr maps / tilesets that did not fit bank $64 / $67 (first fit,
    project.stream_plan). One whole file per bank (INCLUDEd by bank_ext.asm).
    Returns {target: text} (a 'multi:' registry entry): none for a project
    whose streams fit their home banks."""
    out = {}
    for b in prj.stream_plan()['overflow']:
        lines = banner(f"BANK ${b:02X} — overflow LZ streams (generated, S135)", [
            "Layouts, attr maps and tilesets that did not fit bank $64 / $67",
            "(ROADMAP ARC CAP2a; editor2/core/project.py stream_plan, first",
            "fit). Same format as those banks: self-ID byte (load-bearing —",
            "the frame's audio swap saves the bank by reading [$4000] while",
            "a stream decodes), pointer table at $4001, LZSS streams.",
            "Generated by build_project.py — do not hand-edit."])
        lines.append(f'SECTION "ROM Bank ${b:03X}", ROMX[$4000], BANK[${b:02X}]')
        lines += _stream_bank_body(prj, b)
        out[f"file:patches/{stream_bank_file(b)}"] = \
            "\n".join(lines).rstrip("\n") + "\n"
    return out



# ---------------------------------------------------------------------------
# ROM0 region emitter — $26DD records for mapIDs $6B-$6F (S94). The vanilla
# table's rows $6B-$6F are filler (12 24 A0 00 80 00 50 00); CopyCustomRoomRecord
# (bank $71 entry 0) reads THESE rows for mapID < $70 and Custom26DDTable
# above. Making them compiler-owned lets every custom room carry a `record`
# (previously $6B-$6F were hand-patched in bank_000 — PROJECT_STATE S94).
# Labels inside the window are `jr` targets in the surrounding misassembled
# data and must keep their addresses: $2A38, $2A3D, $2A40 (x2), $2A48,
# $2A56, $2A58, $2A59.
# ---------------------------------------------------------------------------

ROM0_FILLER = [0x12, 0x24, 0xA0, 0x00, 0x80, 0x00, 0x50, 0x00]
ROM0_LABELS = {0x2A38: ["Data_2A38"], 0x2A3D: ["DataTable_2A3D"],
               0x2A40: ["DataLookup_2A40Alias", "DataLookup_2A40"],
               0x2A48: ["Data_2A48"], 0x2A56: ["DataTable_2A56"],
               0x2A58: ["Data_2A58"], 0x2A59: ["DataLookup_2A59"]}
ROM0_BASE = 0x26DD


def emit_region_rom0_records(prj, warnings):
    """S140 (ROADMAP ARC CAP3a): the ORIGINAL bytes again. S94-S139 put the
    records of map ids $6B-$6F here (bank $71 entry 0 read ROM0 below $70); with
    regions a $6B is not always region 0's, so every place's record is in bank
    $71 Custom26DDTable (place number) and these five rows are the vanilla
    filler they were in the original game."""
    out = ["; $26DD rows of map ids $6B-$6F ($2A35-$2A5C, 8 B each) — the original",
           "; filler (12 24 A0 00 80 00 50 00). S94-S139 the compiler put the records",
           "; of places $6B-$6F here; S140 (ROADMAP ARC CAP3a — regions): every place's",
           "; record is in bank $71 Custom26DDTable, indexed by its place number.",
           "; Labels inside the window are jr targets and stay put."]
    for mid in range(0x6B, 0x70):
        b = list(ROM0_FILLER)
        why = f"{F.hexb(mid)} (vanilla filler)"
        base = ROM0_BASE + mid * 8
        # split the row at label addresses so labels keep their bytes
        cuts = sorted({0} | {a - base for a in ROM0_LABELS if base < a < base + 8})
        first = True
        for i, c in enumerate(cuts):
            if c in {a - base for a in ROM0_LABELS} and c != 0 or (c == 0 and base in ROM0_LABELS):
                for lab in ROM0_LABELS[base + c]:
                    out.append(f"{lab}:")
            nxt = cuts[i + 1] if i + 1 < len(cuts) else 8
            out.append(F.db_line(b[c:nxt], comment=why if first else None))
            first = False
    return "\n".join(out) + "\n"

# ---------------------------------------------------------------------------
# S103 (P3.9) Layer A-lite: the vanilla data tables as compiler-owned regions
# (editor2/core/gamedata.py; PROJECT_COMPILER §2.20). Every region is the same
# size as the vanilla table it replaces; an empty `gamedata` == the ROM bytes.
# ---------------------------------------------------------------------------

def _gd(fn, *a):
    def emit(prj, warnings):
        from . import gamedata as G
        return getattr(G, fn)(prj.gamedata(), *a)
    emit.__name__ = f"emit_{fn}"
    return emit


def _sp(fn):
    def emit(prj, warnings):
        from . import species as SP
        return getattr(SP, fn)(prj, warnings)
    emit.__name__ = f"emit_{fn}"
    return emit


def emit_bank_077(prj, warnings):
    """S117 (P3.13c): bank $77 = ShopFill (template bank_077_head.asm) + the
    shop lists (editor2/core/shops.py, PROJECT_COMPILER §2.32)."""
    from . import shops as SH
    return SH.emit_bank_077(prj, warnings, template('bank_077_head.asm'))


def emit_bank_076(prj, warnings):
    from . import encounters as EN
    return EN.emit_bank_076(prj, warnings, template('bank_076_head.asm'))


# ---------------------------------------------------------------------------
# S134 (ROADMAP ARC CAP1): the 4 MB ROM — banks $80-$FF.
# Every build is 4 MB: patches/game.asm INCLUDEs patches/bank_ext.asm, which
# gives EVERY bank $80-$FF a section whose first byte is the bank's own number
# (rst $10, AudioSaveBankState and the text engine save "the current bank" by
# READING [$4000] — ARCHITECTURE "ROM banks $80-$FF (S133)"); a bank whose
# content another emitter produces (ARC CAP2 place banks) is INCLUDEd instead
# — that file must start with its own `db <bank>` (tools/validate_custom_data.py
# checks every bank of the built ROM). The section in bank $FF is what makes
# rgbfix pad to 4 MB and write $0148 = $07.
# ---------------------------------------------------------------------------
EXT_BANK_FIRST, EXT_BANK_LAST = 0x80, 0xFF


def ext_bank_files(prj):
    """Banks $80-$FF whose WHOLE content a compiler emitter writes (bank ->
    'bank_0xx.asm'). S135 (ARC CAP2a): the LZ stream overflow banks; ARC
    CAP2b adds the place banks; S139 (CAP2d) the animation banks."""
    from . import places as PL
    out = {b: stream_bank_file(b) for b in prj.stream_plan()['overflow']}
    out.update({b: PL.place_bank_file(b) for b in PL.plan(prj)['overflow']})
    from . import tileanim as TA                       # S139 (ARC CAP2d)
    out.update({b: TA.anim_bank_file(b) for b in TA.plan(prj)['overflow']})
    return out


def emit_bank_ext(prj, warnings):
    owned = ext_bank_files(prj)
    out = ["; =============================================================================",
           "; bank_ext.asm — banks $80-$FF of the 4 MB ROM (S134, ROADMAP ARC CAP1)",
           "; GENERATED by tools/build_project.py (editor2/core/emitters.py emit_bank_ext)",
           "; from editor2/example-project — do not hand-edit.",
           "; Every bank starts with its OWN NUMBER at $4000: rst $10, the audio bank swap",
           "; and the text engine save the current bank by reading [$4000] (ARCHITECTURE",
           '; "ROM banks $80-$FF (S133)"). A bank with compiler content is INCLUDEd; the',
           "; rest are one-byte stubs (unused space, $00-filled by rgblink, the tail of",
           "; bank $FF padded by rgbfix to 4 MB).",
           "; ============================================================================="]
    for b in range(EXT_BANK_FIRST, EXT_BANK_LAST + 1):
        if b in owned:
            out.append(f'INCLUDE "{owned[b]}"')
        else:
            out.append(f'SECTION "ROM Bank ${b:03X}", ROMX[$4000], BANK[${b:02X}]')
            out.append(f"    db ${b:02X}                          ; bank self-ID at $4000")
    return "\n".join(out) + "\n"


REGISTRY = [
    # (name, schema_section, target, function, owned_banks)
    ("rooms60", "custom.rooms", "file:patches/bank_060.asm",
     emit_bank_060, [0x60]),
    # S134 (ARC CAP1): banks $80-$FF — self-ID stubs (+ CAP2's place banks)
    ("ext_banks", "custom.rooms", "file:patches/bank_ext.asm",
     emit_bank_ext, list(range(EXT_BANK_FIRST, EXT_BANK_LAST + 1))),
    # S136 (ARC CAP2b): places + text sections past bank $60 — whole files
    # bank_0xx.asm, one per place bank (none when everything fits $60)
    ("places_ext", "custom.rooms", "multi:place_banks",
     emit_place_banks, list(range(EXT_BANK_FIRST, EXT_BANK_LAST + 1))),
    ("layouts64", "custom.layouts", "file:patches/bank_064.asm",
     emit_bank_064, [0x64]),
    ("tilesets67", "custom.tilesets", "file:patches/bank_067.asm",
     emit_bank_067, [0x67]),
    # S135 (ARC CAP2a): layouts / attr maps / tilesets past $64 / $67 —
    # whole files bank_080.asm …, one per overflow bank (none when they fit)
    ("streams_ext", "custom.layouts", "multi:stream_banks",
     emit_stream_banks, list(range(EXT_BANK_FIRST, EXT_BANK_LAST + 1))),
    ("enemies6b", "progression.enemies", "file:patches/bank_06b.asm",
     emit_bank_06b, [0x6B]),
    ("tileanim6c", "custom.rooms", "file:patches/bank_06c.asm",
     emit_bank_06c, [0x6C]),
    # S139 (ARC CAP2d): rooms' own animations past bank $6C — whole files
    # bank_0xx.asm, one per animation bank (none when they fit $6C)
    ("anims_ext", "custom.rooms", "multi:anim_banks",
     emit_anim_banks, list(range(EXT_BANK_FIRST, EXT_BANK_LAST + 1))),
    ("redirects14", "progression.enemies",
     "region:patches/bank_014.asm#boss_redirects", emit_region_redirects14,
     [0x14]),
    ("gates16", "custom.gates", "region:patches/bank_016.asm#gate_floor_table",
     emit_region_gates16, [0x16]),
    ("dispatch71", "custom.rooms", "file:patches/bank_071.asm",
     emit_bank_071, [0x71]),
    ("palettes_a", "custom.palettes",
     "region:patches/bank_017.asm#room_palettes_a", emit_region_palettes_a,
     [0x17]),
    ("render17", "custom.rooms",
     "region:patches/bank_017.asm#room_render_tables",
     emit_region_render_tables, [0x17]),
    ("rom0_records", "custom.rooms",
     "region:patches/bank_000.asm#rom0_room_records",
     emit_region_rom0_records, [0x00]),
    ("wram_steps", "custom.rooms",
     "region:patches/wram.asm#wram_step_counters", emit_region_wram_steps,
     []),
    ("music74", "custom.music", "file:patches/bank_074.asm",
     emit_bank_074, [0x74]),
    # S116 (P3.13b): the second song bank + the master-table rows that reach it
    ("music75", "custom.music", "file:patches/bank_075.asm",
     emit_bank_075, [0x75]),
    ("audio_master", "custom.music",
     "region:patches/bank_000.asm#rom0_audio_master", emit_region_audio_master,
     [0x00]),
    # S114 (P3.13a): which encounter list a battle draws from — bank $76
    # EncResolve (template bank_076_head.asm) + the project's own lists, the
    # rooms' lists / variants / rates and the gates' plans (editor2/core/
    # encounters.py, PROJECT_COMPILER §2.30). No data == the vanilla rule.
    ("enc76", "custom.encounter_lists", "file:patches/bank_076.asm",
     emit_bank_076, [0x76]),
    # S117 (P3.13c): SHOPS — bank $77 ShopFill + every shop list (the five
    # vanilla lists, edited or not, + custom.shops) and the item records'
    # prices (region gd_item_info, bank $03). No data == the vanilla shops.
    ("shops77", "custom.shops", "file:patches/bank_077.asm",
     emit_bank_077, [0x77]),
    ("gd_monsters", "gamedata.monsters",
     "region:patches/bank_003.asm#gd_monster_info", _gd('emit_monster_info'), [0x03]),
    ("gd_enemies", "gamedata.enemies",
     "region:patches/bank_014.asm#gd_enemy_stats", _gd('emit_enemy_stats'), [0x14]),
    ("gd_encounters", "gamedata.encounters",
     "region:patches/bank_001.asm#gd_encounter_pools", _gd('emit_encounter_pools'), [0x01]),
    ("gd_family", "gamedata.breeding.family",
     "region:patches/bank_016.asm#gd_family_recipes", _gd('emit_family_recipes'), [0x16]),
    ("gd_special", "gamedata.breeding.special",
     "region:patches/bank_069.asm#gd_special_recipes", _gd('emit_special_recipes'), [0x69]),
    ("gd_exp_curves", "gamedata.exp_curves",
     "region:patches/bank_013.asm#gd_exp_curves", _gd('emit_curves', 'exp'), [0x13]),
    ("gd_growth_curves", "gamedata.growth_curves",
     "region:patches/bank_013.asm#gd_growth_curves", _gd('emit_curves', 'growth'), [0x13]),
    ("gd_skill_learn", "gamedata.skills.learn",
     "region:patches/bank_006.asm#gd_skill_learn", _gd('emit_skill_learn'), [0x06]),
    ("gd_skill_mp", "gamedata.skills.mp",
     "region:patches/bank_007.asm#gd_skill_mp", _gd('emit_skill_mp'), [0x07]),
    ("gd_skill_records", "gamedata.skills.record",
     "region:patches/bank_054.asm#gd_skill_records", _gd('emit_skill_records'), [0x54]),
    ("gd_library", "gamedata.monsters.family",
     "region:patches/bank_012.asm#gd_library_grouping", _gd('emit_library_grouping'), [0x12]),
    ("gd_library_text", "gamedata.breeding.family",
     "region:patches/bank_04d.asm#gd_library_text", _gd('emit_library_strings'), [0x4D]),
    ("gd_family_voices", "gamedata.families.dialogue",
     "region:patches/bank_06d.asm#gd_family_voices", _gd('emit_family_voices'), [0x6D]),
    ("gd_spirit_names", "gamedata.families.spirit.names",
     "region:patches/bank_041.asm#gd_spirit_names", _gd('emit_spirit_names'), [0x41]),
    # S107 (P3.10 part 2c): the family icons — one 8x8 picture per family into
    # every copy: the font glyphs (bank $4F), families 0-9's gfx streams (bank
    # $2E, NEW hand patch) and Spirit's stream (bank $6D)
    ("gd_family_icons", "gamedata.families.icon",
     "region:patches/bank_04f.asm#gd_family_icons", _gd('emit_family_icon_glyphs'), [0x4F]),
    ("gd_family_icon_streams", "gamedata.families.icon",
     "region:patches/bank_02e.asm#gd_family_icon_streams", _gd('emit_family_icon_streams'), [0x2E]),
    ("gd_spirit_icon_stream", "gamedata.families.icon",
     "region:patches/bank_06d.asm#gd_spirit_icon_stream", _gd('emit_spirit_icon_stream'), [0x6D]),
    # S105 (P3.9b): NEW species are project data (editor2/core/species.py,
    # PROJECT_COMPILER §2.21) — bank $7E art streams + the ns_* regions the
    # new-species forks read; empty custom.species == the original ROM bytes.
    ("species7e", "custom.species", "file:patches/bank_07e.asm",
     _sp('emit_bank_07e'), [0x7E]),
]


def _species_regions():
    from . import species as SP
    return [(name, "custom.species", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in SP.REGIONS]


REGISTRY += _species_regions()


def _art_regions():
    # S107 (P3.10 part 2a): new art for the ORIGINAL monsters (gamedata.art,
    # editor2/core/art.py, PROJECT_COMPILER §2.23) — the battle / walking
    # tables as regions + the three art banks; empty == the original bytes.
    # S107 2b: + the walking layouts copied into each follower bank's free
    # tail (editor2/core/walk_layouts.py; gamedata.art + custom.species)
    from . import art as A
    from . import walk_layouts as WL
    return ([(name, "gamedata.art", f"region:{path}#{name}", fn, [bank])
             for name, path, fn, bank in A.REGIONS]
            + [(name, "gamedata.art", f"file:{path}", fn, [bank])
               for name, path, fn, bank in A.FILES]
            + [(name, "gamedata.art", f"region:{path}#{name}", fn, [bank])
               for name, path, fn, bank in WL.REGIONS])


REGISTRY += _art_regions()


def _monster_text_regions():
    # S108 (P3.10 part 3): the ORIGINAL monsters' names / default nicknames /
    # descriptions (gamedata.monster_text, editor2/core/monster_text.py,
    # PROJECT_COMPILER §2.24) — no edits == the original bytes.
    from . import monster_text as MT
    return [(name, "gamedata.monster_text", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in MT.REGIONS]


REGISTRY += _monster_text_regions()


def _arena_regions():
    # S109 (P3.10b): the arena — masters (banks $04 / $50), class fees (bank
    # $09), team sizes (bank $6E, hand patch) from gamedata.arena
    # (editor2/core/arena.py, PROJECT_COMPILER §2.25); the teams themselves are
    # gamedata.enemies rows. No arena == the original bytes.
    from . import arena as AR
    return [(name, "gamedata.arena", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in AR.REGIONS]


REGISTRY += _arena_regions()


def _your_arena_regions():
    # S128 (P3.14e3): your arena — the copies' map ids, the return pixel, the locked
    # words' offset and the classes' locks (editor2/core/your_arena.py, PROJECT_COMPILER
    # §2.41). No custom.arena == $FF ids / no locks (the game's arena unchanged).
    from . import your_arena as YA
    return [(name, "custom.arena", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in YA.REGIONS]


REGISTRY += _your_arena_regions()


def _shop_regions():
    from . import shops as SH
    return [(name, "gamedata.items", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in SH.REGIONS]


REGISTRY += _shop_regions()


def _service_regions():
    # S126 (P3.14e1): the Medal Man's rewards (bank $12 MedalRewardTable +
    # MEDAL_REWARD_COUNT; editor2/core/services.py). No gamedata.medals = the
    # game's 4 rewards (the table moved to the bank's end).
    from . import services as SV
    return [(name, "gamedata.medals", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in SV.REGIONS]


REGISTRY += _service_regions()


def _skill_regions():
    # S110 (P3.11): skill names (bank $41), SKIL-menu descriptions + their
    # pointer rows + the spill pad (bank $56), and the looks-like tables
    # (banks $5f / $55) from gamedata.skills (editor2/core/skills.py,
    # PROJECT_COMPILER §2.26). No edits == the original bytes.
    from . import skills as SK
    return [(name, "gamedata.skills", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in SK.REGIONS]


REGISTRY += _skill_regions()


def _custom_skill_regions():
    # S111 (P3.11c/d): the CUSTOM skills' data (built-in $E0-$E9 + a project's new
    # ones $EA-$FE) and the stock skills' element override — records ($54), MP
    # ($07), learn rows / base / elements / Tame meter / Quake power ($72),
    # announce + AI target rows ($58), battle lines ($4C), looks ($5F), sounds
    # ($55), names ($41), SKIL texts ($56) (editor2/core/custom_skills.py,
    # PROJECT_COMPILER §2.27). No edits == the built-in data.
    from . import custom_skills as CS
    return [(name, "gamedata.skills", f"region:{path}#{name}", fn, [bank])
            for name, path, fn, bank in CS.REGIONS]


REGISTRY += _custom_skill_regions()


def _anim_entries():
    # S112 (P3.11e): the project's NEW battle animations (bank $6F engine +
    # data, bank $70 tile sheets) and every skill's own presentation (bank
    # $5F SkillRoutineOverride / SkillAnimOverride) — editor2/core/
    # battle_anims.py, PROJECT_COMPILER §2.28. No edits == the stock
    # behaviour (empty tables, all $FF).
    from . import battle_anims as BA

    def e6f(prj, warnings):
        return BA.emit_bank_06f(prj, warnings, template('bank_06f_head.asm'))
    e6f.__name__ = 'emit_bank_06f'
    return [("anims6f", "custom.animations", "file:patches/bank_06f.asm", e6f, [0x6F]),
            ("anims70", "custom.animations", "file:patches/bank_070.asm",
             BA.emit_bank_070, [0x70]),
            ("gd_anim_routine", "gamedata.skills.presentation",
             "region:patches/bank_05f.asm#gd_anim_routine", BA.emit_routine_region, [0x5F]),
            ("gd_anim_cmd", "gamedata.skills.presentation",
             "region:patches/bank_05f.asm#gd_anim_cmd", BA.emit_cmd_region, [0x5F])]


REGISTRY += _anim_entries()


def _milly_entries():
    # S121 (ROADMAP P3.16 + E7): the MILLY HOOK — bank $79 (template
    # bank_079_head.asm + Milayou's frames) and the same-size regions in banks
    # $0E (the bedroom script), $01 (two redirects) and $4F (the MILLY tiles)
    # — editor2/core/milly.py, PROJECT_COMPILER §2.34. Hook off == vanilla bytes.
    from . import milly as MH

    def e79(prj, warnings):
        return MH.emit_bank_079(prj, warnings, template('bank_079_head.asm'))
    e79.__name__ = 'emit_bank_079'
    return ([("hooks79", "custom.milly_hook", "file:patches/bank_079.asm", e79, [0x79])]
            + [(name, "custom.milly_hook", f"region:{path}#{name}", fn, [bank])
               for name, path, fn, bank in MH.REGIONS])


REGISTRY += _milly_entries()


TEXT_SPRITE_VANILLA = """\
jr_006_6893:
    ld a, [wInGateworld]
    or a
    jr nz, jr_006_68a7

    ld a, [wMapID]
    cp $08
    jr z, jr_006_68a4

    cp $5d
    jr nz, jr_006_68a7

jr_006_68a4:
    xor a
    ldh [$d3], a
"""


def emit_region_text_sprites(prj, warnings):
    """S121: the bank $06 text-box opener's "sprites stay in rooms $08 / $5D"
    test (20 bytes) — vanilla, or (a room sets text_keeps_sprites) a same-size
    call into bank $71 entry 8 TextSpriteMode, which also reads the room's
    CustomRoomFlagsTable bit 1."""
    if not prj.text_sprite_rooms():
        return TEXT_SPRITE_VANILLA
    return ("jr_006_6893:\n"
            "    ld hl, $7108                   ; bank $71 entry 8 TextSpriteMode (S121): $08 / $5D +\n"
            "    rst $10                        ;   custom rooms with text_keeps_sprites -> $FFD3 := 0\n"
            + "    nop\n" * 16)


REGISTRY += [("text_sprites06", "custom.rooms",
              "region:patches/bank_006.asm#text_sprite_mode", emit_region_text_sprites, [0x06])]
