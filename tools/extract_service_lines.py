#!/usr/bin/env python3
"""The service NPCs' menu lines + the Medal Man's rewards, from the ROM (S126).

ROADMAP P3.14e1 (PROJECT_COMPILER §2.39, BANK04_SCRIPT_ENGINE "`$04` screen
types"). Every room-independent service screen (script opcode $04 <type>
<base>) speaks its lines as text id = base + offset through one "say helper"
per bank: bank $09 ScreenEffectSay (shop, Vault), bank $0A ScreenEffectSay0A (egg
appraiser), bank $12 ScreenEffectSay12 (farm, Library, Monster Namer, Medal
Man). For each service this tool writes the block of lines its vanilla NPC
passes (base = the op's second word in the vanilla script), each line split
into its FRAME and its WORDS:

  voice    the opener byte: $EA "low", $EB "high", none (a line that goes on in
           the box already open, e.g. the farm's "[INS 00] was returned…")
  speaker  the label after the opener: "*" ($9F $A3), "hero" ($F6 $A3), a name
           + $A3 ("Pulio"), or none
  tail     the control bytes after the last word: $F0 (no wait: a menu prompt
           stays while the cursor runs), $F7 $F0 / $FA $F7 $F0 (wait for A),
           $EF $EE $F0, $FF $F0 (YES / NO) …
  text     the words in the editor's glyph syntax: "\n" = $EF $EE, "\n\n" =
           $FA $F7 $EF $EE (a new box), {hero} = $F6, {ins0}..{ins3} = $F9
           $00/$10/$20/$30 (the name / number slots the menu code fills)

so a project line keeps the frame and replaces only the words
(editor2/core/services.py). Also: the offsets each handler speaks (a static
census of `ld hl, offset` reaching the say helper directly or through `jr`),
and MedalRewardTable ($12:$6D29: per egg [dw medals, dw enemy row]; the code
tests the eggs given [$D9E1] against 4 in three places).

Output: extracted/service_lines.json
Usage:  python3 tools/extract_service_lines.py            (write)
        python3 tools/extract_service_lines.py --selftest (JSON == ROM)
"""
import hashlib
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ROM_PATH = os.path.join(REPO, 'data', 'DWM-original.gbc')
OUT = os.path.join(REPO, 'extracted', 'service_lines.json')
DIALOGUE = os.path.join(REPO, 'extracted', 'dialogue.json')

# kind -> screen type, the say helper's bank, the vanilla base, the block
# length (offsets 0..n-1: the text ids after the block belong to the next
# block — e.g. $06BA.. repeats Pulio's greeting), the handler range in its
# bank (start inclusive, end exclusive) and the vanilla NPC (map, script).
KINDS = {
    'shop':    dict(screen=0, bank=0x09, base=0x0680, count=0x10, rng=(0x45F3, 0x4EF9),
                    vanilla='Bazaar shopkeepers (map $02)'),
    'vault':   dict(screen=2, bank=0x09, base=0x06A0, count=0x1A, rng=(0x4EF9, 0x5B64),
                    vanilla='Vault keeper (map $0F script 1)'),
    'farm':    dict(screen=3, bank=0x12, base=0x06C0, count=0x27, rng=(0x442D, 0x6061),
                    vanilla='Pulio (map $04 script 26)'),
    'eggs':    dict(screen=7, bank=0x0A, base=0x0750, count=0x1D, rng=(0x6095, 0x6966),
                    vanilla='Egg Evaluator (map $0C scripts 4 / 5)'),
    'library': dict(screen=8, bank=0x12, base=0x0740, count=0x05, rng=(0x6061, 0x6842),
                    vanilla='Librarian (map $12 scripts 14 / 15)'),
    'namer':   dict(screen=9, bank=0x12, base=0x0780, count=0x06, rng=(0x6842, 0x6AFE),
                    vanilla='Monster Namer (map $1A script 2)'),
    'medals':  dict(screen=10, bank=0x12, base=0x0720, count=0x12, rng=(0x6AFE, 0x7000),
                    vanilla='Medal Man (map $16 scripts 1 / 2)'),
    # S127 (ROADMAP P3.14e2): breeding. Grandpa's block is spoken by his menu
    # (screen 6, the BREED / HATCH machine $4BC3-$6095), by "Take … with you
    # now?" (screen 11, $6966-$6E52) and by the Starry Shrine's entry script;
    # +$0D / +$16 are the ceremony's own (map $08 script 0 speaks the ids).
    'grandpa': dict(screen=6, bank=0x0A, base=0x06F0, count=0x20,
                    rng=[(0x4BC3, 0x6095), (0x6966, 0x6E52)],
                    vanilla='Grandpa (Starry Shrine, map $09 scripts 0 / 5 / 7)'),
    # a master offering their own monster: the generic block $0600 ("Why not
    # breed with my [INS 00]?" — the menu fills the mate's name); +0 the script's
    # farewell, +1..+8 the menu ($442D-$4BC3), +9 the line after the ceremony
    # (op $44 = base + 9). +$0A.. belong to the Teto / CatFly blocks.
    'breeder': dict(screen=5, bank=0x0A, base=0x0600, count=0x0A, rng=(0x442D, 0x4BC3),
                    vanilla='Teto (Arena Lobby, map $06 scripts 10 / 11)'),
}
HELPER = {0x09: 0x45E5, 0x0A: 0x441F, 0x12: 0x441F}
MEDAL_TABLE = 0x6D29          # $12: [dw medals, dw EID] per egg; $FFFF ends
MEDAL_COUNT_SITES = (0x6B5D, 0x6B92, 0x6CC0)   # `cp $04` (the eggs given vs 4)
TAIL_CODES = {0xF0, 0xF7, 0xFA, 0xEF, 0xEE, 0xFF, 0xE7}
VOICE = {0xEA: 'low', 0xEB: 'high'}


