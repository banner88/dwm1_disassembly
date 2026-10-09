"""places.py — S136 (ROADMAP ARC CAP2b): PLACE BANKS.

A *place* is what the editor calls a room. Everything bank $60 used to hold
for a room — its script table + scripts, its tile patches (ops $24 / $61), its
screen sub-table, step entries, NPC / exit lists, state rules and monster
cast; S137 (ROADMAP ARC CAP2c): + its render rows and palettes, which bank $17
used to hold — is the place's BLOCK, and a block lives in one HOME BANK: bank $60
first, then the place banks $80+ (first fit, in map id order; the banks come
from Project._take_ext_bank after the LZ stream banks, S135). The project's
text is placed the same way, one 256-id SECTION at a time (section = text id
>> 8 - $0A; TextQueueCheck_Ext / SayText put it in $C822).

Engine (editor2/core/templates/bank_060_head.asm + place_readers.asm): bank
$60's entries 0/1/2/4/5/8/9/10/13 look the place up in `PlaceDirectory` (per
place: home bank, index in that bank) / `TextSectionBanks` on EVERY call,
write the index to wPlaceIdx and call that bank's reader entry; every home
bank carries the same reader block, whose tables are indexed by wPlaceIdx.
Bank $60 keeps the global data: the custom skills' scripts (type $FF),
VanillaExitExtTable, VanillaNPCExtTable.

Accounting: a block's size is the exact db / dw payload of its generated
text (validators._payload_bytes) + its rows in the bank's tables; the reader
code is a measured constant (validators.TEMPLATE_SIZE[$60] for bank $60's
head + readers, PLACE_TEMPLATE_SIZE for a place bank's self-ID + readers).
PROJECT_COMPILER §2.45.
"""

from . import formats as F

HOME_BANK = 0x60
BANK_SIZE = 0x4000
ROOM_ROW_BYTES = 11          # PlaceRoomTable / Script / Rule / Cast / Render (dw) + Source (db)
# auto-numbered text ids start a new section before a section's texts pass
# this many bytes, so one section always fits a place bank (a full section of
# 256 texts at ~80 B is ~20 KB — more than a bank)
TEXT_SECTION_BUDGET = 12288
DATA_MARKER = "PLACE DATA (generated"


def suffix(bank):
    """The reader block's label suffix in `bank` ("" in bank $60)."""
    return '' if bank == HOME_BANK else f"_P{bank:02X}"


def place_bank_file(bank):
    return f"bank_{bank:03x}.asm"


def readers(bank):
    """The pinned reader block (templates/place_readers.asm) for `bank`."""
    from .emitters import template
    text = template('place_readers.asm').replace('{P}', suffix(bank))
    if '{P}' in text:
        raise RuntimeError("place_readers.asm: an unreplaced {…} placeholder")
    return text.rstrip('\n')


# ---------------------------------------------------------------- blocks
def _payload(lines):
    from .validators import _payload_bytes
    return _payload_bytes("\n".join(lines))


def room_block(prj, r, warnings):
    """(lines, row) of one place: row = (subtable, script table, rules|None,
    cast|None, source map id, render table|None)."""
    from . import emitters as E
    tag = E.room_tag(r)
    src = F.val(r.get('source_mapID', 0))
    if r.get('placeholder'):
        lines = [f"; --- {F.hexb(F.val(r['mapID']))} ({r.get('id','')}) placeholder "
                 "(never entered; all screens invalid) ---",
                 f"{tag}_SubTable:",
                 "    dw $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF, $FFFF",
                 f"{tag}_ScriptPtrTable:",
                 f"    dw {tag}_Scr00   ; [0] room entry (no-op)",
                 f"{tag}_Scr00:",
                 "    dw $FFFF", ""]
        return lines, (f"{tag}_SubTable", f"{tag}_ScriptPtrTable", None, None, src, None)
    text_names = prj.text_comments()
    if r.get('scripts'):
        lines = E._room_scripts(prj, r, text_names, warnings)
    else:
        lines = [f"; --- {F.hexb(F.val(r['mapID']))} ({r.get('id','')}) no scripts ---",
                 f"{tag}_ScriptPtrTable:",
                 f"    dw {tag}_Scr00   ; [0] room entry (no-op)",
                 f"{tag}_Scr00:",
                 "    dw $FFFF", ""] + E._patch_data_lines(r)
    rules_lbl = None
    rules = prj.state_rules(r)
    if rules:
        rules_lbl = f"{tag}_StateRules"
        lines += E._state_rule_lines(prj, r, rules_lbl, rules)
    cast_lbl = None
    casts = [(k, prj.monster_cast(r, k)) for k in sorted(prj.room_screens(r))]
    casts = [(k, c) for k, c in casts if c]
    if casts:
        cast_lbl = f"{tag}_MonsterCast"
        lines += E._monster_cast_lines(cast_lbl, casts)
    lines += E._room_data(prj, r)
    rlines, render_lbl = E.render_lines(prj, r, warnings)     # S137 (CAP2c)
    lines += rlines
    return lines, (f"{tag}_SubTable", f"{tag}_ScriptPtrTable", rules_lbl, cast_lbl, src,
                   render_lbl)


