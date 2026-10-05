"""textenc.py — custom-text emission for bank $60 (TEXT_SYSTEM.md owns the format).

Emission strategy: quoted ASCII segments in `db "…"` rely on the GLOBAL
charmap (disassembly/charmap.asm, INCLUDEd by game.asm line 86 before all
banks), exactly as the proven hand-authored strings do. Glyphs the charmap
lacks (S120: contractions, - & ( ) + : / ~ [ ] " * …) and the name inserts are
emitted as hex bytes.

S120 (ROADMAP P3.6, measured in PyBoy on the user's save): the font has NO
letter-pair "DTE" — codes $66-$71 are ONE-CELL CONTRACTIONS ('l 't 's 'r 'm 'y
'v 'd 'e 'c 'n 'T; vanilla writes "don't" as "don" + $67) and $65 is the double
quote; the editor writes an apostrophe + one of those letters as that glyph,
like the game does (one cell instead of two). `{hero}` = text code $F6 (the
hero's name, 4 cells) and `{lead}` = $F9 $00 (the lead monster's species name,
≤ 9 cells; the compiler puts op $3F load_lead_name before the text). A box text
may name its SPEAKER ("*" = the vanilla "*:", "" = none, "hero" = the hero's
name, else a name) and its VOICE (the per-letter blip: "low" = $EA, sound $5B,
the King / bosses; "high" = $EB, sound $5A, Milayou / Pulio / Watabou; "none" =
no opener, silent like the hero's own lines). $EA / $EB print nothing and
indent nothing (the old "BOX2 indents" note was wrong). TEXT_SYSTEM "Glyphs,
speakers and voices (S120)".

Format rules enforced here / in validators (owning doc TEXT_SYSTEM.md +
KEY_LESSONS Session 2):
  * strings terminate `$F7 $F0` (plain) or `$E7 $F0` (YES/NO choice) —
    $E7 is CHOICE, not END.
  * line breaks are `$EF $EE` (PAGE+NEWLINE); a bare $EE overwrites line 1.
  * standard NPC box opener: `$EA $9F $A3` (voice "low" + the "*:" speaker).
  * the custom pointer table is TWO-LEVEL (SaveBankAndSwitch $00:$0940);
    flat tables crash — the emitter builds section tables structurally.
"""

CTRL = {
    'CHOICE': 0xE7, 'PAUSE': 0xE8, 'NUM': 0xE9, 'BOX': 0xEA, 'BOX2': 0xEB,
    'NAME': 0xEC, 'MONSTER': 0xED, 'NEWLINE': 0xEE, 'PAGE': 0xEF,
    'SECTION': 0xF0, 'HERO': 0xF6, 'CLEAR': 0xF7, 'CONTINUE': 0xF9,
    'WAIT': 0xFA, 'CHOICE2': 0xFF,
    # S120 names (the old ones stay accepted in `raw`): VOICE_LOW = $EA,
    # VOICE_HIGH = $EB, SPEED = $EC (back to the menu's text speed), FAST = $ED
    # (bank $56 $45A7: $C826 bit 7 — print at once); POS = $E8, SOUND = $E9
    'VOICE_LOW': 0xEA, 'VOICE_HIGH': 0xEB, 'SPEED': 0xEC, 'FAST': 0xED,
    'POS': 0xE8, 'SOUND': 0xE9,
}

STD_BOX = [0xEA, 0x9F, 0xA3]      # TEXT_SYSTEM "Standard NPC Text Format"
LINE_BREAK = [0xEF, 0xEE]          # $EF $EE together, never bare $EE
END_PLAIN = [0xF7, 0xF0]           # CLEAR + SECTION
END_CHOICE = [0xE7, 0xF0]          # CHOICE + SECTION (script checks $C83C)

MAX_LINE = 18                      # display cells per line (Phase 2 spec)
# S97 r2 (PyBoy-measured, $EA $9F $A3 opener): a box shows 2 lines of 18
# cells; the "*:" speaker mark takes the first 2 cells of the FIRST box's
# line 1 (16 left); later lines and boxes start at cell 0 (no indent; S120:
# $EB does not indent either — both openers only pick the voice). A line past
# 18 cells is wrapped by the engine mid-word; lines past 2 scroll the box
# without waiting — so the editor authors text as explicit boxes.
BOX_LINES = 2
FIRST_LINE = 16
BOX_BREAK = [0xFA, 0xF7, 0xEF, 0xEE]   # WAIT (arrow, A) + CLEAR + PAGE+NEWLINE — vanilla 6029x


class TextError(ValueError):
    pass