def rom_bytes():
    return open(ROM_PATH, 'rb').read()


def _glyph_names():
    sys.path.insert(0, REPO)
    from editor2.core import textenc as T
    rev = {}
    for k, v in T.GLYPHS.items():
        rev.setdefault(v, k)
    for k, v in T.CONTRACTIONS.items():
        rev[v] = k
    rev[0x61] = '..'
    return rev


def read_text(rom, bank, addr):
    o = bank * 0x4000 + addr - 0x4000
    out = []
    while True:
        c = rom[o]
        out.append(c)
        o += 1
        if c == 0xF0 or len(out) > 600:
            return out


def split_line(raw, rev):
    """raw bytes -> (voice, speaker, speaker_bytes, body_text, tail)."""
    b = list(raw)
    j = len(b)
    while j > 0 and b[j - 1] in TAIL_CODES:
        j -= 1
    tail = b[j:]
    i = 0
    voice = None
    if b and b[0] in VOICE:
        voice = VOICE[b[0]]
        i = 1
    speaker, sp_bytes = None, []
    k = i
    while k < min(j, i + 11) and b[k] != 0xA3 and b[k] < 0xE0:
        k += 1
    if voice is not None and k < j and b[k] == 0xA3 and k > i:
        sp_bytes = b[i:k + 1]
        if sp_bytes == [0x9F, 0xA3]:
            speaker = '*'
        elif sp_bytes == [0xF6, 0xA3]:
            speaker = 'hero'
        else:
            speaker = ''.join(rev[c] for c in sp_bytes[:-1])
        i = k + 1
    body = b[i:j]
    text, x = [], 0
    while x < len(body):
        c = body[x]
        if body[x:x + 4] == [0xFA, 0xF7, 0xEF, 0xEE]:
            text.append('\n\n'); x += 4
        elif body[x:x + 2] == [0xEF, 0xEE]:
            text.append('\n'); x += 2
        elif c == 0xF9:
            text.append('{ins%d}' % (body[x + 1] >> 4)); x += 2
        elif c == 0xF6:
            text.append('{hero}'); x += 1
        elif c in rev:
            text.append(rev[c]); x += 1
        else:
            raise ValueError(f'unknown byte ${c:02X} in {raw!r}')
    return voice, speaker, sp_bytes, ''.join(text), tail


def engine_offsets(rom, bank, rng):
    """Offsets reaching the say helper: `ld hl, $00xx` then `call helper`, or
    a `jr` (up to two hops) that lands on `call helper`."""
    base = bank * 0x4000 - 0x4000
    h = HELPER[bank]
    call = bytes([0xCD, h & 0xFF, h >> 8])

    def lands(a, hops=2):
        if rom[base + a:base + a + 3] == call:
            return True
        if hops and rom[base + a] == 0x18:
            d = rom[base + a + 1]
            t = a + 2 + (d - 256 if d > 127 else d)
            return lands(t, hops - 1)
        return False

    out = set()
    for a in range(rng[0], rng[1] - 3):
        if rom[base + a] == 0x21 and rom[base + a + 2] == 0x00 and rom[base + a + 1] < 0x40:
            if lands(a + 3):
                out.add(rom[base + a + 1])
    return sorted(out)


