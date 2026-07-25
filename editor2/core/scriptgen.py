"""scriptgen.py — script (opcode) emission for bank $60.

Op model (schema §scripts): a script is a list of items:
    "label:NAME"                       — local branch target
    ["text", TEXT_ID]                  — queue a text id (bare word, B != $FF)
    ["op", NAME_or_HEX, param, ...]    — $FFxx opcode + params
    ["end"]                            — dw $FFFF

Params may be ints, "$XXXX"/"0x…" strings, RGBDS symbols (pass-through,
e.g. ITEM_BEEF_JERKY or a wram label), or "@NAME" local-label references.

Param counts below are verified against the HANDLER CODE reference block in
patches/bank_004.asm (the per-opcode comment table + handlers), NOT against
tools/compile_script.py, whose table disagrees for at least set_bgm
(compile_script says 2; handler $669D advances the counter once and consumes
one word — verified S53; defect logged in PROJECT_COMPILER.md + TOOLS_AND_DATA).
Branch-target params (the LAST param of the ops in BRANCH_LAST) are emitted
as label words. Serialisation is 1 word per opcode + 1 word per param —
identical to the proven hand-authored scripts.
"""

OPS = {
    # name: (opcode, n_params)  — verified subset used by custom content;
    # unknown ops may be given as hex ("0x2E") with explicit params.
    'if_flag_clear':      (0x00, 2),
    'if_flag_set':        (0x01, 2),
    'clear_flag':         (0x02, 1),
    'set_flag':           (0x03, 1),
    'goto':               (0x14, 1),
    'check_and_branch':   (0x15, 3),   # addr, value, branch (aka cond_branch)
    'write_ram':          (0x12, 2),   # addr, value (low byte written)
    'map_transition':     (0x0F, 3),   # gate_id|flag, spawnX, spawnY (KEY_LESSONS S3)
    'post_battle_check':  (0x27, 1),
    'check_storage_full': (0x28, 1),   # branch if full
    'add_monster':        (0x29, 1),   # enemy_stats_id (egg path)
    'give_item':          (0x2A, 1),
    'check_inv_full':     (0x2C, 1),   # branch if full
    'set_bgm':            (0x41, 1),   # VERIFIED 1 param (handler $04:$669D)
    'npc_hide':           (0x48, 1),
    'npc_show':           (0x49, 1),
    # S70 additions — each verified against the HANDLER BYTES (not comments):
    'write_ram2':         (0x13, 2),   # 16-bit RAM write: addr, value16 (LE).
                                       # Vanilla-proven: Healer post-battle
                                       # FF13 D8E3 0307 ($D8E3=$0307).
    'init_dialog':        (0x07, 0),   # $5824: enter dialog mode from script
                                       # context ($C917/18=$FFFF, $C8EB.0 set,
                                       # $C915=0 -> box-open state ladder ->
                                       # slot $0B services queued text). 0
                                       # params (compile_script's "1" is the
                                       # set_bgm-class table defect). REQUIRED
                                       # before any `text` outside an NPC
                                       # interaction (entry scripts, post-
                                       # battle tails) — field mode never
                                       # services the text queue (S70 finding;
                                       # the vanilla Healer boss script uses
                                       # exactly this post-battle).
    'delay':              (0x09, 1),   # $5843: 1 param -> $D8DB, set $D8D7.2, ret=yield
    'wait_movement':      (0x19, 0),   # $5C6D: $D8D7.4 set -> counter-1 + ret (re-exec yield)
    'npc_walk_x':         (0x1A, 2),   # $5C86: npc, signed 16-bit px delta; sets $D8D7.4
    'npc_walk_y':         (0x1B, 2),   # $5CCF: same, Y axis
    'trigger_anim':       (0x1C, 1),   # $5D1A: $XXYY (XX=type: 01=jump; YY=npc, 0=player)
    'lock_movement':      (0x1D, 0),   # $5D4B: set $D8D7.5
    'unlock_movement':    (0x1E, 0),   # $5D53: res $D8D7.5
    'begin_walk':         (0x22, 0),   # $5E87: set $D8D7.3
    'trigger_battle3':    (0x5A, 1),   # $6D56: EID -> $DA03/04, $DA09=3 boss mode,
                                       #        battle-latch + ret=yield; win path
                                       #        resumes the script AFTER this opcode
                                       #        (SIDEQUEST_MAP S68 engine guarantee)
}