# charmap.asm, as rgbasm applies it to a quoted db string (longest match
# first: ".." is ONE glyph, $61 — so "..." is 2 cells, not 3). These are the
# characters a `db "…"` string may hold.
CHARMAP = {str(d): d for d in range(10)}
CHARMAP.update({chr(0x41 + i): 0x24 + i for i in range(26)})
CHARMAP.update({chr(0x61 + i): 0x3E + i for i in range(26)})
CHARMAP.update({"'": 0x5C, ',': 0x5E, '.': 0x5F, ';': 0x60, '..': 0x61,
                ' ': 0x62, '!': 0x63, '?': 0x64})
# S120: every other glyph of the text font custom text may use (font bank $4F,
# rendered + PyBoy-shown; vanilla dialogue uses - & ( ) + : … [ ] and ").
EXTRA = {'"': 0x65, '-': 0x9C, '&': 0xB6, '(': 0xA0, ')': 0xA1, '+': 0xA2,
         ':': 0xA3, '/': 0x9E, '~': 0x9D, '[': 0x96, ']': 0x97, '*': 0x9F,
         '\u2026': 0xA4}                       # … (one cell; ".." is $61)
GLYPHS = dict(CHARMAP)
GLYPHS.update(EXTRA)
# one-cell contractions: an apostrophe + one of these letters (vanilla: 'l 205,
# 't 341, 's 445, 'r 415, 'm 392, 'v 39, 'd 12, 'e 8 uses …)
CONTRACTIONS = {"'l": 0x66, "'t": 0x67, "'s": 0x68, "'r": 0x69, "'m": 0x6A,
                "'y": 0x6B, "'v": 0x6C, "'d": 0x6D, "'e": 0x6E, "'c": 0x6F,
                "'n": 0x70, "'T": 0x71}
# name inserts: token -> (bytes, cells it may take, preview glyphs)
HERO_CELLS = 4        # vanilla's widest $F6 line leaves 4 cells; the new-game name is 4 bytes
LEAD_CELLS = 9        # a species name (monster_text NAME_MAX)
TOKENS = {
    '{hero}': ([0xF6], HERO_CELLS, [0xD3, 0xD4, 0xD5, 0xD6]),   # the new-game name tiles (TERRY; MILLY with the Milly hook, S121)
    '{lead}': ([0xF9, 0x00], LEAD_CELLS,
               [0x27, 0x4F, 0x3E, 0x48, 0x36, 0x49, 0x46, 0x4A, 0x42]),  # "DrakSlime"
}
SPEAKER = [0x9F, 0xA3]             # the "*:" the $EA $9F $A3 opener prints
VOICES = {'low': [0xEA], 'high': [0xEB], 'none': []}
SPEAKER_MAX = 10                   # cells of a named speaker incl. the ":"


def items(s):
    """A text line -> [(kind, value, source)]: kind 'g' = one glyph code,
    't' = a name insert token. Longest match: tokens, '..', contractions."""
    out, i = [], 0
    while i < len(s):
        if s[i] == '{':
            j = s.find('}', i)
            tok = s[i:j + 1] if j > 0 else ''
            if tok not in TOKENS:
                raise TextError(f"unknown insert {s[i:j + 1] or s[i:]!r} "
                                f"(known: {', '.join(TOKENS)})")
            out.append(('t', tok, tok))
            i = j + 1
            continue
        two = s[i:i + 2]
        if two == '..':
            out.append(('g', 0x61, two))
            i += 2
        elif two in CONTRACTIONS:
            out.append(('g', CONTRACTIONS[two], two))
            i += 2
        elif s[i] in GLYPHS:
            out.append(('g', GLYPHS[s[i]], s[i]))
            i += 1
        else:
            raise TextError(f"character {s[i]!r} is not in the game font "
                            "(letters, digits, space and . , ; ! ? ' \" - & ( ) + : / ~ [ ] * …)")
    return out


def codes(s):
    """Glyph codes as the box will SHOW them (an insert = its preview glyphs,
    as many as the cells it may take)."""
    out = []
    for kind, v, _src in items(s):
        out += TOKENS[v][2] if kind == 't' else [v]
    return out


def encode(s):
    """The bytes a text line is stored as (inserts = their control codes)."""
    out = []
    for kind, v, _src in items(s):
        out += TOKENS[v][0] if kind == 't' else [v]
    return out


def cells(s):
    """Display cells a string takes (one per glyph; an insert its budget)."""
    return sum(TOKENS[v][1] if kind == 't' else 1 for kind, v, _src in items(s))


def uses_lead(entry_or_text):
    """True when a dialogue entry / text uses {lead} (needs op $3F before it)."""
    import json as _j
    return '{lead}' in (entry_or_text if isinstance(entry_or_text, str)
                        else _j.dumps(entry_or_text))