def _rngs(k):
    """A kind's handler ranges (S127: Grandpa's lines come from two screens)."""
    r = k['rng']
    return r if isinstance(r, list) else [r]


def extract():
    rom = rom_bytes()
    rev = _glyph_names()
    dia = json.load(open(DIALOGUE))
    by = {e['id']: e for e in dia['text_ids']}
    kinds = {}
    for kind, k in KINDS.items():
        lines = []
        for off in range(k['count']):
            tid = k['base'] + off
            e = by[f'${tid:04X}']
            raw = read_text(rom, int(e['bank'][1:], 16), int(e['addr'][1:], 16))
            voice, sp, spb, text, tail = split_line(raw, rev)
            lines.append({'off': off, 'id': f'${tid:04X}', 'raw': bytes(raw).hex(),
                          'voice': voice, 'speaker': sp,
                          'speaker_raw': bytes(spb).hex(), 'tail': bytes(tail).hex(),
                          'text': text})
        kinds[kind] = {'screen': k['screen'], 'bank': f"${k['bank']:02X}",
                       'base': f"${k['base']:04X}", 'count': k['count'],
                       'handler': [f"${a:04X}" for r in _rngs(k) for a in r],
                       'vanilla_npc': k['vanilla'],
                       'engine_offsets': sorted({o for r in _rngs(k)
                                                 for o in engine_offsets(rom, k['bank'], r)}),
                       'lines': lines}
    mb = 0x12 * 0x4000 - 0x4000
    rows = []
    a = MEDAL_TABLE
    while True:
        t = rom[mb + a] | rom[mb + a + 1] << 8
        if t == 0xFFFF:
            break
        rows.append({'medals': t, 'eid': rom[mb + a + 2] | rom[mb + a + 3] << 8})
        a += 4
    counts = [rom[mb + s + 1] for s in MEDAL_COUNT_SITES]
    for s in MEDAL_COUNT_SITES:
        assert rom[mb + s] == 0xFE, f'cp expected at $12:{s:04X}'
    assert counts == [len(rows)] * 3, counts
    md5 = hashlib.md5(rom).hexdigest()
    return {'_generator': f'tools/extract_service_lines.py (ROM md5 {md5})',
            '_doc': 'PROJECT_COMPILER §2.39; per service the lines its menu speaks '
                    '(text id = base + offset), split into frame (voice, speaker, tail) '
                    'and words (text); engine_offsets = the static census of the '
                    'handler\'s say-helper calls (lines spoken only through computed '
                    'offsets are missing from it).',
            'kinds': kinds,
            'medal_rewards': {'table': f'$12:${MEDAL_TABLE:04X}',
                              'count_sites': [f'$12:${s:04X}' for s in MEDAL_COUNT_SITES],
                              'rows': rows}}


def main():
    if not os.path.exists(ROM_PATH):
        print('SKIP: no ROM at data/DWM-original.gbc')
        return 0
    data = extract()
    if '--selftest' in sys.argv:
        have = json.load(open(OUT))
        ok = have['kinds'] == data['kinds'] and have['medal_rewards'] == data['medal_rewards']
        # every line rebuilds byte-for-byte from its frame + words
        sys.path.insert(0, REPO)
        from editor2.core import services as SV
        bad = gen = 0
        for kind, k in data['kinds'].items():
            for ln in k['lines']:
                if SV.encode_line(ln, ln['text']).hex() != ln['raw']:
                    bad += 1
                    print(f'  rebuild mismatch {kind} +{ln["off"]:02X}')
                # the words re-typed through the encoder: the same bytes except
                # where the game wrote two '.' glyphs ($5F $5F; typed '..' = $61)
                enc = bytes(SV.frame_head(ln) + SV.encode_body(ln['text'])
                            + list(bytes.fromhex(ln['tail']))).hex()
                if enc != ln['raw'] and '..' not in ln['text']:
                    gen += 1
                    print(f'  re-typed words differ {kind} +{ln["off"]:02X}')
        bad += gen
        print(f'service_lines.json == ROM: {ok}; lines rebuilt from frame + words: '
              f'{sum(len(k["lines"]) for k in data["kinds"].values()) - bad} ok, {bad} bad')
        return 0 if ok and not bad else 1
    json.dump(data, open(OUT, 'w'), indent=1, ensure_ascii=False)
    n = sum(len(k['lines']) for k in data['kinds'].values())
    print(f'wrote {OUT}: {len(data["kinds"])} services, {n} lines, '
          f'{len(data["medal_rewards"]["rows"])} medal rewards')
    return 0


if __name__ == '__main__':
    sys.exit(main())