BRANCH_LAST = {0x00, 0x01, 0x0E, 0x14, 0x15, 0x27, 0x28, 0x2C, 0x37}


class ScriptError(ValueError):
    pass


def _pval(p):
    if isinstance(p, int):
        return p
    s = str(p).strip()
    if s.startswith('@'):
        return ('label', s[1:])
    if s.startswith('$'):
        return int(s[1:], 16)
    if s.lower().startswith('0x'):
        return int(s, 16)
    if s.lstrip('-').isdigit():
        return int(s) & 0xFFFF
    return ('sym', s)          # RGBDS symbol pass-through


def _fmt(word, base_label):
    if isinstance(word, tuple):
        kind, name = word
        return f"{base_label}_{name}" if kind == 'label' else name
    return f"${word:04X}"


def emit_script(label, items, text_names=None, warnings=None):
    """Render one script to .asm lines. text_names: text_id → short comment."""
    text_names = text_names or {}
    # S70 HARD RULE: a script stream MUST end on an 'end' ($FFFF) or an
    # unconditional terminal op — otherwise execution falls off into the
    # next script's words with player input suppressed forever (the exact
    # "can't move in room $6B" freeze: an edit dropped arm_encounters'
    # ['end'] and the entry script never terminated).
    _TERMINAL_OPS = {'goto', 'warp_castle'}
    if not items:
        raise ScriptError(f"{label}: empty script")
    _last = items[-1]
    _ok = (isinstance(_last, list) and (
        _last[0] == 'end'
        or (_last[0] == 'op' and _last[1] in _TERMINAL_OPS)))
    if not _ok:
        raise ScriptError(
            f"{label}: script does not terminate — last item {_last!r}; "
            "append ['end'] (or finish on goto/warp_castle). Falling off "
            "the stream executes the next script's words with input "
            "suppressed (S70 freeze class).")
    lines = [f"{label}:"]
    seen_labels, used_labels = set(), set()
    for it in items:
        if isinstance(it, str):
            if not it.startswith('label:'):
                raise ScriptError(f"{label}: bad string item {it!r}")
            name = it.split(':', 1)[1]
            if name in seen_labels:
                raise ScriptError(f"{label}: duplicate label {name}")
            seen_labels.add(name)
            lines.append(f"{label}_{name}:")
            continue
        head = it[0]
        if head == 'end':
            lines.append("    dw $FFFF")
            continue
        if head == 'text':
            tid = _pval(it[1])
            if isinstance(tid, tuple):
                raise ScriptError(f"{label}: text id must be numeric: {it!r}")
            cm = text_names.get(tid, "")
            lines.append(f"    dw ${tid:04X}" + (f"  ; {cm}" if cm else ""))
            continue
        if head != 'op':
            raise ScriptError(f"{label}: unknown item head {head!r}")
        opname = it[1]
        params = [_pval(p) for p in it[2:]]
        if isinstance(opname, str) and opname in OPS:
            opcode, n = OPS[opname]
            if len(params) != n and warnings is not None:
                warnings.append(
                    f"{label}: op {opname} expects {n} params, got {len(params)}"
                    " (bank_004-verified table)")
            comment = opname
        else:
            opcode = _pval(opname)
            if isinstance(opcode, tuple):
                raise ScriptError(f"{label}: bad opcode {opname!r}")
            comment = f"opcode ${opcode:02X}"
        lines.append(f"    dw $FF{opcode:02X}  ; {comment}")
        for p in params:
            if isinstance(p, tuple) and p[0] == 'label':
                used_labels.add(p[1])
            lines.append(f"    dw {_fmt(p, label)}")
    missing = used_labels - seen_labels
    if missing:
        raise ScriptError(f"{label}: unresolved local labels: {sorted(missing)}")
    return lines
