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
# S97 r2 (PyBoy-measured, $EA $9F $A3 opener): a box shows 2 lines of 18
# cells; the "*:" speaker mark takes the first 2 cells of the FIRST box's
# line 1 (16 left); later lines and boxes start at cell 0 (no indent — the
# indent seen in vanilla comes from the $EB opener). A line past 18 cells
# is wrapped by the engine mid-word; lines past 2 scroll the box without
# waiting — so the editor authors text as explicit boxes.
BOX_LINES = 2
FIRST_LINE = 16
BOX_BREAK = [0xFA, 0xF7, 0xEF, 0xEE]   # WAIT (arrow, A) + CLEAR + PAGE+NEWLINE — vanilla 6029x

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


# charmap.asm, as rgbasm applies it to a quoted db string (longest match
# first: ".." is ONE glyph, $61 — so "..." is 2 cells, not 3).
CHARMAP = {str(d): d for d in range(10)}
CHARMAP.update({chr(0x41 + i): 0x24 + i for i in range(26)})
CHARMAP.update({chr(0x61 + i): 0x3E + i for i in range(26)})
CHARMAP.update({"'": 0x5C, ',': 0x5E, '.': 0x5F, ';': 0x60, '..': 0x61,
                ' ': 0x62, '!': 0x63, '?': 0x64})
SPEAKER = [0x9F, 0xA3]             # the "*:" the $EA $9F $A3 opener prints


def codes(s):
    """Glyph codes of a charmap-safe string (longest match, like rgbasm)."""
    out, i = [], 0
    while i < len(s):
        if s.startswith('..', i):
            out.append(0x61)
            i += 2
        elif s[i] in CHARMAP:
            out.append(CHARMAP[s[i]])
            i += 1
        else:
            raise TextError(f"character {s[i]!r} not in the charmap-safe set")
    return out


def cells(s):
    """Display cells a string takes (one per glyph)."""
    return len(codes(s))


# The text font: 2bpp 8x8 tiles indexed by glyph code at bank $4F $4010
# (disassembly/bank_04f.asm INCBINs "0-9" / "A-P" …; PyBoy S97 r2: the
# dialog canvas tiles $B0+ hold exactly these bytes for "*:Hello").
FONT_ROM_OFFSET = 0x4F * 0x4000 + 0x0010


def glyph_2bpp(rom, code):
    o = FONT_ROM_OFFSET + code * 16
    return rom[o:o + 16]


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


def line_limit(box_index, line_index):
    """Display cells available to a line of a `boxes` text."""
    return FIRST_LINE if (box_index, line_index) == (0, 0) else MAX_LINE


def flow_boxes(text, first_box=True):
    """Word-wrap free text into boxes of BOX_LINES lines (first line of the
    first box FIRST_LINE cells, the rest MAX_LINE). A newline in `text`
    forces a new line, an empty line forces a new box. first_box=False
    flows text that continues later in a talk (no "*:" line)."""
    boxes, cur = [], []
    base = 0 if first_box else 1

    def push_line(ln):
        nonlocal cur
        if len(cur) == BOX_LINES:
            boxes.append(cur)
            cur = []
        cur.append(ln)

    for para in text.replace('\r', '').split('\n\n'):
        if not para.strip():
            continue
        if cur:
            boxes.append(cur)
            cur = []
        for hard in para.split('\n'):
            words, line = hard.split(), ''
            for w in words:
                lim = line_limit(len(boxes) + base, len(cur))
                if cells(w) > MAX_LINE:
                    raise TextError(f"word longer than {MAX_LINE} cells: {w!r}")
                cand = (line + ' ' + w) if line else w
                if cells(cand) <= lim:
                    line = cand
                else:
                    if line:
                        push_line(line)
                    line = w
            if line:
                push_line(line)
    if cur:
        boxes.append(cur)
    return boxes


def check_boxes(boxes):
    """Raise TextError when a box text cannot show as authored."""
    if not boxes:
        raise TextError('no text')
    for bi, box in enumerate(boxes):
        if not box or not any(ln for ln in box):
            raise TextError(f'box {bi + 1} is empty')
        if len(box) > BOX_LINES:
            raise TextError(f'box {bi + 1} has {len(box)} lines (a box shows {BOX_LINES})')
        for li, ln in enumerate(box):
            check_text_chars(ln)
            lim = line_limit(bi, li)
            if cells(ln) > lim:
                raise TextError(f'box {bi + 1} line {li + 1} is {cells(ln)} cells '
                                f'(max {lim}): {ln!r}')


def entry_boxes(entry):
    """The boxes a `boxes` / auto `text` entry shows (None for lines/raw)."""
    if 'boxes' in entry:
        return [list(b) for b in entry['boxes']]
    if 'text' in entry and 'lines' not in entry and 'raw' not in entry:
        return flow_boxes(entry['text'])
    return None


def entry_stream(entry):
    """Normalise a dialogue entry to a stream of ('str', s) / ('ctl', [bytes]).

    Two authoring forms (schema PROJECT_COMPILER.md §dialogue):
      explicit: {"lines": ["Want a", "Beef Jerky?"], "choice": true}
      raw     : {"raw": [["box"], "Want a", ["br"], ...]}  (regression-grade)
      auto    : {"text": "long text...", "choice": false} → flowed into
                boxes (S97 r2; was one scrolling page)
      boxes   : {"boxes": [["line 1", "line 2"], ["next box"]], "choice": …}
                (S97 r2) — each box waits for A ($FA) and clears ($F7)
    """
    out = []
    boxes = entry_boxes(entry)
    if boxes is not None:
        check_boxes(boxes)
        out.append(('ctl', STD_BOX))
        for bi, box in enumerate(boxes):
            if bi:
                out.append(('ctl', BOX_BREAK))
            for li, ln in enumerate(box):
                if li:
                    out.append(('ctl', LINE_BREAK))
                if ln:
                    out.append(('str', ln))
        # choice: the question's last line then $E7 $F0 (vanilla form,
        # PyBoy S97 r2: both lines stay, YES/NO opens); plain: $F7 $F0
        out.append(('ctl', END_CHOICE if entry.get('choice') else END_PLAIN))
        return out
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
