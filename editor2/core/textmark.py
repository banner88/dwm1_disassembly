"""textmark.py — the game's own texts as editable markup, LOSSLESSLY (S150,
ROADMAP P3.6 / Phase F T-author; TEXT_SYSTEM "Edited game text (S150)",
PROJECT_COMPILER §2.58).

`decode(raw, style)` turns a text's bytes (without the closing $F0) into a
markup string an author can edit; `encode(markup, style)` turns it back.
For every text of the original game `encode(decode(raw)) == raw` (the
census `tools/census_text_codec.py` proves it for all of them; test_s150).

Two styles, because the game writes two kinds of text:

  * 'box'  — what people say (the 2,560 text ids, the battle tutorial):
             a line break is `$EF $EE` (PAGE + NEWLINE)      -> "\\n"
             the wait arrow + a cleared box `$FA $F7`         -> "▼"
               so the usual next box `$FA $F7 $EF $EE`        -> "▼\\n"
             the closing `$F7` (CLEAR) before $F0 is implied: a text that
             ends otherwise (with ▼, {yes/no}, {choice}, or no clear at all)
             says so — the last one with "{end}".
  * 'rows' — the tables (battle messages, item / field texts, credits):
             a line break is `$F1` (NEXTROW)                   -> "\\n"
             nothing is implied: every other code is a token.

Glyphs: letters, digits, space and . , ; ! ? ' " - & ( ) + : / ~ [ ] * …;
".." is ONE glyph ($61) and an apostrophe + l t s r m y v d e c n T is ONE
glyph (the font's contractions, $66-$71) — exactly as textenc.py writes the
project's own dialogue. A byte the markup has no friendlier form for is
written `{$xx}` (any byte; the decoder also uses it where two glyphs would
otherwise read back as one, e.g. an apostrophe the game wrote apart from its
"t").

Tokens (case-insensitive): {hero} $F6 · {ins NN} $F9 NN (a name the caller
put in slot NN: 00 / 10 / 20 / 30) · {low} $EA · {high} $EB (the voice: low
= the King / most people, high = Milayou / Watabou …) · {yes/no} $FF ·
{choice} $E7 · {wait} $FA · {clear} $F7 · {sound NN} $E9 NN · {end} (box
style: no closing clear) · {XX} or {XX NN …} any control code $E0-$FF with
its parameter bytes (e.g. {FC 10}, {E8 08 01}) · {slime} … {material} the
family icons $10-$18 · ★ $AC · © $B5 · ° $8F.
"""

import re

# ------------------------------------------------------------------ the font
GLYPH_CHARS = {}
GLYPH_CHARS.update({d: str(d) for d in range(10)})
GLYPH_CHARS.update({0x24 + i: chr(0x41 + i) for i in range(26)})
GLYPH_CHARS.update({0x3E + i: chr(0x61 + i) for i in range(26)})
GLYPH_CHARS.update({0x5C: "'", 0x5E: ',', 0x5F: '.', 0x60: ';', 0x61: '\u2025',
                    0x62: ' ', 0x63: '!', 0x64: '?', 0x65: '"',
                    0x66: "'l", 0x67: "'t", 0x68: "'s", 0x69: "'r", 0x6A: "'m",
                    0x6B: "'y", 0x6C: "'v", 0x6D: "'d", 0x6E: "'e", 0x6F: "'c",
                    0x70: "'n", 0x71: "'T",
                    0x9C: '-', 0xB6: '&', 0xA0: '(', 0xA1: ')', 0xA2: '+',
                    0xA3: ':', 0x9E: '/', 0x9D: '~', 0x96: '[', 0x97: ']',
                    0x9F: '*', 0xA4: '…', 0xAC: '★', 0xB5: '©',
                    0x8F: '°'})
CHAR_GLYPHS = {}
for _b, _c in GLYPH_CHARS.items():
    CHAR_GLYPHS.setdefault(_c, _b)
MULTI = sorted((c for c in CHAR_GLYPHS if len(c) > 1), key=len, reverse=True)
ICONS = ('slime', 'dragon', 'beast', 'bird', 'plant', 'bug', 'devil', 'zombie',
         'material')                          # $10-$18 (the family icons)
ICON_GLYPHS = {n: 0x10 + i for i, n in enumerate(ICONS)}

# ------------------------------------------------------------------ the codes
# parameter bytes per control code (bank $56 TextCodeTable — TEXT_SYSTEM)
PARAMS = {0xE8: 2, 0xE9: 1, 0xF8: 1, 0xF9: 1, 0xFB: 1, 0xFC: 1}
NAMED = {'hero': [0xF6], 'low': [0xEA], 'high': [0xEB], 'yes/no': [0xFF],
         'choice': [0xE7], 'wait': [0xFA], 'clear': [0xF7]}
NAMED_PARAM = {'ins': 0xF9, 'sound': 0xE9}
CODE_NAMES = {0xF6: 'hero', 0xEA: 'low', 0xEB: 'high', 0xFF: 'yes/no', 0xE7: 'choice',
              0xFA: 'wait', 0xF7: 'clear'}