def speaker_codes(speaker):
    """Glyph codes the speaker label shows (preview) for a box text's first
    line, and the bytes stored. speaker None / '*' = "*:", '' = none, 'hero' =
    the hero's name + ':', else the name + ':'."""
    if speaker in (None, '*'):
        return list(SPEAKER), list(SPEAKER)
    if speaker == '':
        return [], []
    if speaker == 'hero':
        return TOKENS['{hero}'][2] + [0xA3], [0xF6, 0xA3]
    if '{' in speaker:
        raise TextError(f"speaker {speaker!r}: a name, '*', 'hero' or nothing")
    cs = codes(speaker)
    return cs + [0xA3], cs + [0xA3]


def speaker_cells(speaker):
    return len(speaker_codes(speaker)[0])


def check_speaker(speaker, voice):
    if voice not in (None, 'low', 'high', 'none'):
        raise TextError(f"voice {voice!r}: 'low', 'high' or 'none'")
    if speaker not in (None, '*', '', 'hero'):
        if not isinstance(speaker, str) or not speaker.strip() or speaker != speaker.strip():
            raise TextError(f"speaker {speaker!r}: a name without leading / trailing spaces")
        n = speaker_cells(speaker)
        if n > SPEAKER_MAX:
            raise TextError(f"speaker {speaker!r} is {n} cells with the ':' (max {SPEAKER_MAX})")


FONT_ROM_OFFSET = 0x4F * 0x4000 + 0x0010


# S120b (user: "change TERRY to MILLY as default, but leave otherwise as 4 letters")
# drew the new-game hero name tiles $D3-$D6 as "MILLY"; S121 moved that under the
# Milly hook (patches/bank_04f.asm region milly_name_tiles: MILLY with the hook, the
# original TERRY without). The previews read glyphs from the ORIGINAL ROM, so the
# MILLY tiles come from here while the open project has the hook on —
# use_hero_glyphs() (Session / the Milly hook dialog); test_compiler checks
# MILLY_GLYPHS against a hook-on build.
MILLY_GLYPHS = {
    0xD3: bytes.fromhex('ff44ff6cff54ff44ff44ff44ff44ff00'),
    0xD4: bytes.fromhex('ffe4ff44ff44ff44ff44ff44ffe7ff00'),
    0xD5: bytes.fromhex('ff10ff10ff10ff10ff10ff10ff9eff00'),
    0xD6: bytes.fromhex('ff44ff44ff28ff10ff10ff10ff10ff00'),
}
PATCHED_GLYPHS = {}             # the glyphs the previews draw instead of the ROM's


def use_hero_glyphs(milly_on):
    """The previews' hero-name tiles: MILLY (True) or the ROM's TERRY (False)."""
    PATCHED_GLYPHS.clear()
    if milly_on:
        PATCHED_GLYPHS.update(MILLY_GLYPHS)


def glyph_2bpp(rom, code):
    if code in PATCHED_GLYPHS:
        return PATCHED_GLYPHS[code]
    o = FONT_ROM_OFFSET + code * 16
    return rom[o:o + 16]


def check_text_chars(s):
    """Raise TextError when a line holds something the font cannot show."""
    items(s)


def check_raw_string(s):
    """A `raw` string is emitted as a quoted db string — only the charmap's
    characters are safe there (S120: a ':' in a raw string became 'W', the
    ASCII byte $3A, with no error)."""
    bad = []
    i = 0
    while i < len(s):
        if s.startswith('..', i):
            i += 2
            continue
        if s[i] not in CHARMAP:
            bad.append(s[i])
        i += 1
    if bad:
        raise TextError(f"raw string {s!r}: {sorted(set(bad))!r} are not charmap characters "
                        "(use [\"bytes\", …] for other glyphs, or a boxes / lines text)")


def wrap_text(s, width=MAX_LINE):
    """Greedy word wrap to `width` display cells."""
    words, lines, cur = s.split(), [], ""
    for w in words:
        if cells(w) > width:
            raise TextError(f"word longer than {width} cells: {w!r}")
        cand = (cur + " " + w).strip()
        if cells(cand) <= width:
            cur = cand
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def line_limit(box_index, line_index, speaker=None):
    """Display cells available to a line of a `boxes` text (the first line of
    the first box loses the speaker label's cells: "*:" = 2 by default)."""
    if (box_index, line_index) == (0, 0):
        return MAX_LINE - speaker_cells(speaker)
    return MAX_LINE


def flow_boxes(text, first_box=True, speaker=None):
    """Word-wrap free text into boxes of BOX_LINES lines (first line of the
    first box after the speaker label, the rest MAX_LINE). A newline in `text`
    forces a new line, an empty line forces a new box. first_box=False
    flows text that continues later in a talk (no speaker line)."""
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
                lim = line_limit(len(boxes) + base, len(cur), speaker)
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