def text_block(prj, si, sec):
    from . import textenc as T
    lines = [f"CustomTextSection{si}:"]
    for tid, entry in sec:
        lines.append(f"    dw {prj.text_label(tid)}"
                     f"   ; {F.hexw(tid)}: {entry.get('comment','')}")
    lines.append("")
    for tid, entry in sec:
        cm = f"{F.hexw(tid)} — {entry.get('comment','')}".rstrip(' —')
        lines += T.render_entry_asm(prj.text_label(tid), entry, comment=cm)
        lines.append("")
    return lines


def text_entry_size(prj, tid, entry):
    """Bytes one text entry assembles to (its row excluded); 0 if it cannot
    render (validators report that text's problem)."""
    from . import textenc as T
    try:
        return _payload(T.render_entry_asm(prj.text_label(tid), entry))
    except Exception:                                    # noqa: BLE001
        return 0


# ---------------------------------------------------------------- bank $60's fixed part
def _skill_lines(prj, warnings):
    from . import emitters as E
    from . import scriptgen as S
    text_names = prj.text_comments()
    first = E.SKILL_SCRIPT_FIRST
    out = ["SkillScriptPtrTable:   ; script type $FF — custom skills' dialogs (bank $60 only)"]
    for i in range(first):
        out.append(f"    dw SkillScrNoop   ; [{i}] never armed")
    for i, sc in enumerate(prj.skill_scripts):
        out.append(f"    dw SkillScr{first + i:02d}   ; [{first + i}] {sc['id']}")
    out += ["SkillScrNoop:", "    dw $FFFF", ""]
    for i, sc in enumerate(prj.skill_scripts):
        for it in prj.script(sc['id'])['ops']:
            if isinstance(it, list) and len(it) > 1 and it[0] == 'op' and \
                    str(it[1]).lower() in ('0x24', '0x61', 'draw_tiles', 'draw_attrs'):
                raise ValueError(f"skill script {sc['id']!r}: ops $24 / $61 are not "
                                 "supported in the custom skills' scripts (bank $60 "
                                 "forwards them by place; type $FF has none)")
        out += S.emit_script(f"SkillScr{first + i:02d}", prj.script(sc['id'])['ops'],
                             text_names=text_names, warnings=warnings)
        out.append("")
    return out


def _globals_lines(prj):
    from . import emitters as E
    return E._vanilla_exit_exts(prj) + E._vanilla_npc_exts(prj)