END = 0xF0
STYLES = ('box', 'rows')
BOX_NL = [0xEF, 0xEE]
ROWS_NL = [0xF1]
ARROW = '▼'                              # ▼ = $FA $F7 in box style
BOX_ARROW = [0xFA, 0xF7]


class MarkupError(ValueError):
    pass


def scan(rom, off, limit=8192):
    """The bytes of a text at ROM offset `off`, WITHOUT its closing $F0 — the
    first $F0 that is not a control code's parameter (S150: $FB / $FC / $F8 /
    $E8 / $E9 / $F9 take parameter bytes; the battle tutorial writes `$FB $F0`
    mid-text). None when no end within `limit`."""
    i = off
    end = min(len(rom), off + limit)
    while i < end:
        b = rom[i]
        if b == END:
            return bytes(rom[off:i])
        i += 1 + PARAMS.get(b, 0)
    return None


def _units(raw):
    """raw -> [(kind, bytes)] kind 'g' glyph / 'c' control code (+ params)."""
    out, i = [], 0
    while i < len(raw):
        b = raw[i]
        n = PARAMS.get(b, 0) if b >= 0xE0 else 0
        if b >= 0xE0:
            out.append(('c', bytes(raw[i:i + 1 + n])))
            i += 1 + n
        else:
            out.append(('g', bytes([b])))
            i += 1
    return out


def _glyph_text(units, k):
    """The markup of glyph unit k (a friendlier form when it reads back as
    itself, else {$xx})."""
    b = units[k][1][0]
    c = GLYPH_CHARS.get(b)
    if c is None:
        if 0x10 <= b <= 0x18:
            return '{' + ICONS[b - 0x10] + '}'
        return '{$%02X}' % b
    # would this char and the next unit's text merge into one multi-char glyph?
    nxt = ''
    if k + 1 < len(units) and units[k + 1][0] == 'g':
        nc = GLYPH_CHARS.get(units[k + 1][1][0])
        nxt = nc or ''
    if len(c) == 1 and nxt:
        for m in MULTI:
            if m.startswith(c) and (c + nxt).startswith(m):
                return '{$%02X}' % b
    if c == '{':
        return '{$%02X}' % b
    return c


def _code_text(bs):
    b = bs[0]
    if b in CODE_NAMES and len(bs) == 1:
        return '{' + CODE_NAMES[b] + '}'
    if b == 0xF9 and len(bs) == 2:
        return '{ins %02X}' % bs[1]
    if b == 0xE9 and len(bs) == 2:
        return '{sound %02X}' % bs[1]
    return '{' + ' '.join('%02X' % x for x in bs) + '}'


def _body(units, style):
    out, k = [], 0
    nl = BOX_NL if style == 'box' else ROWS_NL
    while k < len(units):
        kind, bs = units[k]
        if kind == 'g':
            out.append(_glyph_text(units, k))
            k += 1
            continue
        if style == 'box' and bs == b'\xfa' and k + 1 < len(units) and units[k + 1] == ('c', b'\xf7'):
            out.append(ARROW)
            k += 2
            continue
        if len(nl) == 2 and bs == bytes([nl[0]]) and k + 1 < len(units) and \
                units[k + 1] == ('c', bytes([nl[1]])):
            out.append('\n')
            k += 2
            continue
        if len(nl) == 1 and bs == bytes(nl):
            out.append('\n')
            k += 1
            continue
        out.append(_code_text(bs))
        k += 1
    return ''.join(out)


def decode(raw, style='box'):
    """A text's bytes (no closing $F0) -> markup (see the module docstring).
    Box style: the closing $F7 is implied when encode() would add it back;
    otherwise the text says how it ends (▼ / {yes/no} / {choice} end it
    without a clear; anything else gets {end})."""
    if style not in STYLES:
        raise MarkupError(f"style {style!r}")
    raw = bytes(raw)
    units = _units(raw)
    if style == 'rows':
        return _body(units, style)
    cands = []
    if units and units[-1] == ('c', b'\xf7'):
        cands.append(_body(units[:-1], style))
    cands.append(_body(units, style))
    cands.append(_body(units, style) + '{end}')
    for c in cands:
        try:
            if encode(c, style) == raw:
                return c
        except MarkupError:
            pass
    raise MarkupError(f"no markup reads back as {raw.hex()}")


_TOKEN = re.compile(r'\{([^{}]*)\}')


