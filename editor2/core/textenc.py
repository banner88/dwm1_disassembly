"""textenc.py — custom-text emission for bank $60 (TEXT_SYSTEM.md owns the format).

Emission strategy: quoted ASCII segments in `db "…"` rely on the GLOBAL
charmap (disassembly/charmap.asm, INCLUDEd by game.asm line 86 before all
banks), exactly as the proven hand-authored strings do. Control codes are
emitted as hex bytes. DTE is NOT applied to custom text in v1 (matches the
proven hand-authored state; a future space-optimising pass may add it).

Format rules enforced here / in validators (owning doc TEXT_SYSTEM.md +
KEY_LESSONS Session 2):
  * strings terminate `$F7 $F0` (plain) or `$E7 $F0` (YES/NO choice) —
    $E7 is CHOICE, not END.
  * line breaks are `$EF $EE` (PAGE+NEWLINE); a bare $EE overwrites line 1.
  * standard NPC box opener: `$EA $9F $A3`.
  * the custom pointer table is TWO-LEVEL (SaveBankAndSwitch $00:$0940);
    flat tables crash — the emitter builds section tables structurally.
"""

CTRL = {
    'CHOICE': 0xE7, 'PAUSE': 0xE8, 'NUM': 0xE9, 'BOX': 0xEA, 'BOX2': 0xEB,
    'NAME': 0xEC, 'MONSTER': 0xED, 'NEWLINE': 0xEE, 'PAGE': 0xEF,
    'SECTION': 0xF0, 'HERO': 0xF6, 'CLEAR': 0xF7, 'CONTINUE': 0xF9,
    'WAIT': 0xFA, 'CHOICE2': 0xFF,
}

STD_BOX = [0xEA, 0x9F, 0xA3]      # TEXT_SYSTEM "Standard NPC Text Format"
LINE_BREAK = [0xEF, 0xEE]          # $EF $EE together, never bare $EE
END_PLAIN = [0xF7, 0xF0]           # CLEAR + SECTION
END_CHOICE = [0xE7, 0xF0]          # CHOICE + SECTION (script checks $C83C)

MAX_LINE = 18                      # display cells per line (Phase 2 spec)

# Characters representable by the charmap for quoted emission
# (charmap.asm: digits, A-Z, a-z, ' > , . ; space ! ?). '>' maps to an arrow
# glyph — excluded from auto text. '"' cannot appear inside a db string.
_SAFE = set("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            "abcdefghijklmnopqrstuvwxyz'.,;!? -")
# NOTE: '-' maps via charmap? charmap.asm defines $5C-$64 as ' > , . ; .. sp ! ?
# '-' is NOT listed in TEXT_SYSTEM's table; validator rejects unknown chars in
# auto mode rather than guessing (KEY_LESSONS: don't guess encodings).
_SAFE.discard('-')


class TextError(ValueError):
    pass


def check_text_chars(s):
    bad = sorted({c for c in s if c not in _SAFE})
    if bad:
        raise TextError(f"characters not in charmap-safe set: {bad!r} in {s!r}")


def wrap_text(s, width=MAX_LINE):
    """Greedy word wrap to `width` display cells (1 char = 1 cell)."""
    words, lines, cur = s.split(), [], ""
    for w in words:
        if len(w) > width:
            raise TextError(f"word longer than {width} cells: {w!r}")
        cand = (cur + " " + w).strip()
        if len(cand) <= width:
            cur = cand
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def entry_stream(entry):
    """Normalise a dialogue entry to a stream of ('str', s) / ('ctl', [bytes]).

    Two authoring forms (schema PROJECT_COMPILER.md §dialogue):
      explicit: {"lines": ["Want a", "Beef Jerky?"], "choice": true}
      raw     : {"raw": [["box"], "Want a", ["br"], ...]}  (regression-grade)
      auto    : {"text": "long text...", "choice": false} → wrapped
    """
    out = []
    if 'raw' in entry:
        for item in entry['raw']:
            if isinstance(item, str):
                out.append(('str', item))
            else:
                tok = item[0].upper()
                if tok == 'BOX':
                    out.append(('ctl', STD_BOX))
                elif tok == 'BR':
                    out.append(('ctl', LINE_BREAK))
                elif tok in CTRL:
                    out.append(('ctl', [CTRL[tok]]))
                elif tok == 'BYTES':
                    out.append(('ctl', [int(str(b).replace('$', '0x'), 16)
                                        if isinstance(b, str) else b
                                        for b in item[1:]]))
                else:
                    raise TextError(f"unknown raw token {item!r}")
        return out
    if 'lines' in entry:
        lines = list(entry['lines'])
    else:
        lines = wrap_text(entry['text'])
    out.append(('ctl', STD_BOX))
    for i, ln in enumerate(lines):
        check_text_chars(ln)
        if len(ln) > MAX_LINE:
            raise TextError(f"line over {MAX_LINE} cells: {ln!r}")
        out.append(('str', ln))
        out.append(('ctl', LINE_BREAK))
    if entry.get('choice'):
        # choice texts keep the trailing line break before $E7 $F0
        # (proven form: "...?" $EF $EE $E7 $F0 — TEXT_SYSTEM "YES/NO Choice")
        out.append(('ctl', END_CHOICE))
    else:
        # plain texts DROP the final line break before $F7 $F0
        # (proven form: last line then $F7 $F0)
        if out and out[-1] == ('ctl', LINE_BREAK):
            out.pop()
        out.append(('ctl', END_PLAIN))
    return out


def render_entry_asm(label, entry, comment=None):
    """Render one text entry as .asm lines (db strings + hex controls)."""
    lines = [f"{label}:"]
    if comment:
        lines[0] = f"{label}:"  # keep label clean; comment goes above
        lines.insert(0, f"; {comment}")
    stream = entry_stream(entry)
    # Coalesce: controls and strings interleave on shared db lines exactly
    # like the hand-authored files (db $EA, $9F, $A3 / db "Want a", $EF, $EE)
    cur = []

    def flush():
        nonlocal cur
        if cur:
            lines.append("    db " + ", ".join(cur))
            cur = []

    i = 0
    while i < len(stream):
        kind, v = stream[i]
        if kind == 'ctl' and v == STD_BOX:
            flush()
            lines.append("    db $EA, $9F, $A3")
        elif kind == 'str':
            cur.append('"' + v + '"')
            # attach a following control run to this line (matches style)
            j = i + 1
            while j < len(stream) and stream[j][0] == 'ctl':
                cur += [f"${b:02X}" for b in stream[j][1]]
                j += 1
            flush()
            i = j - 1
        else:
            cur += [f"${b:02X}" for b in v]
            flush()
        i += 1
    flush()
    return lines


def entry_terminator_ok(entry):
    """Validator hook: entry ends $F7 $F0 or $E7 $F0."""
    stream = entry_stream(entry)
    tail = []
    for kind, v in stream:
        if kind == 'ctl':
            tail += v
        else:
            tail = []
    return tail[-2:] in ([0xF7, 0xF0], [0xE7, 0xF0]) if len(tail) >= 2 else False