# ---------------------------------------------------------------- the plan
def plan(prj):
    """Where every place and text section lives (cached on the Project).
    {'home': {mapID: (bank, index)}, 'text_home': [bank per section],
     'banks': {bank: {'rooms': [(room, lines, row)], 'texts': [(si, lines)]}},
     'overflow': [bank, …], 'used': {bank: bytes}, 'skill': lines,
     'globals': lines, 'warnings': [...]}"""
    cached = getattr(prj, '_place_plan', None)
    if cached is not None:
        return cached
    from . import validators as V
    from .project import ProjectError
    prj.stream_plan()                       # the stream banks take their $80+ banks first
    warnings = []
    skill = _skill_lines(prj, warnings)
    glob = _globals_lines(prj)
    sections = prj.text_sections()
    n_rooms = len(prj.rooms)
    head = V.TEMPLATE_SIZE.get(HOME_BANK) or 0
    fixed60 = head + _payload(skill) + _payload(glob) + 2 * n_rooms + len(sections)
    cap = {HOME_BANK: BANK_SIZE - fixed60}
    place_cap = BANK_SIZE - V.PLACE_TEMPLATE_SIZE
    used = {HOME_BANK: 0}
    span = {}                               # bank -> (first section, last section)
    banks = {HOME_BANK: {'rooms': [], 'texts': []}}
    order = [HOME_BANK]
    home, text_home = {}, []

    def fits(b, size, si=None):
        extra = 0
        if si is not None:
            lo, hi = span.get(b, (si, si))
            extra = 2 * (max(hi, si) - min(lo, si) + 1) - (
                2 * (hi - lo + 1) if b in span else 0)
        return used[b] + size + extra <= cap[b], extra

    def place(size, what, si=None):
        for b in order:
            ok, extra = fits(b, size, si)
            if ok:
                break
        else:
            if size + (2 if si is not None else 0) > place_cap:
                raise ProjectError(
                    f"{what} is {size} bytes — more than one bank holds "
                    f"({place_cap}); split it (ARC CAP2b, PROJECT_COMPILER §2.45)")
            b = prj._take_ext_bank('places')
            order.append(b)
            cap[b] = place_cap
            used[b] = 0
            banks[b] = {'rooms': [], 'texts': []}
            ok, extra = fits(b, size, si)
        used[b] += size + extra
        if si is not None:
            lo, hi = span.get(b, (si, si))
            span[b] = (min(lo, si), max(hi, si))
        return b

    taken0 = list(getattr(prj, '_ext_taken', None) or [])
    try:
        _fill(prj, warnings, place, banks, home, text_home, sections)
    except Exception:
        prj._ext_taken = taken0              # a failed plan gives its banks back
        raise
    for b in banks:
        banks[b]['texts'].sort()
    out = {'home': home, 'text_home': text_home, 'banks': banks,
           'overflow': [b for b in order if b != HOME_BANK],
           'used': {b: (fixed60 if b == HOME_BANK else V.PLACE_TEMPLATE_SIZE) + used[b]
                    for b in order},
           'skill': skill, 'globals': glob, 'warnings': warnings, 'span': span}
    prj._place_plan = out
    return out


def _fill(prj, warnings, place, banks, home, text_home, sections):
    for r in prj.rooms:
        lines, row = room_block(prj, r, warnings)
        size = _payload(lines) + ROOM_ROW_BYTES
        b = place(size, f"room {r.get('id')!r} (its scripts + screens + lists + colours)")
        home[F.val(r['mapID'])] = (b, len(banks[b]['rooms']))
        banks[b]['rooms'].append((r, lines, row))
    for si, sec in enumerate(sections):
        lines = text_block(prj, si, sec)
        b = place(_payload(lines), f"text section {si} ({F.hexw(0x0A00 + (si << 8))}…)", si)
        text_home.append(b)
        banks[b]['texts'].append((si, lines))