def _token_bytes(body, style):
    t = body.strip()
    low = t.lower()
    if low in NAMED:
        return list(NAMED[low])
    if low in ICON_GLYPHS:
        return [ICON_GLYPHS[low]]
    if low == 'end':
        return None                               # handled by the caller
    parts = low.split()
    if parts and parts[0] in NAMED_PARAM:
        if len(parts) != 2:
            raise MarkupError(f"{{{body}}}: {parts[0]} takes one number (hex), e.g. {{{parts[0]} 00}}")
        return [NAMED_PARAM[parts[0]], _hex(parts[1], body)]
    if low.startswith('$') and len(parts) == 1:
        v = _hex(low[1:], body)
        return [v]
    vals = [_hex(p, body) for p in parts]
    if not vals:
        raise MarkupError("{} is empty")
    b = vals[0]
    if b < 0xE0:
        raise MarkupError(f"{{{body}}}: a control code is $E0-$FF (a glyph is {{$xx}})")
    if b == END:
        raise MarkupError("{F0} ends a text — the build adds it")
    want = PARAMS.get(b, 0)
    if len(vals) - 1 != want:
        raise MarkupError(f"{{{body}}}: code ${b:02X} takes {want} parameter byte(s)")
    return vals


def _hex(s, body):
    try:
        v = int(s.lstrip('$'), 16)
    except ValueError:
        raise MarkupError(f"{{{body}}}: {s!r} is not a hex number") from None
    if not 0 <= v <= 0xFF:
        raise MarkupError(f"{{{body}}}: {s!r} is not a byte")
    return v


def encode(markup, style='box'):
    """Markup -> the text's bytes, WITHOUT the closing $F0 (the build adds it).
    Raises MarkupError on anything the game cannot show."""
    if style not in STYLES:
        raise MarkupError(f"style {style!r}")
    if not isinstance(markup, str):
        raise MarkupError("a text is a string")
    out = []
    end_seen = False
    i = 0
    nl = BOX_NL if style == 'box' else ROWS_NL
    s = markup.replace('\r\n', '\n')
    while i < len(s):
        if end_seen:
            raise MarkupError("{end} must be the last thing in a text")
        ch = s[i]
        if ch == '{':
            m = _TOKEN.match(s, i)
            if not m:
                raise MarkupError(f"an unclosed '{{' at character {i + 1}")
            bs = _token_bytes(m.group(1), style)
            if bs is None:
                if style != 'box':
                    raise MarkupError("{end} is for dialogue texts only")
                end_seen = True
            else:
                out += bs
            i = m.end()
            continue
        if ch == '}':
            raise MarkupError(f"a stray '}}' at character {i + 1}")
        if ch == '\n':
            out += nl
            i += 1
            continue
        if ch == ARROW:
            if style != 'box':
                raise MarkupError("▼ is for dialogue texts — write {wait}{clear} here")
            out += BOX_ARROW
            i += 1
            continue
        for mm in MULTI:
            if s.startswith(mm, i):
                out.append(CHAR_GLYPHS[mm])
                i += len(mm)
                break
        else:
            if ch in CHAR_GLYPHS:
                out.append(CHAR_GLYPHS[ch])
                i += 1
            else:
                raise MarkupError(f"character {ch!r} is not in the game font (letters, digits, "
                                  "space and . , ; ! ? ' \" - & ( ) + : / ~ [ ] * … ★ ©; "
                                  "any byte as {$xx})")
    if style == 'box' and not end_seen:
        last = _units(bytes(out))[-1:] if out else []
        last = last[0][1] if last else b''
        tail2 = _units(bytes(out))[-2:]
        arrow = len(tail2) == 2 and tail2[0][1] == b'\xfa' and tail2[1][1] == b'\xf7'
        if not (arrow or last in (b'\xff', b'\xe7')):
            out.append(0xF7)
    if END in out:
        # a glyph escape {$F0} or a parameter byte $F0 is fine; an END code is not
        k = 0
        while k < len(out):
            b = out[k]
            if b == END:
                raise MarkupError("{F0} ends a text — the build adds it")
            k += 1 + (PARAMS.get(b, 0) if b >= 0xE0 else 0)
    return bytes(out)


# ------------------------------------------------------------------ measuring
def cells_per_line(raw, style='box', hero=4, ins=9):
    """[(cells of each line)] of a text, line breaks / boxes as the style
    writes them — what the editor's warnings and preview count. {hero} counts
    `hero` cells, {ins NN} `ins` cells (a species / item / skill name)."""
    lines, cur = [], 0
    units = _units(bytes(raw))
    nl = BOX_NL if style == 'box' else ROWS_NL
    k = 0
    while k < len(units):
        kind, bs = units[k]
        if kind == 'g':
            cur += 1
        elif bs[0] == 0xF6:
            cur += hero
        elif bs[0] == 0xF9:
            cur += ins
        elif len(nl) == 2 and bs == bytes([nl[0]]) and k + 1 < len(units) and \
                units[k + 1] == ('c', bytes([nl[1]])):
            lines.append(cur)
            cur = 0
            k += 1
        elif len(nl) == 1 and bs == bytes(nl):
            lines.append(cur)
            cur = 0
        elif bs[0] in (0xF7, 0xF3) and style == 'box':
            pass
        k += 1
    lines.append(cur)
    return lines


def plain(markup):
    """The markup without its tokens (search / list previews): a code is a space."""
    s = _TOKEN.sub(' ', markup or '')
    return s.replace(ARROW, ' ')