def check_boxes(boxes, speaker=None, voice=None):
    """Raise TextError when a box text cannot show as authored."""
    check_speaker(speaker, voice)
    if not boxes:
        raise TextError('no text')
    for bi, box in enumerate(boxes):
        if not box or not any(ln for ln in box):
            raise TextError(f'box {bi + 1} is empty')
        if len(box) > BOX_LINES:
            raise TextError(f'box {bi + 1} has {len(box)} lines (a box shows {BOX_LINES})')
        for li, ln in enumerate(box):
            check_text_chars(ln)
            lim = line_limit(bi, li, speaker)
            if cells(ln) > lim:
                raise TextError(f'box {bi + 1} line {li + 1} is {cells(ln)} cells '
                                f'(max {lim}): {ln!r}')


def entry_boxes(entry):
    """The boxes a `boxes` / auto `text` entry shows (None for lines/raw)."""
    if 'boxes' in entry:
        return [list(b) for b in entry['boxes']]
    if 'text' in entry and 'lines' not in entry and 'raw' not in entry:
        return flow_boxes(entry['text'], speaker=entry.get('speaker'))
    return None


def opener(entry):
    """The bytes before the first line: voice ($EA / $EB / none) + speaker
    label. Default = $EA $9F $A3 (STD_BOX), byte-identical to pre-S120."""
    voice = entry.get('voice') or 'low'
    sp = entry.get('speaker')
    return VOICES[voice] + speaker_codes(sp)[1]


def entry_stream(entry):
    """Normalise a dialogue entry to a stream of ('str', s) / ('ctl', [bytes]).

    Authoring forms (schema PROJECT_COMPILER.md §dialogue):
      explicit: {"lines": ["Want a", "Beef Jerky?"], "choice": true}
      raw     : {"raw": [["box"], "Want a", ["br"], ...]}  (regression-grade)
      auto    : {"text": "long text...", "choice": false} → flowed into
                boxes (S97 r2; was one scrolling page)
      boxes   : {"boxes": [["line 1", "line 2"], ["next box"]], "choice": …}
                (S97 r2) — each box waits for A ($FA) and clears ($F7);
                S120: + "speaker" / "voice" (boxes and auto text)
    A 'str' item holds a text line in the S120 glyph syntax (contractions,
    extra glyphs, {hero} / {lead}); render_entry_asm encodes it.
    """
    out = []
    boxes = entry_boxes(entry)
    if boxes is not None:
        check_boxes(boxes, entry.get('speaker'), entry.get('voice'))
        voice = VOICES[entry.get('voice') or 'low']
        sp = entry.get('speaker')
        if voice + speaker_codes(sp)[1] == STD_BOX:
            out.append(('ctl', STD_BOX))
        else:
            if voice:
                out.append(('ctl', voice))
            if sp == 'hero':
                out.append(('ctl', [0xF6, 0xA3]))
            elif sp not in (None, '*', ''):
                out += [('str', sp), ('ctl', [0xA3])]       # the name as text, then ':'
            elif sp in (None, '*'):
                out.append(('ctl', list(SPEAKER)))
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
                check_raw_string(item)
                out.append(('raw', item))
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
        if cells(ln) > MAX_LINE:
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


def _db_parts(s):
    """A text line -> db operands: runs of charmap characters as one quoted
    string (exactly the pre-S120 output for such text), everything else
    (contractions, extra glyphs, inserts) as hex bytes."""
    parts, run = [], ''
    for kind, v, src in items(s):
        plain = kind == 'g' and src in CHARMAP      # contractions ("'t") are not
        if plain:
            run += src
        else:
            if run:
                parts.append('"' + run + '"')
                run = ''
            bs = TOKENS[v][0] if kind == 't' else [v]
            parts += [f"${b:02X}" for b in bs]
    if run:
        parts.append('"' + run + '"')
    return parts


def entry_bytes(entry):
    """The stored bytes of a dialogue entry (what render_entry_asm emits)."""
    out = []
    for kind, v in entry_stream(entry):
        if kind == 'ctl':
            out += v
        elif kind == 'str':
            out += encode(v)
        else:                                   # raw: the charmap, longest match
            i = 0
            while i < len(v):
                if v.startswith('..', i):
                    out.append(0x61)
                    i += 2
                else:
                    out.append(CHARMAP[v[i]])
                    i += 1
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
        elif kind in ('str', 'raw'):
            cur += _db_parts(v) if kind == 'str' else ['"' + v + '"']
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