# ---------------------------------------------------------------- emission
def _bank_tables(plan_, bank):
    P = suffix(bank)
    ent = plan_['banks'][bank]
    rows = [(F.val(r['mapID']), r.get('id', ''), row) for r, _l, row in ent['rooms']]
    out = [f"; place tables of bank ${bank:02X} — index = wPlaceIdx (PlaceDirectory, bank $60)"]
    out.append(f"PlaceRoomTable{P}:")
    out += [f"    dw {row[0]}   ; {F.hexb(mid)} = place {i} here"
            for i, (mid, _n, row) in enumerate(rows)]
    out.append(f"PlaceScriptTable{P}:")
    out += [f"    dw {row[1]}   ; mapID {F.hexb(mid)}" for mid, _n, row in rows]
    out.append(f"PlaceRuleTable{P}:")
    out += [f"    dw {row[2]}   ; {F.hexb(mid)} {n}" if row[2]
            else f"    dw $0000   ; {F.hexb(mid)} (no rules)" for mid, n, row in rows]
    out.append(f"PlaceCastTable{P}:")
    out += [f"    dw {row[3]}   ; {F.hexb(mid)} {n}" if row[3]
            else f"    dw $0000   ; {F.hexb(mid)} (no monster NPCs)" for mid, n, row in rows]
    out.append(f"PlaceRenderTable{P}:   ; S137: render rows + palettes (bank $17 via entry 13)")
    out += [f"    dw {row[5]}   ; {F.hexb(mid)} {n}" if row[5]
            else f"    dw $0000   ; {F.hexb(mid)} (no render table: the Castle's)"
            for mid, n, row in rows]
    out.append(f"PlaceSourceTable{P}:")
    out += [f"    db {F.hexb(row[4])}   ; {F.hexb(mid)} — {n}" for mid, n, row in rows]
    lo_hi = plan_['span'].get(bank)
    out.append(f"PlaceTextRows{P}:   ; text sections "
               + (f"{lo_hi[0]}-{lo_hi[1]}" if lo_hi else "(none here)"))
    if lo_hi:
        have = {si for si, _l in ent['texts']}
        for si in range(lo_hi[0], lo_hi[1] + 1):
            out.append(f"    dw CustomTextSection{si}" if si in have
                       else f"    dw $0000   ; section {si} lives in another bank")
    out.append("")
    for r, lines, _row in ent['rooms']:
        out += lines
    for si, lines in ent['texts']:
        out += lines
    out.append(f"PLACE_TEXT_FIRST{P} EQU {lo_hi[0] if lo_hi else 0}")
    return out


def emit_bank_060(prj, warnings, head_text):
    p = plan(prj)
    warnings.extend(w for w in p['warnings'] if w not in warnings)
    from . import emitters as E
    lines = [head_text.rstrip('\n'), "", readers(HOME_BANK), ""]
    lines += E.banner(DATA_MARKER + ") — bank $60: SCRIPT DATA (generated) + places", [
        "Bank $60's own data: the custom skills' scripts, the place directory,",
        "the text section banks, its places' tables and blocks, its text",
        "sections, the vanilla-room exit / NPC overrides (editor2/core/places.py).",
        "Index 0 of a place's script table = its room entry script."])
    lines += p['skill']
    lines.append(f"PlaceDirectory:   ; per place (map id $6B + n): home bank, index there")
    for r in prj.rooms:
        mid = F.val(r['mapID'])
        b, i = p['home'][mid]
        lines.append(f"    db ${b:02X}, {i}   ; {F.hexb(mid)} {r.get('id','')}")
    lines.append("TextSectionBanks:   ; per text section ($0A00 + 256 n): its home bank")
    for si, b in enumerate(p['text_home']):
        lines.append(f"    db ${b:02X}   ; section {si}")
    lines.append("")
    lines += _bank_tables(p, HOME_BANK)
    lines.append("")
    lines += p['globals']
    lines.append(f"PLACE_COUNT EQU {len(prj.rooms)}")
    lines.append(f"TEXT_SECTIONS EQU {len(p['text_home'])}")
    return "\n".join(lines) + "\n"


def emit_place_banks(prj, warnings):
    """{target: text} — one whole file per place bank (none when everything
    fits bank $60). INCLUDEd by bank_ext.asm."""
    from . import emitters as E
    p = plan(prj)
    out = {}
    for b in p['overflow']:
        lines = E.banner(f"BANK ${b:02X} — PLACE BANK (generated, S136)", [
            "Places (custom rooms) and text sections that did not fit bank $60",
            "(ROADMAP ARC CAP2b; editor2/core/places.py, first fit). Bank $60's",
            "forwarders call this bank's reader entries (PlaceEntries at $4001)",
            "with wPlaceIdx = the place's index here. The self-ID byte is",
            "load-bearing (rst $10 / the text engine read [$4000]).",
            "Generated by build_project.py — do not hand-edit."])
        lines.append(f'SECTION "ROM Bank ${b:03X}", ROMX[$4000], BANK[${b:02X}]')
        lines.append(f"    db ${b:02X}  ; bank self-ID")
        lines.append(readers(b))
        lines.append("")
        lines += E.banner(DATA_MARKER + f") — bank ${b:02X}")
        lines += _bank_tables(p, b)
        out[f"file:patches/{place_bank_file(b)}"] = "\n".join(lines).rstrip("\n") + "\n"
    return out
